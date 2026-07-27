import AppKit
import CoreGraphics
import UniformTypeIdentifiers

@MainActor
enum ExportService {
    static func copySelection(from store: ArchitectStore) {
        let page = store.activePage
        let crop = exportBounds(for: page, selectedIDs: store.selectedIDs)
        let svg = CanvasRenderer.svg(page: filteredPage(page, selectedIDs: store.selectedIDs), crop: crop)
        let png = renderPNG(page: page, crop: crop)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        var items: [NSPasteboardItem] = []
        let svgItem = NSPasteboardItem()
        svgItem.setString(svg, forType: NSPasteboard.PasteboardType("public.svg-image"))
        items.append(svgItem)
        if let png {
            let pngItem = NSPasteboardItem()
            pngItem.setData(png, forType: .png)
            items.append(pngItem)
        }
        pasteboard.writeObjects(items)
        store.statusMessage = "Copied SVG + PNG for PowerPoint"
    }

    static func exportCurrentPage(from store: ArchitectStore, type: UTType) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [type]
        panel.nameFieldStringValue = "\(store.activePage.name).\(type.preferredFilenameExtension ?? "png")"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let page = store.activePage
        let crop = page.presentationFrame.cgRect
        do {
            if type == .png, let data = renderPNG(page: page, crop: crop) {
                try data.write(to: url)
            } else if type == .svg {
                try CanvasRenderer.svg(page: page, crop: crop).data(using: .utf8)?.write(to: url)
            } else if type == .pdf {
                try renderPDF(pages: [page]).write(to: url)
            }
            store.statusMessage = "Exported \(url.lastPathComponent)"
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    static func exportAllPagesPDF(from store: ArchitectStore) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(store.document.title).pdf"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try renderPDF(pages: store.document.pages).write(to: url)
            store.statusMessage = "Exported multi-page PDF"
        } catch {
            let alert = NSAlert()
            alert.messageText = "PDF export failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    static func renderPNG(page: CanvasPage, crop: CGRect, transparent: Bool = false) -> Data? {
        let width = max(1, Int(crop.width.rounded()))
        let height = max(1, Int(crop.height.rounded()))
        guard let bitmap = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: width,
            pixelsHigh: height,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }
        bitmap.size = NSSize(width: width, height: height)
        NSGraphicsContext.saveGraphicsState()
        guard let context = NSGraphicsContext(bitmapImageRep: bitmap) else { return nil }
        NSGraphicsContext.current = context
        if !transparent {
            RGBAColor.paper.nsColor.setFill()
            NSBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: height)).fill()
        }
        let transform = NSAffineTransform()
        transform.translateX(by: -crop.minX, yBy: -crop.minY)
        transform.concat()
        CanvasRenderer.draw(page: page, showGrid: false, showPresentationFrame: false, in: crop)
        context.flushGraphics()
        NSGraphicsContext.restoreGraphicsState()
        return bitmap.representation(using: .png, properties: [:])
    }

    static func renderPDF(pages: [CanvasPage]) throws -> Data {
        let data = NSMutableData()
        guard let consumer = CGDataConsumer(data: data as CFMutableData) else {
            throw CocoaError(.fileWriteUnknown)
        }
        var mediaBox = CGRect(x: 0, y: 0, width: 960, height: 540)
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw CocoaError(.fileWriteUnknown)
        }
        for page in pages {
            let crop = page.presentationFrame.cgRect
            mediaBox = CGRect(origin: .zero, size: crop.size)
            context.beginPDFPage([kCGPDFContextMediaBox: NSData(bytes: &mediaBox, length: MemoryLayout<CGRect>.size)] as CFDictionary)
            let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = nsContext
            RGBAColor.paper.nsColor.setFill()
            NSBezierPath(rect: mediaBox).fill()
            let transform = NSAffineTransform()
            transform.translateX(by: -crop.minX, yBy: -crop.minY)
            transform.concat()
            CanvasRenderer.draw(page: page, showGrid: false, showPresentationFrame: false, in: crop)
            NSGraphicsContext.restoreGraphicsState()
            context.endPDFPage()
        }
        context.closePDF()
        return data as Data
    }

    private static func exportBounds(for page: CanvasPage, selectedIDs: Set<UUID>) -> CGRect {
        let objects = page.layers.flatMap(\.objects).filter { selectedIDs.isEmpty || selectedIDs.contains($0.id) }
        guard let first = objects.first else { return page.presentationFrame.cgRect }
        return objects.dropFirst().reduce(first.bounds) { $0.union($1.bounds) }.insetBy(dx: -20, dy: -20)
    }

    private static func filteredPage(_ page: CanvasPage, selectedIDs: Set<UUID>) -> CanvasPage {
        guard !selectedIDs.isEmpty else { return page }
        var copy = page
        for index in copy.layers.indices {
            copy.layers[index].objects = copy.layers[index].objects.filter { selectedIDs.contains($0.id) }
        }
        return copy
    }
}

