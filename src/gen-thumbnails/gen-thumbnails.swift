import Foundation
import ImageIO

let fileMngr = FileManager.default


func genThumbnail(origPath: String, maxSize: Int) -> Bool {
  print(origPath)

  if !fileMngr.isReadableFile(atPath: origPath) {
    errL("\(origPath): error: file is not readable.")
    return false
  }
  let origUrl = URL(fileURLWithPath: origPath)
  let stem = origUrl.deletingPathExtension().path
  let thumbPath = stem + "-\(maxSize).heic"
  let thumbUrl = URL(fileURLWithPath: thumbPath)

  guard let imgSrc = CGImageSourceCreateWithURL(origUrl as CFURL, nil) else {
    errL("\(origPath): error: could not create image source.")
    return false
  }
  guard let imgDst = CGImageDestinationCreateWithURL(thumbUrl as CFURL, "public.heic" as CFString, 1, nil) else {
    errL("\(thumbUrl.path): error: could not create image destination.")
    return false
  }

  var properties: [NSString: Any]  = [:]
  if let srcProperties = CGImageSourceCopyPropertiesAtIndex(imgSrc, 0, nil) as NSDictionary? {
    for (k, v) in srcProperties {
      let k = k as! String
      if k == "Orientation" { continue } // Drop orientation because it will cause double-rotation.
      properties[k as NSString] = v
    }
  }


  let options: [CFString: Any] = [
    kCGImageSourceCreateThumbnailFromImageAlways: true,
    kCGImageSourceCreateThumbnailWithTransform: true,
    kCGImageSourceShouldCacheImmediately: true, // Create the image in memory immediately.
    kCGImageSourceThumbnailMaxPixelSize: maxSize
  ]

  guard let img = CGImageSourceCreateThumbnailAtIndex(imgSrc, 0, options as CFDictionary) else {
    errL("\(origPath): error: create thumbnail failed.")
    return false
  }

  //if let cs = img.colorSpace { print("thumbnail colorspace: \(cs)") }


  CGImageDestinationAddImage(imgDst, img, properties as CFDictionary)

  let ok = CGImageDestinationFinalize(imgDst)
  if !ok {
    errL("\(thumbUrl.path): could not write to destination.")
  }
  return ok
}



func errZ<Item>(_ item: Item) {
  fputs(String(describing: item), stderr)
}


func errL<Item>(_ item: Item) {
  fputs(String(describing: item), stderr)
  fputs("\n", stderr)
}
