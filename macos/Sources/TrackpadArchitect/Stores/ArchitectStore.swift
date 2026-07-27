import AppKit
import Combine
import Foundation

@MainActor
final class ArchitectStore: ObservableObject {
    @Published var document: ArchitectDocument
    @Published var activePageID: UUID
    @Published var activeLayerID: UUID
    @Published var selectedIDs: Set<UUID> = []
    @Published var tool: CanvasTool = .select
    @Published var zoom: Double = 1
    @Published var pan = CanvasPoint(x: 0, y: 0)
    @Published var showGrid = true
    @Published var showPresentationFrame = true
    @Published var zenMode = true
    @Published var statusMessage = "Touch the trackpad to draw · Two fingers navigate"
    @Published var currentURL: URL?
    @Published var currentStyle = ObjectStyle()

    private var undoStack: [ArchitectDocument] = []
    private var redoStack: [ArchitectDocument] = []
    private let recoveryURL: URL

    init(document: ArchitectDocument = .blank) {
        self.document = document
        activePageID = document.pages[0].id
        activeLayerID = document.pages[0].layers[0].id
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        recoveryURL = support
            .appendingPathComponent("Trackpad Architect", isDirectory: true)
            .appendingPathComponent("Recovery.tpa")
    }

    var activePage: CanvasPage {
        document.pages.first(where: { $0.id == activePageID }) ?? document.pages[0]
    }

    var visibleObjects: [DiagramObject] {
        activePage.layers.filter(\.isVisible).flatMap(\.objects)
    }

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    func replaceDocument(_ newDocument: ArchitectDocument, url: URL? = nil) {
        document = newDocument.pages.isEmpty ? .blank : newDocument
        activePageID = document.pages[0].id
        activeLayerID = document.pages[0].layers.first?.id ?? UUID()
        selectedIDs.removeAll()
        undoStack.removeAll()
        redoStack.removeAll()
        currentURL = url
        statusMessage = "Ready"
    }

    func beginMutation() {
        undoStack.append(document)
        if undoStack.count > 80 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    func finishMutation(_ message: String) {
        statusMessage = message
        saveRecovery()
    }

    func addObject(_ object: DiagramObject) {
        beginMutation()
        mutateActiveLayer { $0.objects.append(object) }
        selectedIDs = [object.id]
        finishMutation("Added \(object.kind.rawValue)")
    }

    func replaceObject(_ object: DiagramObject) {
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            for layerIndex in document.pages[pageIndex].layers.indices {
                if let objectIndex = document.pages[pageIndex].layers[layerIndex].objects.firstIndex(where: { $0.id == object.id }) {
                    document.pages[pageIndex].layers[layerIndex].objects[objectIndex] = object
                    return
                }
            }
        }
    }

    func object(id: UUID) -> DiagramObject? {
        visibleObjects.first(where: { $0.id == id })
    }

    func hitTest(_ point: CGPoint) -> UUID? {
        for object in visibleObjects.reversed() where !object.locked {
            if object.bounds.insetBy(dx: -8, dy: -8).contains(point) {
                return object.id
            }
        }
        return nil
    }

    func moveSelection(by delta: CGPoint, recordUndo: Bool) {
        guard !selectedIDs.isEmpty else { return }
        if recordUndo { beginMutation() }
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            for layerIndex in document.pages[pageIndex].layers.indices {
                for objectIndex in document.pages[pageIndex].layers[layerIndex].objects.indices {
                    var object = document.pages[pageIndex].layers[layerIndex].objects[objectIndex]
                    guard selectedIDs.contains(object.id), !object.locked else { continue }
                    object.frame.x += delta.x
                    object.frame.y += delta.y
                    object.points = object.points.map { CanvasPoint(x: $0.x + delta.x, y: $0.y + delta.y) }
                    document.pages[pageIndex].layers[layerIndex].objects[objectIndex] = object
                }
            }
        }
        if recordUndo { finishMutation("Moved selection") }
    }

    func deleteSelection() {
        guard !selectedIDs.isEmpty else { return }
        beginMutation()
        mutatePageLayers { layer in
            layer.objects.removeAll { selectedIDs.contains($0.id) && !$0.locked }
        }
        selectedIDs.removeAll()
        finishMutation("Deleted selection")
    }

    func duplicateSelection() {
        let originals = visibleObjects.filter { selectedIDs.contains($0.id) }
        guard !originals.isEmpty else { return }
        beginMutation()
        var copies: [DiagramObject] = []
        for var object in originals {
            object.id = UUID()
            object.frame.x += 24
            object.frame.y += 24
            object.points = object.points.map { CanvasPoint(x: $0.x + 24, y: $0.y + 24) }
            object.connector = nil
            copies.append(object)
        }
        mutateActiveLayer { $0.objects.append(contentsOf: copies) }
        selectedIDs = Set(copies.map(\.id))
        finishMutation("Duplicated selection")
    }

    func setSelectionLocked(_ locked: Bool) {
        guard !selectedIDs.isEmpty else { return }
        beginMutation()
        mutatePageLayers { layer in
            for index in layer.objects.indices where selectedIDs.contains(layer.objects[index].id) {
                layer.objects[index].locked = locked
            }
        }
        finishMutation(locked ? "Locked selection" : "Unlocked selection")
    }

    func groupSelection() {
        guard selectedIDs.count > 1 else { return }
        let groupID = UUID()
        beginMutation()
        mutatePageLayers { layer in
            for index in layer.objects.indices where selectedIDs.contains(layer.objects[index].id) {
                layer.objects[index].groupID = groupID
            }
        }
        finishMutation("Grouped selection")
    }

    func undo() {
        guard let previous = undoStack.popLast() else { return }
        redoStack.append(document)
        document = previous
        selectedIDs.removeAll()
        statusMessage = "Undo"
    }

    func redo() {
        guard let next = redoStack.popLast() else { return }
        undoStack.append(document)
        document = next
        selectedIDs.removeAll()
        statusMessage = "Redo"
    }

    func addPage() {
        beginMutation()
        let page = CanvasPage(name: "Page \(document.pages.count + 1)", layers: [CanvasLayer(name: "Diagram")])
        document.pages.append(page)
        activePageID = page.id
        activeLayerID = page.layers[0].id
        finishMutation("Added page")
    }

    func deleteActivePage() {
        guard document.pages.count > 1 else { return }
        beginMutation()
        document.pages.removeAll { $0.id == activePageID }
        activePageID = document.pages[0].id
        activeLayerID = document.pages[0].layers[0].id
        finishMutation("Deleted page")
    }

    func addLayer() {
        beginMutation()
        for index in document.pages.indices where document.pages[index].id == activePageID {
            let layer = CanvasLayer(name: "Layer \(document.pages[index].layers.count + 1)")
            document.pages[index].layers.append(layer)
            activeLayerID = layer.id
        }
        finishMutation("Added layer")
    }

    func toggleLayerVisibility(_ id: UUID) {
        beginMutation()
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            if let layerIndex = document.pages[pageIndex].layers.firstIndex(where: { $0.id == id }) {
                document.pages[pageIndex].layers[layerIndex].isVisible.toggle()
            }
        }
        finishMutation("Updated layer")
    }

    func toggleLayerLock(_ id: UUID) {
        beginMutation()
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            if let layerIndex = document.pages[pageIndex].layers.firstIndex(where: { $0.id == id }) {
                document.pages[pageIndex].layers[layerIndex].isLocked.toggle()
            }
        }
        finishMutation("Updated layer")
    }

    func applyTemplate(_ template: ArchitectTemplate) {
        replaceDocument(template.makeDocument())
        statusMessage = "Loaded \(template.rawValue)"
    }

    func autoLayout(_ direction: LayoutDirection) {
        let candidates = visibleObjects.filter {
            $0.kind != .pen && $0.kind != .connector && $0.kind != .line && !$0.locked &&
            (selectedIDs.isEmpty || selectedIDs.contains($0.id))
        }
        guard !candidates.isEmpty else { return }
        beginMutation()
        let sorted = candidates.sorted { lhs, rhs in
            direction == .leftToRight ? lhs.frame.x < rhs.frame.x : lhs.frame.y < rhs.frame.y
        }
        let columns = max(1, Int(ceil(sqrt(Double(sorted.count)))))
        let startX = 150.0
        let startY = 150.0
        let spacingX = 250.0
        let spacingY = 150.0
        for (position, item) in sorted.enumerated() {
            guard var object = object(id: item.id) else { continue }
            let row = position / columns
            let column = position % columns
            if direction == .leftToRight {
                object.frame.x = startX + Double(column) * spacingX
                object.frame.y = startY + Double(row) * spacingY
            } else {
                object.frame.x = startX + Double(row) * spacingX
                object.frame.y = startY + Double(column) * spacingY
            }
            replaceObject(object)
        }
        finishMutation("Auto-layout complete")
    }

    func snap(_ point: CGPoint) -> CGPoint {
        CGPoint(x: (point.x / 8).rounded() * 8, y: (point.y / 8).rounded() * 8)
    }

    func openDocument() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.init(filenameExtension: "tpa")!]
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(ArchitectDocument.self, from: data)
            replaceDocument(decoded, url: url)
        } catch {
            presentError("Couldn’t open this Trackpad Architect document.", error)
        }
    }

    func saveDocument(saveAs: Bool = false) {
        var destination = currentURL
        if destination == nil || saveAs {
            let panel = NSSavePanel()
            panel.allowedContentTypes = [.init(filenameExtension: "tpa")!]
            panel.nameFieldStringValue = "\(document.title).tpa"
            guard panel.runModal() == .OK else { return }
            destination = panel.url
        }
        guard let destination else { return }
        do {
            let data = try encodedDocument()
            try data.write(to: destination, options: .atomic)
            currentURL = destination
            statusMessage = "Saved \(destination.lastPathComponent)"
        } catch {
            presentError("Couldn’t save this document.", error)
        }
    }

    func encodedDocument() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(document)
    }

    private func saveRecovery() {
        do {
            try FileManager.default.createDirectory(
                at: recoveryURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try encodedDocument().write(to: recoveryURL, options: .atomic)
        } catch {
            // Recovery must never interrupt drawing.
        }
    }

    private func mutateActiveLayer(_ mutation: (inout CanvasLayer) -> Void) {
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            guard let layerIndex = document.pages[pageIndex].layers.firstIndex(where: { $0.id == activeLayerID }) else { continue }
            guard !document.pages[pageIndex].layers[layerIndex].isLocked else { return }
            mutation(&document.pages[pageIndex].layers[layerIndex])
        }
    }

    private func mutatePageLayers(_ mutation: (inout CanvasLayer) -> Void) {
        for pageIndex in document.pages.indices where document.pages[pageIndex].id == activePageID {
            for layerIndex in document.pages[pageIndex].layers.indices where !document.pages[pageIndex].layers[layerIndex].isLocked {
                mutation(&document.pages[pageIndex].layers[layerIndex])
            }
        }
    }

    private func presentError(_ message: String, _ error: Error) {
        let alert = NSAlert()
        alert.messageText = message
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }
}
