// Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

import Compression
import Dispatch
import Foundation


let exeName = "gen-thumbnails"


let validOpts = Set<String>([
  "-Z",
])


func main() {
  let (paths, opts) = parseArgs()

  let maxSize: Int
  if let maxSizeStr = opts["-Z"] {
    guard let ms = Int(maxSizeStr) else { fail("invalid max size: '\(maxSizeStr)'") }
    maxSize = ms
  } else {
    maxSize = 4096
  }

  if paths.isEmpty { fail("No paths specified.") }

  var ok = true
  for path in paths {
    ok &&= genThumbnail(origPath: path, maxSize: maxSize)
  }
  exit(ok ? 0 : 1)
}


func parseArgs() -> ([String], [String: String]) {
  var paths: [String] = []
  var opts: [String: String] = [:]

  var opt: String? = nil
  for (i, arg) in ProcessInfo.processInfo.arguments.enumerated() {
    if i == 0 {
      continue
    } else if let o = opt {
      opts[o] = arg
      opt = nil
    } else if validOpts.contains(arg) {
      opt = arg
    } else if arg.hasPrefix("-") {
      fail("unrecognized option: '\(arg)'")
    } else {
      paths.append(arg)
    }
  }
  if let opt = opt {
    fail("dangling option: \(opt)")
  }
  return (paths, opts)
}


func fail(_ msg: String) -> Never {
  errL("\(exeName): error: \(msg)")
  exit(1)
}


infix operator &&= : AssignmentPrecedence

func &&=(_ lhs: inout Bool, rhs: Bool) { lhs = lhs && rhs }

main()
