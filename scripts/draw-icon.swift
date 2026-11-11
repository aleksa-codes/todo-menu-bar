import AppKit

func drawIcon(size: Int) throws -> Data {
  guard
    let bitmap = NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ), let context = NSGraphicsContext(bitmapImageRep: bitmap)
  else {
    throw CocoaError(.fileWriteUnknown)
  }
  NSGraphicsContext.saveGraphicsState()
  NSGraphicsContext.current = context
  defer { NSGraphicsContext.restoreGraphicsState() }
  let scale = CGFloat(size) / 1024
  context.cgContext.scaleBy(x: scale, y: scale)
  let artworkScale: CGFloat = 824.0 / 896.0
  let inset = (1 - artworkScale) * 512
  context.cgContext.translateBy(x: inset, y: inset)
  context.cgContext.scaleBy(x: artworkScale, y: artworkScale)

  let tile = NSBezierPath(
    roundedRect: NSRect(x: 64, y: 64, width: 896, height: 896), xRadius: 200, yRadius: 200)
  NSGraphicsContext.saveGraphicsState()
  let shadow = NSShadow()
  shadow.shadowColor = NSColor.black.withAlphaComponent(0.22)
  shadow.shadowBlurRadius = 24
  shadow.shadowOffset = NSSize(width: 0, height: -10)
  shadow.set()
  NSColor(white: 0.94, alpha: 1).setFill()
  tile.fill()
  NSGraphicsContext.restoreGraphicsState()
  let gradient = NSGradient(
    starting: NSColor(white: 1, alpha: 1), ending: NSColor(white: 0.86, alpha: 1))
  gradient?.draw(in: tile, angle: -90)
  NSColor.white.withAlphaComponent(0.8).setStroke()
  tile.lineWidth = 3
  tile.stroke()

  let ink = NSColor(srgbRed: 0.19, green: 0.23, blue: 0.29, alpha: 1)
  let blue = NSColor(srgbRed: 0.12, green: 0.39, blue: 0.91, alpha: 1)
  for (index, y) in [CGFloat(700), 512, 324].enumerated() {
    let circle = NSBezierPath(ovalIn: NSRect(x: 216, y: y - 53, width: 106, height: 106))
    if index == 0 {
      blue.setFill()
      circle.fill()
      let check = NSBezierPath()
      check.move(to: NSPoint(x: 242, y: y))
      check.line(to: NSPoint(x: 262, y: y - 20))
      check.line(to: NSPoint(x: 295, y: y + 20))
      check.lineWidth = 12
      check.lineCapStyle = .round
      check.lineJoinStyle = .round
      NSColor.white.setStroke()
      check.stroke()
    } else {
      ink.withAlphaComponent(index == 1 ? 0.7 : 0.45).setStroke()
      circle.lineWidth = 11
      circle.stroke()
    }
    let line = NSBezierPath(
      roundedRect: NSRect(x: 388, y: y - 12, width: index == 1 ? 352 : 278, height: 24),
      xRadius: 12, yRadius: 12)
    ink.withAlphaComponent(index == 0 ? 0.92 : index == 1 ? 0.7 : 0.45).setFill()
    line.fill()
  }
  context.flushGraphics()
  guard let data = bitmap.representation(using: .png, properties: [:]) else {
    throw CocoaError(.fileWriteUnknown)
  }
  return data
}

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconset = root.appending(path: ".build/AppIcon.iconset")
let assets = root.appending(path: "Assets")
let resources = root.appending(path: "Sources/TodoMenuBar/Resources")
for directory in [iconset, assets, resources] {
  try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
}
for size in [16, 32, 128, 256, 512] {
  try drawIcon(size: size).write(to: iconset.appending(path: "icon_\(size)x\(size).png"))
  try drawIcon(size: size * 2).write(to: iconset.appending(path: "icon_\(size)x\(size)@2x.png"))
}
try drawIcon(size: 1024).write(to: assets.appending(path: "app-icon.png"))
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = [
  "-c", "icns", iconset.path, "-o", resources.appending(path: "AppIcon.icns").path,
]
try process.run()
process.waitUntilExit()
guard process.terminationStatus == 0 else { throw CocoaError(.fileWriteUnknown) }
print("Generated Assets/app-icon.png and Resources/AppIcon.icns")
