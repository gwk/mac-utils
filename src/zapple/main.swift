// Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

import Compression
import Dispatch
import Foundation


let validOpts = Set<String>([
  "-a", // Algorithm.
  "-c", // Compress.
  "-d", // Decompress.
  "-o", // Output.
])

let validFlags = Set<String>([
  "-q", // Quiet.
])

func main() {
  let (paths, opts, flags) = parseArgs()

  let isLoud = !flags.contains("-q")
  var srcPath = ""
  var dstPath = ""
  var alg: CompressionAlgorithm = COMPRESSION_LZFSE
  var op: CompressionStreamOp

  if let a = opts["-a"] {
    if let _alg = CompressionAlgorithm(name: a) {
      alg = _alg
    } else {
      fail("invalid compression algorithm: \(a)")
    }
  } else {
    fail("algorithm (-a) option required.")
  }

  if let c = opts["-c"] {
    if opts.keys.contains("-d") { fail("-c and -d cannot both be specified.") }
    srcPath = c
    op = COMPRESSION_STREAM_ENCODE
  } else if let d = opts["-d"] {
    srcPath = d
    op = COMPRESSION_STREAM_DECODE
  } else {
    fail("either compress (-c) or decompress (-d) option required.")
  }

  if let o = opts["-o"] {
    dstPath = o
  } else {
    fail("output (-o) option required.")
    //dstPath = srcPath + algorithm.pathExt
    //guard let algorithm = CompressionAlgorithm(name: srcPath.pathExt) else {
    //  errL("unrecognized path extension: \(srcPath)")
    //  return false
    //}
    //let dstPath = srcPath.pathStem
  }

  if !paths.isEmpty { fail("path list is not yet handled.") }

  var ok = true
  ok &&= performFileOp(op: op, algorithm: alg, srcPath: srcPath, dstPath: dstPath, isLoud: isLoud)
  //for path in paths {
  //  ok &&= performFileOp(op: op, algorithm: alg, srcPath: path, dstPath: ???)
  //}
  exit(ok ? 0 : 1)
}


func parseArgs() -> (paths: [String], opts:[String: String], flags: Set<String>) {
  var paths: [String] = []
  var opts: [String: String] = [:]
  var flags: Set<String> = []

  var opt: String? = nil
  for (i, arg) in ProcessInfo.processInfo.arguments.enumerated() {
    if i == 0 {
      continue
    } else if let o = opt {
      opts[o] = arg
      opt = nil
    } else if validOpts.contains(arg) {
      opt = arg
    } else if validFlags.contains(arg) {
      flags.insert(arg)
    } else if arg.hasPrefix("-") {
      fail("unrecognized option: '\(arg)'")
    } else {
      paths.append(arg)
    }
  }
  if let opt = opt {
    fail("dangling option: \(opt)")
  }
  return (paths, opts, flags)
}


func fail(_ msg: String) -> Never {
  errL("error: \(msg)")
  exit(1)
}


infix operator &&= : AssignmentPrecedence

func &&=(_ lhs: inout Bool, rhs: Bool) { lhs = lhs && rhs }

main()
