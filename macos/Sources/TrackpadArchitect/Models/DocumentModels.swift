import Foundation
import AppKit

enum DocumentSchemaVersion: Int, Codable {
    case v1 = 1
}

struct CanvasPoint: Codable, Hashable {
    var x: Double
    var y: Double

    init(_ point: CGPoint) {
        x = point.x
        y = point.y
    }

    init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    var cgPoint: CGPoint { CGPoint(x: x, y: y) }
}

struct CanvasRect: Codable, Hashable {
    var x: Double
    var y: Double
    var width: Double
    var height: Double

    init(_ rect: CGRect) {
        x = rect.origin.x
        y = rect.origin.y
        width = rect.size.width
        height = rect.size.height
    }

    init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }

    var cgRect: CGRect { CGRect(x: x, y: y, width: width, height: height).standardized }
}

struct RGBAColor: Codable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double

    static let ink = RGBAColor(red: 0.05, green: 0.04, blue: 0.28, alpha: 1)
    static let violet = RGBAColor(red: 0.37, green: 0.30, blue: 0.88, alpha: 1)
    static let mint = RGBAColor(red: 0.58, green: 0.94, blue: 0.69, alpha: 1)
    static let coral = RGBAColor(red: 1.0, green: 0.55, blue: 0.47, alpha: 1)
    static let sky = RGBAColor(red: 0.55, green: 0.84, blue: 0.98, alpha: 1)
    static let paper = RGBAColor(red: 0.985, green: 0.98, blue: 0.94, alpha: 1)
    static let clear = RGBAColor(red: 0, green: 0, blue: 0, alpha: 0)

    var nsColor: NSColor {
        NSColor(calibratedRed: red, green: green, blue: blue, alpha: alpha)
    }
}

struct ObjectStyle: Codable, Hashable {
    var stroke: RGBAColor = .ink
    var fill: RGBAColor = .clear
    var lineWidth: Double = 2.5
    var fontSize: Double = 18
    var roughness: Double = 0.35
}

enum DiagramKind: String, Codable, CaseIterable {
    case pen, line, rectangle, ellipse, arrow, connector, text
}

enum ConnectorAnchor: String, Codable {
    case top, right, bottom, left, center
}

struct ConnectorEndpoint: Codable, Hashable {
    var objectID: UUID?
    var anchor: ConnectorAnchor = .center
    var point: CanvasPoint
}

struct ConnectorBinding: Codable, Hashable {
    var start: ConnectorEndpoint
    var end: ConnectorEndpoint
}

struct DiagramObject: Identifiable, Codable, Hashable {
    var id = UUID()
    var kind: DiagramKind
    var frame: CanvasRect
    var points: [CanvasPoint] = []
    var text: String = ""
    var style = ObjectStyle()
    var connector: ConnectorBinding?
    var locked = false
    var groupID: UUID?

    var bounds: CGRect {
        if kind == .pen, !points.isEmpty {
            let xs = points.map(\.x)
            let ys = points.map(\.y)
            return CGRect(
                x: xs.min() ?? 0,
                y: ys.min() ?? 0,
                width: max(1, (xs.max() ?? 0) - (xs.min() ?? 0)),
                height: max(1, (ys.max() ?? 0) - (ys.min() ?? 0))
            )
        }
        return frame.cgRect
    }
}

struct CanvasLayer: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var isVisible = true
    var isLocked = false
    var objects: [DiagramObject] = []
}

struct CanvasPage: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var layers: [CanvasLayer]
    var presentationFrame = CanvasRect(x: 80, y: 70, width: 960, height: 540)
}

struct ArchitectDocument: Codable, Hashable {
    var schemaVersion = DocumentSchemaVersion.v1.rawValue
    var title: String
    var pages: [CanvasPage]

    static var blank: ArchitectDocument {
        ArchitectDocument(
            title: "Untitled Architecture",
            pages: [
                CanvasPage(
                    name: "Page 1",
                    layers: [CanvasLayer(name: "Diagram")]
                )
            ]
        )
    }
}

enum CanvasTool: String, CaseIterable, Identifiable {
    case select, pen, line, rectangle, ellipse, arrow, connector, text, hand

    var id: String { rawValue }

    var title: String { rawValue.capitalized }

    var symbol: String {
        switch self {
        case .select: return "arrow.up.left"
        case .pen: return "pencil.tip"
        case .line: return "line.diagonal"
        case .rectangle: return "rectangle"
        case .ellipse: return "circle"
        case .arrow: return "arrow.up.right"
        case .connector: return "point.topleft.down.to.point.bottomright.curvepath"
        case .text: return "textformat"
        case .hand: return "hand.draw"
        }
    }
}

enum LayoutDirection: String {
    case leftToRight
    case topToBottom
}

