import AppKit
import SwiftUI
import UniformTypeIdentifiers

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        MultitouchReader.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        CGAssociateMouseAndMouseCursorPosition(boolean_t(1))
        MultitouchReader.shared.stop()
    }
}

@main
struct TrackpadArchitectApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var store = ArchitectStore()

    var body: some Scene {
        WindowGroup {
            ContentView(store: store)
        }
        .defaultSize(width: 1240, height: 780)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New from Blank") {
                    store.applyTemplate(.blank)
                }
                .keyboardShortcut("n")

                Menu("New from Template") {
                    ForEach(ArchitectTemplate.allCases) { template in
                        Button(template.rawValue) {
                            store.applyTemplate(template)
                        }
                    }
                }

                Divider()

                Button("Open…") {
                    store.openDocument()
                }
                .keyboardShortcut("o")

                Button("Save") {
                    store.saveDocument()
                }
                .keyboardShortcut("s")

                Button("Save As…") {
                    store.saveDocument(saveAs: true)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }

            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { store.undo() }
                    .keyboardShortcut("z")
                    .disabled(!store.canUndo)
                Button("Redo") { store.redo() }
                    .keyboardShortcut("z", modifiers: [.command, .shift])
                    .disabled(!store.canRedo)
            }

            CommandGroup(after: .pasteboard) {
                Button("Copy SVG + PNG") {
                    ExportService.copySelection(from: store)
                }
                .keyboardShortcut("c")

                Button("Duplicate") {
                    store.duplicateSelection()
                }
                .keyboardShortcut("d")
            }

            CommandMenu("Arrange") {
                Button("Auto-layout Left to Right") {
                    store.autoLayout(.leftToRight)
                }
                Button("Auto-layout Top to Bottom") {
                    store.autoLayout(.topToBottom)
                }
                Divider()
                Button("Group") { store.groupSelection() }
                    .keyboardShortcut("g")
                Button("Lock") { store.setSelectionLocked(true) }
                    .keyboardShortcut("l")
                Button("Unlock") { store.setSelectionLocked(false) }
                    .keyboardShortcut("l", modifiers: [.command, .option])
            }

            CommandMenu("Export") {
                Button("Export Page as PNG…") {
                    ExportService.exportCurrentPage(from: store, type: .png)
                }
                Button("Export Page as SVG…") {
                    ExportService.exportCurrentPage(from: store, type: .svg)
                }
                Button("Export Page as PDF…") {
                    ExportService.exportCurrentPage(from: store, type: .pdf)
                }
                Button("Export All Pages as PDF…") {
                    ExportService.exportAllPagesPDF(from: store)
                }
            }
        }

        Window("Trackpad Lab", id: "trackpad-lab") {
            TrackpadLabView()
        }
        .defaultSize(width: 760, height: 520)
    }
}

