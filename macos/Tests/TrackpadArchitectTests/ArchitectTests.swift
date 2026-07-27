import XCTest
@testable import TrackpadArchitect

@MainActor
final class ArchitectTests: XCTestCase {
    func testDocumentRoundTrip() throws {
        let original = ArchitectTemplate.pipeline.makeDocument()
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(ArchitectDocument.self, from: data)
        XCTAssertEqual(decoded, original)
        XCTAssertEqual(decoded.schemaVersion, DocumentSchemaVersion.v1.rawValue)
    }

    func testConnectorTargetsPersist() {
        let document = ArchitectTemplate.pipeline.makeDocument()
        let objects = document.pages[0].layers[0].objects
        let connector = objects.first(where: { $0.kind == .connector })
        XCTAssertNotNil(connector?.connector?.start.objectID)
        XCTAssertNotNil(connector?.connector?.end.objectID)
    }

    func testGridSnap() {
        let store = ArchitectStore()
        XCTAssertEqual(store.snap(CGPoint(x: 11, y: 29)), CGPoint(x: 8, y: 32))
    }

    func testUndoRedo() {
        let store = ArchitectStore()
        let object = DiagramObject(
            kind: .rectangle,
            frame: CanvasRect(x: 10, y: 10, width: 100, height: 60)
        )
        store.addObject(object)
        XCTAssertEqual(store.visibleObjects.count, 1)
        store.undo()
        XCTAssertTrue(store.visibleObjects.isEmpty)
        store.redo()
        XCTAssertEqual(store.visibleObjects.count, 1)
    }

    func testSVGIncludesShapesAndText() {
        let page = ArchitectTemplate.context.makeDocument().pages[0]
        let svg = CanvasRenderer.svg(page: page, crop: page.presentationFrame.cgRect)
        XCTAssertTrue(svg.contains("<svg"))
        XCTAssertTrue(svg.contains("Core system"))
        XCTAssertTrue(svg.contains("<path"))
    }

    func testAutoLayoutPreservesLockedObjects() {
        var document = ArchitectTemplate.breakdown.makeDocument()
        document.pages[0].layers[0].objects[0].locked = true
        let locked = document.pages[0].layers[0].objects[0]
        let store = ArchitectStore(document: document)
        store.autoLayout(.leftToRight)
        XCTAssertEqual(store.object(id: locked.id)?.frame, locked.frame)
    }
}

