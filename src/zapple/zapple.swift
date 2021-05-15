// Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

import Foundation
import Compression


func performFileOp(op: CompressionStreamOp, algorithm: CompressionAlgorithm, srcPath: String, dstPath: String) -> Bool {

  let fileManager = FileManager.default

  guard let srcFile = FileHandle(forReadingAtPath: srcPath) else {
    errL("could not open source file: \(srcPath)")
    return false
  }
  guard let attrs = try? fileManager.attributesOfItem(atPath: srcPath) else {
    errL("could not read attributes of source: \(srcPath)")
    return false
  }
  guard let v = attrs[FileAttributeKey.size] else {
    errL("could not obtain source size: \(srcPath)")
    return false
  }
  let srcSize = (v as! NSNumber) as! UInt64

  if !fileManager.fileExists(atPath: dstPath) {
    if !fileManager.createFile(atPath: dstPath, contents: nil, attributes: nil) {
      errL("could not create destination file: \(dstPath)")
      return false
    }
  }

  guard let dstFile = FileHandle(forWritingAtPath: dstPath) else {
    errL("could not open destination file: \(dstPath)")
    return false
  }

  let progress = Progress()
  progress.totalUnitCount = Int64(srcSize)

  let opMsg = (op == COMPRESSION_STREAM_ENCODE) ? "Compressing" : "Decompressing"

  let res = performStreamingOp(
    operation: op,
    srcFile: srcFile,
    dstFile: dstFile,
    algorithm: algorithm) {
    unitProgress in
    progress.completedUnitCount = unitProgress
    errZ("\(opMsg) '\(srcPath)': \(numberFormatter.string(from: progress.fractionCompleted as NSNumber)!)…\r")
  }
  errL("\(opMsg) '\(srcPath)': \(numberFormatter.string(from: progress.fractionCompleted as NSNumber)!).")
  return res
}


func updateUIOnCompletion(operation: CompressionStreamOp) {
  DispatchQueue.main.async {
    errL(operation == COMPRESSION_STREAM_ENCODE ? "encoded." : "decoded.")
  }
}


func performStreamingOp(
  operation: CompressionStreamOp,
  srcFile: FileHandle,
  dstFile: FileHandle,
  algorithm: CompressionAlgorithm,
  progressUpdateFunction: (Int64) -> Void) -> Bool {

  let bufferSize = 32_768
  let destinationBufferPointer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
  defer {
    destinationBufferPointer.deallocate()
  }

  // Create the CompressionStream and throw an error if failed.
  var stream = CompressionStream()
  if compression_stream_init(&stream, operation, algorithm) == COMPRESSION_STATUS_ERROR {
    print("Unable to initialize the compression stream.")
    return false
  }
  defer { compression_stream_destroy(&stream) }

  // Must setup after compression_stream_init, since compression_stream_init will zero all fields in stream.
  stream.src_size = 0
  stream.dst_ptr = destinationBufferPointer
  stream.dst_size = bufferSize

  var status = COMPRESSION_STATUS_OK
  var sourceData: Data?
  repeat {
    var flags = Int32(0)

    // If this iteration has consumed all of the source data, read a new tempData buffer from the input file.
    if stream.src_size == 0 {
      sourceData = srcFile.readData(ofLength: bufferSize)

      stream.src_size = sourceData!.count
      if sourceData!.count < bufferSize {
        flags = Int32(COMPRESSION_STREAM_FINALIZE.rawValue)
      }
    }

    // Perform compression or decompression.
    if let sourceData = sourceData {
      let count = sourceData.count

      sourceData.withUnsafeBytes {
        let baseAddress = $0.bindMemory(to: UInt8.self).baseAddress!

        stream.src_ptr = baseAddress.advanced(by: count - stream.src_size)
        status = compression_stream_process(&stream, flags)
      }
    }

    switch status {
    case COMPRESSION_STATUS_OK, COMPRESSION_STATUS_END:

      // Get the number of bytes put in the destination buffer. This is the difference between
      // stream.dst_size before the call (here bufferSize), and stream.dst_size after the call.
      let count = bufferSize - stream.dst_size

      let outputData = Data(bytesNoCopy: destinationBufferPointer, count: count, deallocator: .none)
      dstFile.write(outputData)

      // Reset the stream to receive the next batch of output.
      stream.dst_ptr = destinationBufferPointer
      stream.dst_size = bufferSize
      progressUpdateFunction(Int64(srcFile.offsetInFile))
    case COMPRESSION_STATUS_ERROR:
      print("COMPRESSION_STATUS_ERROR.")
      return false

    default:
      break
    }

  } while status == COMPRESSION_STATUS_OK

  srcFile.closeFile()
  dstFile.closeFile()
  return true
}


let numberFormatter:NumberFormatter = {
  // Used to display the fractional progress as a percentage.
  let f = NumberFormatter()
  f.numberStyle = .percent
  f.multiplier = 100
  return f
}()


typealias CompressionAlgorithm = compression_algorithm
typealias CompressionStream = compression_stream
typealias CompressionStreamOp = compression_stream_operation


extension CompressionAlgorithm {

  var name: String {
    switch self {
    case COMPRESSION_LZ4: return "lz4"
    case COMPRESSION_LZ4_RAW: return "lz4_raw"
    case COMPRESSION_LZFSE: return "lzfse"
    case COMPRESSION_LZMA: return "lzma"
    case COMPRESSION_ZLIB: return "zlib"
    default: fatalError("Unknown compression algorithm.")
    }
  }

  var pathExt: String { return "." + name }

  init?(name: String) {
    switch name.lowercased() {
    case "lz4": self = COMPRESSION_LZ4
    case "lz4_raw": self = COMPRESSION_LZ4_RAW
    case "lzfse": self = COMPRESSION_LZFSE
    case "lzma": self = COMPRESSION_LZMA
    case "zlib": self = COMPRESSION_ZLIB
    default: return nil
    }
  }
}


extension CompressionStream {
  init() {
    self = UnsafeMutablePointer<CompressionStream>.allocate(capacity: 1).pointee
  }
}


extension String {
  var pathExt: String { return URL(fileURLWithPath: self).pathExtension }
  var pathStem: String { return URL(fileURLWithPath: self).deletingPathExtension().path }
}


func errZ<Item>(_ item: Item) {
  fputs(String(describing: item), stderr)
}


func errL<Item>(_ item: Item) {
  fputs(String(describing: item), stderr)
  fputs("\n", stderr)
}
