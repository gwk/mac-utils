// Dedicated to the public domain under CC0: https://creativecommons.org/publicdomain/zero/1.0/.

import AppKit
import Dispatch
import Foundation


let validOpts = Set<String>([
])


class AppDelegate: NSObject, NSApplicationDelegate {
  // NSWorkspace.recycle appears to need to be called from within a running application.
  // I tried scheduling in DispatchQueue.main.async and then calling dispatchMain,
  // but although files did get deleted, the callback only fired for error cases.

  override init() {}

  func applicationDidFinishLaunching(_ note: Notification) {

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
        errL("unrecognized option: '\(arg)'")
        exit(1)
      } else {
        paths.append(arg)
      }
    }

    let workspace = NSWorkspace.shared
    var hasError = false

    for path in paths {
      workspace.recycle([URL(fileURLWithPath: path)]) {
        (newURLs, error) in
        if let error = error {
          errL("del error: \(error.localizedDescription)")
          hasError = true
        }
      }
    }
    exit(hasError ? 1 : 0)
  }
}


func errL<Item>(_ item: Item) {
  fputs(String(describing: item), stderr)
  fputs("\n", stderr)
}


let app = NSApplication.shared
let appDelegate = AppDelegate() // bound to global because app.delegate is unowned.
app.delegate = appDelegate
app.run()
