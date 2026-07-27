import AppKit
import Combine
import CoreGraphics
import SwiftUI

struct CanvasHost: NSViewRepresentable {
    @ObservedObject var store: ArchitectStore

    func makeNSView(context: Context) -> ArchitectCanvasView {
        ArchitectCanvasView(store: store)
    }

    func updateNSView(_ nsView: ArchitectCanvasView, context: Context) {
        nsView.store = store
        nsView.updateZenMode()
        nsView.needsDisplay = true
    }
}

final class ArchitectCanvasView: NSView {
    struct Draft {
        var kind: DiagramKind
        var start: CGPoint
        var current: CGPoint
        var points: [CanvasPoint]
    }

    var store: ArchitectStore
    private var draft: Draft?
    private var lastDragPoint: CGPoint?
    private var movingSelection = false
    private var resizingObject: DiagramObject?
    private var panning = false
    private var hiddenCursor = false
    private var touchDrawing = false
    private var touchFingerID: Int?
    private var touchDraft: [CanvasPoint] = []
    private var touchLineWidth = 2.5
    private var twoFingerCentroid: CGPoint?
    private var twoFingerSpread: CGFloat?
    private var windowObservers: [NSObjectProtocol] = []

    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    init(store: ArchitectStore) {
        self.store = store
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = RGBAColor.paper.nsColor.cgColor
        allowedTouchTypes = [.indirect]
        wantsRestingTouches = true
        MultitouchReader.shared.onFrame = { [weak self] samples in
            self?.handleRawTouches(samples)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("ArchitectCanvasView does not support NSCoder")
    }

    deinit {
        restoreCursor()
        windowObservers.forEach(NotificationCenter.default.removeObserver)
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        windowObservers.forEach(NotificationCenter.default.removeObserver)
        windowObservers.removeAll()
        guard let window else {
            restoreCursor()
            return
        }
        let center = NotificationCenter.default
        windowObservers.append(center.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.restoreCursor()
        })
        windowObservers.append(center.addObserver(forName: NSWindow.didBecomeKeyNotification, object: window, queue: .main) { [weak self] _ in
            self?.updateZenMode()
        })
        updateZenMode()
    }

    func updateZenMode() {
        guard store.zenMode, window?.isKeyWindow == true else {
            restoreCursor()
            return
        }
        guard !hiddenCursor else { return }
        CGAssociateMouseAndMouseCursorPosition(boolean_t(0))
        NSCursor.hide()
        hiddenCursor = true
        store.statusMessage = "Touch the trackpad to draw · Two fingers navigate"
    }

    private func restoreCursor() {
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        if hiddenCursor {
            NSCursor.unhide()
            hiddenCursor = false
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        RGBAColor.paper.nsColor.setFill()
        NSBezierPath(rect: bounds).fill()

        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: CGFloat(store.pan.x), yBy: CGFloat(store.pan.y))
        transform.scale(by: CGFloat(store.zoom))
        transform.concat()
        let canvasBounds = CGRect(
            x: -CGFloat(store.pan.x) / CGFloat(store.zoom),
            y: -CGFloat(store.pan.y) / CGFloat(store.zoom),
            width: bounds.width / CGFloat(store.zoom),
            height: bounds.height / CGFloat(store.zoom)
        )
        CanvasRenderer.draw(
            page: store.activePage,
            selectedIDs: store.selectedIDs,
            showGrid: store.showGrid,
            showPresentationFrame: store.showPresentationFrame,
            in: canvasBounds
        )
        drawDraft()
        NSGraphicsContext.restoreGraphicsState()

        drawModeBadge()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let point = canvasPoint(event.locationInWindow)
        let snapped = store.snap(point)

        if store.tool == .select {
            if let selected = store.selectedIDs.compactMap({ store.object(id: $0) }).first,
               resizeHandle(for: selected).insetBy(dx: -8, dy: -8).contains(point) {
                store.beginMutation()
                resizingObject = selected
                lastDragPoint = point
                return
            }
            if let id = store.hitTest(point) {
                if !event.modifierFlags.contains(.shift) {
                    store.selectedIDs = [id]
                } else if store.selectedIDs.contains(id) {
                    store.selectedIDs.remove(id)
                } else {
                    store.selectedIDs.insert(id)
                }
                store.beginMutation()
                movingSelection = true
                lastDragPoint = point
            } else {
                store.selectedIDs.removeAll()
            }
            needsDisplay = true
            return
        }

        if store.tool == .hand {
            panning = true
            lastDragPoint = convert(event.locationInWindow, from: nil)
            return
        }

        if store.tool == .text {
            createText(at: snapped)
            return
        }

        draft = Draft(
            kind: diagramKind(for: store.tool),
            start: snapped,
            current: snapped,
            points: [CanvasPoint(snapped)]
        )
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        let point = canvasPoint(event.locationInWindow)
        if movingSelection, let lastDragPoint {
            let snapped = store.snap(point)
            let last = store.snap(lastDragPoint)
            store.moveSelection(by: CGPoint(x: snapped.x - last.x, y: snapped.y - last.y), recordUndo: false)
            self.lastDragPoint = point
            needsDisplay = true
            return
        }
        if var resizingObject, let lastDragPoint {
            let delta = CGPoint(x: point.x - lastDragPoint.x, y: point.y - lastDragPoint.y)
            resizingObject.frame.width = max(24, resizingObject.frame.width + Double(delta.x))
            resizingObject.frame.height = max(24, resizingObject.frame.height + Double(delta.y))
            store.replaceObject(resizingObject)
            self.resizingObject = resizingObject
            self.lastDragPoint = point
            needsDisplay = true
            return
        }
        if panning, let lastDragPoint {
            let viewPoint = convert(event.locationInWindow, from: nil)
            store.pan.x += Double(viewPoint.x - lastDragPoint.x)
            store.pan.y += Double(viewPoint.y - lastDragPoint.y)
            self.lastDragPoint = viewPoint
            needsDisplay = true
            return
        }
        guard var draft else { return }
        draft.current = store.snap(point)
        if draft.kind == .pen { draft.points.append(CanvasPoint(point)) }
        self.draft = draft
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if movingSelection {
            movingSelection = false
            lastDragPoint = nil
            store.finishMutation("Moved selection")
            return
        }
        if resizingObject != nil {
            resizingObject = nil
            lastDragPoint = nil
            store.finishMutation("Resized selection")
            return
        }
        if panning {
            panning = false
            lastDragPoint = nil
            return
        }
        commitDraft()
    }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.command) {
            let factor = 1 + Double(-event.scrollingDeltaY) * 0.01
            store.zoom = min(5, max(0.2, store.zoom * factor))
        } else {
            store.pan.x += Double(event.scrollingDeltaX)
            store.pan.y += Double(event.scrollingDeltaY)
        }
        needsDisplay = true
    }

    override func magnify(with event: NSEvent) {
        store.zoom = min(5, max(0.2, store.zoom * (1 + Double(event.magnification))))
        needsDisplay = true
    }

    override func keyDown(with event: NSEvent) {
        let key = event.charactersIgnoringModifiers?.lowercased() ?? ""
        if key == "z", !event.modifierFlags.contains(.command) {
            store.zenMode.toggle()
            updateZenMode()
            needsDisplay = true
            return
        }
        if event.keyCode == 51 || event.keyCode == 117 {
            store.deleteSelection()
            needsDisplay = true
            return
        }
        super.keyDown(with: event)
    }

    private func handleRawTouches(_ samples: [MTFingerSample]) {
        guard store.zenMode, window?.isKeyWindow == true else { return }
        if samples.count == 2 {
            endTouchStroke()
            let centroid = CGPoint(
                x: (samples[0].position.x + samples[1].position.x) / 2,
                y: (samples[0].position.y + samples[1].position.y) / 2
            )
            let spread = hypot(
                samples[0].position.x - samples[1].position.x,
                samples[0].position.y - samples[1].position.y
            )
            if let previous = twoFingerCentroid, let previousSpread = twoFingerSpread {
                store.pan.x += Double((centroid.x - previous.x) * bounds.width)
                store.pan.y -= Double((centroid.y - previous.y) * bounds.height)
                if previousSpread > 0.001 {
                    store.zoom = min(5, max(0.2, store.zoom * Double(spread / previousSpread)))
                }
            }
            twoFingerCentroid = centroid
            twoFingerSpread = spread
            needsDisplay = true
            return
        }
        twoFingerCentroid = nil
        twoFingerSpread = nil

        guard samples.count == 1 else {
            endTouchStroke()
            return
        }
        let pen = samples[0]
        touchFingerID = pen.id
        let viewPoint = CGPoint(
            x: pen.position.x * bounds.width,
            y: (1 - pen.position.y) * bounds.height
        )
        let rawPoint = canvasPointFromView(viewPoint)
        let point: CGPoint
        if let previous = touchDraft.last?.cgPoint {
            let responsiveness: CGFloat = 0.34
            point = CGPoint(
                x: previous.x + (rawPoint.x - previous.x) * responsiveness,
                y: previous.y + (rawPoint.y - previous.y) * responsiveness
            )
            guard hypot(point.x - previous.x, point.y - previous.y) > 0.45 else { return }
        } else {
            point = rawPoint
        }
        let measuredWidth = min(10, max(1.5, 1.3 + pen.size * 5.5))
        touchLineWidth = touchLineWidth * 0.72 + measuredWidth * 0.28
        if !touchDrawing {
            touchDrawing = true
            touchDraft = [CanvasPoint(point)]
        } else {
            touchDraft.append(CanvasPoint(point))
        }
        needsDisplay = true
    }

    private func endTouchStroke() {
        guard touchDrawing, touchDraft.count > 1 else {
            touchDrawing = false
            touchFingerID = nil
            touchDraft.removeAll()
            return
        }
        let rect = boundsForPoints(touchDraft)
        var style = store.currentStyle
        style.lineWidth = touchLineWidth
        let object = DiagramObject(
            kind: .pen,
            frame: CanvasRect(rect),
            points: touchDraft,
            style: style
        )
        store.addObject(object)
        touchDrawing = false
        touchFingerID = nil
        touchDraft.removeAll()
        touchLineWidth = store.currentStyle.lineWidth
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
    }

    private func commitDraft() {
        guard let draft else { return }
        let frame = CGRect(
            x: min(draft.start.x, draft.current.x),
            y: min(draft.start.y, draft.current.y),
            width: max(1, abs(draft.current.x - draft.start.x)),
            height: max(1, abs(draft.current.y - draft.start.y))
        )
        var object = DiagramObject(
            kind: draft.kind,
            frame: CanvasRect(frame),
            points: draft.kind == .pen ? draft.points : [],
            style: store.currentStyle
        )
        if draft.kind == .connector {
            let startID = store.hitTest(draft.start)
            let endID = store.hitTest(draft.current)
            object.connector = ConnectorBinding(
                start: ConnectorEndpoint(objectID: startID, anchor: .right, point: CanvasPoint(draft.start)),
                end: ConnectorEndpoint(objectID: endID, anchor: .left, point: CanvasPoint(draft.current))
            )
        }
        store.addObject(object)
        self.draft = nil
        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        needsDisplay = true
    }

    private func createText(at point: CGPoint) {
        let field = NSTextField(string: "New label")
        field.frame = CGRect(x: 0, y: 0, width: 260, height: 26)
        let alert = NSAlert()
        alert.messageText = "Add text"
        alert.informativeText = "Type the label that belongs on the canvas."
        alert.accessoryView = field
        alert.addButton(withTitle: "Add")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let object = DiagramObject(
            kind: .text,
            frame: CanvasRect(x: point.x, y: point.y, width: 260, height: 42),
            text: field.stringValue,
            style: store.currentStyle
        )
        store.addObject(object)
        needsDisplay = true
    }

    private func drawDraft() {
        var preview: DiagramObject?
        if let draft {
            let frame = CGRect(
                x: min(draft.start.x, draft.current.x),
                y: min(draft.start.y, draft.current.y),
                width: max(1, abs(draft.current.x - draft.start.x)),
                height: max(1, abs(draft.current.y - draft.start.y))
            )
            preview = DiagramObject(
                kind: draft.kind,
                frame: CanvasRect(frame),
                points: draft.points,
                style: store.currentStyle
            )
        } else if touchDrawing {
            preview = DiagramObject(
                kind: .pen,
                frame: CanvasRect(boundsForPoints(touchDraft)),
                points: touchDraft,
                style: store.currentStyle
            )
        }
        guard let preview else { return }
        let page = CanvasPage(name: "Preview", layers: [CanvasLayer(name: "Preview", objects: [preview])])
        CanvasRenderer.draw(page: page, showGrid: false, showPresentationFrame: false, in: bounds)
    }

    private func drawModeBadge() {
        let title = store.zenMode ? "TRACKPAD CANVAS · TOUCH TO DRAW" : "POINTER · Z FOR CANVAS"
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: store.zenMode ? NSColor.white : RGBAColor.ink.nsColor,
        ]
        let size = (title as NSString).size(withAttributes: attributes)
        let rect = CGRect(x: 14, y: bounds.maxY - 34, width: size.width + 20, height: 24)
        (store.zenMode ? RGBAColor.violet.nsColor : NSColor.white.withAlphaComponent(0.88)).setFill()
        NSBezierPath(roundedRect: rect, xRadius: 12, yRadius: 12).fill()
        (title as NSString).draw(at: CGPoint(x: rect.minX + 10, y: rect.minY + 5), withAttributes: attributes)
    }

    private func canvasPoint(_ locationInWindow: CGPoint) -> CGPoint {
        canvasPointFromView(convert(locationInWindow, from: nil))
    }

    private func canvasPointFromView(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x - CGFloat(store.pan.x)) / CGFloat(store.zoom),
            y: (point.y - CGFloat(store.pan.y)) / CGFloat(store.zoom)
        )
    }

    private func resizeHandle(for object: DiagramObject) -> CGRect {
        let bounds = object.bounds
        return CGRect(x: bounds.maxX - 5, y: bounds.maxY - 5, width: 10, height: 10)
    }

    private func diagramKind(for tool: CanvasTool) -> DiagramKind {
        switch tool {
        case .pen: return .pen
        case .line: return .line
        case .rectangle: return .rectangle
        case .ellipse: return .ellipse
        case .arrow: return .arrow
        case .connector: return .connector
        case .text: return .text
        case .select, .hand: return .pen
        }
    }

    private func boundsForPoints(_ points: [CanvasPoint]) -> CGRect {
        guard let first = points.first else { return .zero }
        return points.dropFirst().reduce(CGRect(x: first.x, y: first.y, width: 1, height: 1)) { partial, point in
            partial.union(CGRect(x: point.x, y: point.y, width: 1, height: 1))
        }
    }
}
