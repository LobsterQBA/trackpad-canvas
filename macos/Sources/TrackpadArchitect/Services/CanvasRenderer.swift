import AppKit
import CoreGraphics

enum CanvasRenderer {
    static func draw(
        page: CanvasPage,
        selectedIDs: Set<UUID> = [],
        showGrid: Bool = false,
        showPresentationFrame: Bool = true,
        in bounds: CGRect
    ) {
        if showGrid {
            drawGrid(in: bounds)
        }

        if showPresentationFrame {
            let frame = page.presentationFrame.cgRect
            NSColor.white.withAlphaComponent(0.75).setFill()
            NSBezierPath(roundedRect: frame, xRadius: 4, yRadius: 4).fill()
            NSColor(calibratedWhite: 0.72, alpha: 0.8).setStroke()
            let outline = NSBezierPath(roundedRect: frame, xRadius: 4, yRadius: 4)
            outline.lineWidth = 1
            outline.stroke()
        }

        let objects = page.layers.filter(\.isVisible).flatMap(\.objects)
        for object in objects {
            draw(object: object, allObjects: objects)
        }

        for object in objects where selectedIDs.contains(object.id) {
            drawSelection(for: object)
        }
    }

    static func resolvedEndpoints(for object: DiagramObject, allObjects: [DiagramObject]) -> (CGPoint, CGPoint) {
        guard let connector = object.connector else {
            let frame = object.frame.cgRect
            return (frame.origin, CGPoint(x: frame.maxX, y: frame.maxY))
        }
        return (
            resolve(connector.start, allObjects: allObjects),
            resolve(connector.end, allObjects: allObjects)
        )
    }

    static func svg(page: CanvasPage, crop: CGRect) -> String {
        let objects = page.layers.filter(\.isVisible).flatMap(\.objects)
        var body = """
        <svg xmlns="http://www.w3.org/2000/svg" width="\(Int(crop.width))" height="\(Int(crop.height))" viewBox="\(crop.minX) \(crop.minY) \(crop.width) \(crop.height)">
          <rect x="\(crop.minX)" y="\(crop.minY)" width="\(crop.width)" height="\(crop.height)" fill="#fffdf4"/>
          <g stroke-linecap="round" stroke-linejoin="round">
        """
        for object in objects {
            let stroke = hex(object.style.stroke)
            let fill = object.style.fill.alpha > 0.01 ? hex(object.style.fill) : "none"
            let width = object.style.lineWidth
            switch object.kind {
            case .pen:
                let points = object.points.map { "\($0.x),\($0.y)" }.joined(separator: " ")
                body += "\n<polyline points=\"\(points)\" fill=\"none\" stroke=\"\(stroke)\" stroke-width=\"\(width)\"/>"
            case .line:
                let rect = object.frame.cgRect
                body += "\n<line x1=\"\(rect.minX)\" y1=\"\(rect.minY)\" x2=\"\(rect.maxX)\" y2=\"\(rect.maxY)\" stroke=\"\(stroke)\" stroke-width=\"\(width)\"/>"
            case .rectangle:
                let rect = object.frame.cgRect
                body += "\n<rect x=\"\(rect.minX)\" y=\"\(rect.minY)\" width=\"\(rect.width)\" height=\"\(rect.height)\" rx=\"10\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(width)\"/>"
                body += textSVG(object.text, rect: rect, style: object.style)
            case .ellipse:
                let rect = object.frame.cgRect
                body += "\n<ellipse cx=\"\(rect.midX)\" cy=\"\(rect.midY)\" rx=\"\(rect.width / 2)\" ry=\"\(rect.height / 2)\" fill=\"\(fill)\" stroke=\"\(stroke)\" stroke-width=\"\(width)\"/>"
                body += textSVG(object.text, rect: rect, style: object.style)
            case .arrow, .connector:
                let endpoints = resolvedEndpoints(for: object, allObjects: objects)
                body += arrowSVG(start: endpoints.0, end: endpoints.1, color: stroke, width: width)
            case .text:
                body += textSVG(object.text, rect: object.frame.cgRect, style: object.style)
            }
        }
        body += "\n  </g>\n</svg>"
        return body
    }

    private static func drawGrid(in bounds: CGRect) {
        let path = NSBezierPath()
        let spacing: CGFloat = 16
        var x = floor(bounds.minX / spacing) * spacing
        while x < bounds.maxX {
            var y = floor(bounds.minY / spacing) * spacing
            while y < bounds.maxY {
                path.move(to: CGPoint(x: x, y: y))
                path.line(to: CGPoint(x: x + 0.7, y: y))
                y += spacing
            }
            x += spacing
        }
        NSColor(calibratedRed: 0.16, green: 0.13, blue: 0.36, alpha: 0.13).setStroke()
        path.lineWidth = 1
        path.stroke()
    }

    private static func draw(object: DiagramObject, allObjects: [DiagramObject]) {
        let strokeColor = object.style.stroke.nsColor
        let fillColor = object.style.fill.nsColor
        let lineWidth = CGFloat(object.style.lineWidth)
        let frame = object.frame.cgRect

        switch object.kind {
        case .pen:
            guard let first = object.points.first?.cgPoint else { return }
            let path = NSBezierPath()
            path.move(to: first)
            for point in object.points.dropFirst() { path.line(to: point.cgPoint) }
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.lineWidth = lineWidth
            strokeColor.setStroke()
            path.stroke()
        case .line:
            let path = NSBezierPath()
            path.move(to: frame.origin)
            path.line(to: CGPoint(x: frame.maxX, y: frame.maxY))
            path.lineCapStyle = .round
            path.lineWidth = lineWidth
            strokeColor.setStroke()
            path.stroke()
        case .rectangle:
            let path = NSBezierPath(roundedRect: frame, xRadius: 10, yRadius: 10)
            fillColor.setFill()
            path.fill()
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
            drawLabel(object.text, in: frame, style: object.style)
        case .ellipse:
            let path = NSBezierPath(ovalIn: frame)
            fillColor.setFill()
            path.fill()
            strokeColor.setStroke()
            path.lineWidth = lineWidth
            path.stroke()
            drawLabel(object.text, in: frame, style: object.style)
        case .arrow, .connector:
            let endpoints = resolvedEndpoints(for: object, allObjects: allObjects)
            drawArrow(start: endpoints.0, end: endpoints.1, color: strokeColor, width: lineWidth)
        case .text:
            drawLabel(object.text, in: frame, style: object.style, centered: false)
        }
    }

    private static func drawArrow(start: CGPoint, end: CGPoint, color: NSColor, width: CGFloat) {
        let path = NSBezierPath()
        path.move(to: start)
        path.line(to: end)
        path.lineWidth = width
        path.lineCapStyle = .round
        color.setStroke()
        path.stroke()

        let angle = atan2(end.y - start.y, end.x - start.x)
        let length: CGFloat = 13 + width
        let spread: CGFloat = .pi / 7
        let a = CGPoint(x: end.x - length * cos(angle - spread), y: end.y - length * sin(angle - spread))
        let b = CGPoint(x: end.x - length * cos(angle + spread), y: end.y - length * sin(angle + spread))
        let head = NSBezierPath()
        head.move(to: a)
        head.line(to: end)
        head.line(to: b)
        head.lineWidth = width
        head.lineCapStyle = .round
        head.lineJoinStyle = .round
        head.stroke()
    }

    private static func drawLabel(_ text: String, in rect: CGRect, style: ObjectStyle, centered: Bool = true) {
        guard !text.isEmpty else { return }
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = centered ? .center : .left
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: style.fontSize, weight: .medium),
            .foregroundColor: style.stroke.nsColor,
            .paragraphStyle: paragraph,
        ]
        let size = (text as NSString).boundingRect(
            with: CGSize(width: max(1, rect.width - 20), height: 10_000),
            options: [.usesLineFragmentOrigin],
            attributes: attributes
        ).size
        let target = centered
            ? CGRect(x: rect.minX + 10, y: rect.midY - size.height / 2, width: rect.width - 20, height: size.height)
            : rect
        (text as NSString).draw(in: target, withAttributes: attributes)
    }

    private static func drawSelection(for object: DiagramObject) {
        let rect = object.bounds.insetBy(dx: -5, dy: -5)
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        path.setLineDash([5, 4], count: 2, phase: 0)
        path.lineWidth = 1.5
        RGBAColor.violet.nsColor.setStroke()
        path.stroke()
        let handle = CGRect(x: rect.maxX - 4, y: rect.maxY - 4, width: 8, height: 8)
        RGBAColor.violet.nsColor.setFill()
        NSBezierPath(ovalIn: handle).fill()
    }

    private static func resolve(_ endpoint: ConnectorEndpoint, allObjects: [DiagramObject]) -> CGPoint {
        guard let id = endpoint.objectID, let object = allObjects.first(where: { $0.id == id }) else {
            return endpoint.point.cgPoint
        }
        let frame = object.bounds
        switch endpoint.anchor {
        case .top: return CGPoint(x: frame.midX, y: frame.minY)
        case .right: return CGPoint(x: frame.maxX, y: frame.midY)
        case .bottom: return CGPoint(x: frame.midX, y: frame.maxY)
        case .left: return CGPoint(x: frame.minX, y: frame.midY)
        case .center: return CGPoint(x: frame.midX, y: frame.midY)
        }
    }

    private static func hex(_ color: RGBAColor) -> String {
        String(format: "#%02X%02X%02X", Int(color.red * 255), Int(color.green * 255), Int(color.blue * 255))
    }

    private static func textSVG(_ value: String, rect: CGRect, style: ObjectStyle) -> String {
        guard !value.isEmpty else { return "" }
        let escaped = value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
        return "\n<text x=\"\(rect.midX)\" y=\"\(rect.midY)\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"-apple-system, sans-serif\" font-size=\"\(style.fontSize)\" font-weight=\"600\" fill=\"\(hex(style.stroke))\">\(escaped)</text>"
    }

    private static func arrowSVG(start: CGPoint, end: CGPoint, color: String, width: Double) -> String {
        let angle = atan2(end.y - start.y, end.x - start.x)
        let length = 13.0 + width
        let spread = Double.pi / 7
        let ax = end.x - length * cos(angle - spread)
        let ay = end.y - length * sin(angle - spread)
        let bx = end.x - length * cos(angle + spread)
        let by = end.y - length * sin(angle + spread)
        return "\n<path d=\"M \(start.x) \(start.y) L \(end.x) \(end.y) M \(ax) \(ay) L \(end.x) \(end.y) L \(bx) \(by)\" fill=\"none\" stroke=\"\(color)\" stroke-width=\"\(width)\"/>"
    }
}

