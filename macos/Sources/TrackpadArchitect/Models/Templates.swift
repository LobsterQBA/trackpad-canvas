import Foundation

enum ArchitectTemplate: String, CaseIterable, Identifiable {
    case blank = "Blank 16:9"
    case breakdown = "Breakdown Tree"
    case pipeline = "Data Pipeline"
    case context = "System Context"
    case swimlane = "Ownership Swimlane"

    var id: String { rawValue }

    func makeDocument() -> ArchitectDocument {
        var document = ArchitectDocument.blank
        document.title = rawValue
        document.pages[0].name = rawValue
        guard self != .blank else { return document }

        let layerID = document.pages[0].layers[0].id
        _ = layerID
        let nodeStyle = ObjectStyle(stroke: .ink, fill: .mint, lineWidth: 2.5, fontSize: 18, roughness: 0.35)
        let altStyle = ObjectStyle(stroke: .ink, fill: .sky, lineWidth: 2.5, fontSize: 18, roughness: 0.35)
        var objects: [DiagramObject] = []

        func node(_ x: Double, _ y: Double, _ w: Double, _ h: Double, _ text: String, _ style: ObjectStyle = nodeStyle) -> DiagramObject {
            DiagramObject(kind: .rectangle, frame: CanvasRect(x: x, y: y, width: w, height: h), text: text, style: style)
        }

        func link(_ from: DiagramObject, _ to: DiagramObject) -> DiagramObject {
            let start = CanvasPoint(x: from.frame.x + from.frame.width, y: from.frame.y + from.frame.height / 2)
            let end = CanvasPoint(x: to.frame.x, y: to.frame.y + to.frame.height / 2)
            return DiagramObject(
                kind: .connector,
                frame: CanvasRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y),
                style: ObjectStyle(stroke: .violet, fill: .clear, lineWidth: 2.5, fontSize: 18, roughness: 0.25),
                connector: ConnectorBinding(
                    start: ConnectorEndpoint(objectID: from.id, anchor: .right, point: start),
                    end: ConnectorEndpoint(objectID: to.id, anchor: .left, point: end)
                )
            )
        }

        switch self {
        case .blank:
            break
        case .breakdown:
            let root = node(150, 260, 190, 80, "Core question", altStyle)
            let a = node(470, 130, 190, 76, "Workstream A")
            let b = node(470, 270, 190, 76, "Workstream B", ObjectStyle(stroke: .ink, fill: .coral, lineWidth: 2.5, fontSize: 18, roughness: 0.35))
            let c = node(470, 410, 190, 76, "Workstream C", nodeStyle)
            objects = [root, a, b, c, link(root, a), link(root, b), link(root, c)]
        case .pipeline:
            let source = node(120, 270, 160, 76, "Sources", altStyle)
            let ingest = node(360, 270, 160, 76, "Ingest")
            let model = node(600, 270, 160, 76, "Model", ObjectStyle(stroke: .ink, fill: .coral, lineWidth: 2.5, fontSize: 18, roughness: 0.35))
            let serve = node(840, 270, 160, 76, "Serve", altStyle)
            objects = [source, ingest, model, serve, link(source, ingest), link(ingest, model), link(model, serve)]
        case .context:
            let users = node(120, 270, 170, 78, "Teams", altStyle)
            let system = node(455, 235, 230, 145, "Core system", ObjectStyle(stroke: .ink, fill: .coral, lineWidth: 3, fontSize: 22, roughness: 0.3))
            let data = node(840, 150, 170, 78, "Data platform")
            let partner = node(840, 390, 170, 78, "Partner API", altStyle)
            objects = [users, system, data, partner, link(users, system), link(system, data), link(system, partner)]
        case .swimlane:
            let titleStyle = ObjectStyle(stroke: .ink, fill: .sky, lineWidth: 2, fontSize: 16, roughness: 0.25)
            let lanes = ["Product", "Data", "Platform"]
            for (index, title) in lanes.enumerated() {
                let y = 120.0 + Double(index) * 150
                objects.append(node(100, y, 170, 110, title, titleStyle))
                objects.append(node(340, y + 16, 180, 78, index == 0 ? "Define" : index == 1 ? "Transform" : "Operate"))
                objects.append(node(650, y + 16, 180, 78, index == 0 ? "Validate" : index == 1 ? "Publish" : "Observe", altStyle))
            }
        }

        document.pages[0].layers[0].objects = objects
        return document
    }
}

