import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("usage: create_dmg_background.swift OUTPUT.png\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let logicalSize = CGSize(width: 540, height: 380)
let scale: CGFloat = 2
let pixelWidth = Int(logicalSize.width * scale)
let pixelHeight = Int(logicalSize.height * scale)
let colorSpace = CGColorSpaceCreateDeviceRGB()

guard let context = CGContext(
    data: nil,
    width: pixelWidth,
    height: pixelHeight,
    bitsPerComponent: 8,
    bytesPerRow: pixelWidth * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("could not create bitmap context\n", stderr)
    exit(1)
}

func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(red: red, green: green, blue: blue, alpha: alpha)
}

func drawText(_ value: String, at point: CGPoint, size: CGFloat, weight: String = "regular", color: CGColor) {
    let fontName = weight == "bold" ? "HelveticaNeue-Bold" : "HelveticaNeue"
    let font = CTFontCreateWithName(fontName as CFString, size, nil)
    let attributed = NSAttributedString(
        string: value,
        attributes: [
            NSAttributedString.Key(kCTFontAttributeName as String): font,
            NSAttributedString.Key(kCTForegroundColorAttributeName as String): color
        ]
    )
    let line = CTLineCreateWithAttributedString(attributed as CFAttributedString)
    context.textPosition = point
    CTLineDraw(line, context)
}

func drawArrow(from start: CGPoint, to end: CGPoint, color: CGColor) {
    let angle = atan2(end.y - start.y, end.x - start.x)
    let headLength: CGFloat = 9
    let headAngle: CGFloat = .pi / 6

    context.saveGState()
    context.setStrokeColor(color)
    context.setLineWidth(2)
    context.setLineCap(.round)
    context.move(to: start)
    context.addLine(to: end)
    context.strokePath()

    let arrowHead = CGMutablePath()
    arrowHead.move(to: end)
    arrowHead.addLine(to: CGPoint(
        x: end.x - headLength * cos(angle - headAngle),
        y: end.y - headLength * sin(angle - headAngle)
    ))
    arrowHead.move(to: end)
    arrowHead.addLine(to: CGPoint(
        x: end.x - headLength * cos(angle + headAngle),
        y: end.y - headLength * sin(angle + headAngle)
    ))
    context.addPath(arrowHead)
    context.strokePath()
    context.restoreGState()
}

context.scaleBy(x: scale, y: scale)
context.setFillColor(color(0.97, 0.98, 1.0))
context.fill(CGRect(origin: .zero, size: logicalSize))

let navy = color(0.08, 0.12, 0.22)
let secondary = color(0.35, 0.41, 0.53)
let blue = color(0.16, 0.38, 0.86)

context.setFillColor(blue)
context.fill(CGRect(x: 34, y: 326, width: 3, height: 22))
drawText("Install GatePass", at: CGPoint(x: 50, y: 328), size: 20, weight: "bold", color: navy)
drawText("Drag the app to Applications", at: CGPoint(x: 50, y: 304), size: 11, color: secondary)
drawArrow(from: CGPoint(x: 224, y: 190), to: CGPoint(x: 316, y: 190), color: blue)

guard let image = context.makeImage(),
      let destination = CGImageDestinationCreateWithURL(
        outputURL as CFURL,
        UTType.png.identifier as CFString,
        1,
        nil
      ) else {
    fputs("could not create PNG destination\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)
guard CGImageDestinationFinalize(destination) else {
    fputs("could not write PNG\n", stderr)
    exit(1)
}
