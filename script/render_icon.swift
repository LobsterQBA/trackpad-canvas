import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("usage: render_icon <output.png>\n", stderr)
    exit(2)
}

let size = NSSize(width: 1024, height: 1024)
let image = NSImage(size: size)
image.lockFocus()

let canvas = NSRect(origin: .zero, size: size)
NSColor(calibratedRed: 0.035, green: 0.028, blue: 0.20, alpha: 1).setFill()
NSBezierPath(roundedRect: canvas.insetBy(dx: 54, dy: 54), xRadius: 220, yRadius: 220).fill()

let inset = canvas.insetBy(dx: 130, dy: 130)
NSColor.white.withAlphaComponent(0.18).setStroke()
let trackpad = NSBezierPath(roundedRect: inset, xRadius: 145, yRadius: 145)
trackpad.lineWidth = 16
trackpad.stroke()

let gesture = NSBezierPath()
gesture.move(to: NSPoint(x: 235, y: 395))
gesture.curve(
    to: NSPoint(x: 785, y: 670),
    controlPoint1: NSPoint(x: 390, y: 790),
    controlPoint2: NSPoint(x: 615, y: 250)
)
gesture.lineCapStyle = .round
gesture.lineWidth = 76
NSColor(calibratedRed: 0.65, green: 0.95, blue: 0.69, alpha: 1).setStroke()
gesture.stroke()

let glow = NSBezierPath(ovalIn: NSRect(x: 719, y: 604, width: 132, height: 132))
NSColor(calibratedRed: 1.0, green: 0.55, blue: 0.47, alpha: 1).setFill()
glow.fill()
NSColor.white.setStroke()
glow.lineWidth = 18
glow.stroke()

image.unlockFocus()

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("could not render icon\n", stderr)
    exit(1)
}

try png.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))

