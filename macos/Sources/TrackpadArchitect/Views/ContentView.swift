import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: ArchitectStore
    @Environment(\.openWindow) private var openWindow
    @State private var showInspector = true

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 170, ideal: 210, max: 260)
        } detail: {
            HSplitView {
                VStack(spacing: 0) {
                    ToolShelf(store: store)
                    Divider()
                    CanvasHost(store: store)
                        .accessibilityLabel("Architecture canvas")
                        .background(Color(red: 0.985, green: 0.98, blue: 0.94))
                    Divider()
                    StatusBar(store: store)
                }
                if showInspector {
                    InspectorView(store: store)
                        .frame(minWidth: 220, idealWidth: 260, maxWidth: 320)
                }
            }
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        store.undo()
                    } label: {
                        Label("Undo", systemImage: "arrow.uturn.backward")
                    }
                    .disabled(!store.canUndo)
                    .help("Undo (⌘Z)")

                    Button {
                        store.redo()
                    } label: {
                        Label("Redo", systemImage: "arrow.uturn.forward")
                    }
                    .disabled(!store.canRedo)
                    .help("Redo (⇧⌘Z)")

                    Divider()

                    Button {
                        store.autoLayout(.leftToRight)
                    } label: {
                        Label("Layout left to right", systemImage: "rectangle.3.group")
                    }
                    .help("Auto-layout selected objects left to right")

                    Button {
                        ExportService.copySelection(from: store)
                    } label: {
                        Label("Copy for PowerPoint", systemImage: "doc.on.doc")
                    }
                    .help("Copy SVG + PNG (⌘C)")

                    Button {
                        showInspector.toggle()
                    } label: {
                        Label("Inspector", systemImage: "sidebar.right")
                    }
                    .help("Toggle Inspector (⌥⌘I)")

                    Button {
                        openWindow(id: "trackpad-lab")
                    } label: {
                        Label("Trackpad Lab", systemImage: "waveform.path.ecg.rectangle")
                    }
                    .help("Open Trackpad Lab")
                }
            }
        }
        .navigationTitle(store.document.title)
        .frame(minWidth: 980, minHeight: 650)
        .onChange(of: store.activePageID) { newPageID in
            if let page = store.document.pages.first(where: { $0.id == newPageID }),
               let firstLayer = page.layers.first {
                store.activeLayerID = firstLayer.id
                store.selectedIDs.removeAll()
            }
        }
    }
}

private struct SidebarView: View {
    @ObservedObject var store: ArchitectStore

    var body: some View {
        VStack(spacing: 0) {
            List(selection: $store.activePageID) {
                Section("Pages") {
                    ForEach(store.document.pages) { page in
                        Label(page.name, systemImage: "rectangle.on.rectangle")
                            .tag(page.id)
                    }
                }
            }
            .listStyle(.sidebar)

            HStack {
                Button {
                    store.addPage()
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add page")

                Button {
                    store.deleteActivePage()
                } label: {
                    Image(systemName: "minus")
                }
                .disabled(store.document.pages.count == 1)
                .help("Delete page")

                Spacer()

                Menu {
                    ForEach(ArchitectTemplate.allCases) { template in
                        Button(template.rawValue) {
                            store.applyTemplate(template)
                        }
                    }
                } label: {
                    Label("Templates", systemImage: "square.grid.2x2")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(10)
        }
    }
}

private struct ToolShelf: View {
    @ObservedObject var store: ArchitectStore

    var body: some View {
        HStack(spacing: 5) {
            ForEach(CanvasTool.allCases) { tool in
                Button {
                    store.tool = tool
                    store.zenMode = false
                    store.statusMessage = "\(tool.title) tool"
                } label: {
                    Image(systemName: tool.symbol)
                        .frame(width: 25, height: 25)
                }
                .buttonStyle(.bordered)
                .tint(store.tool == tool ? Color(red: 0.37, green: 0.30, blue: 0.88) : .clear)
                .help("\(tool.title) tool")
                .accessibilityLabel("\(tool.title) tool")
            }

            Divider()
                .frame(height: 24)

            Button {
                store.zenMode.toggle()
                store.statusMessage = store.zenMode
                    ? "Touch the trackpad to draw"
                    : "Pointer mode"
            } label: {
                Label(store.zenMode ? "Zen on" : "Zen", systemImage: store.zenMode ? "scope" : "cursorarrow.motionlines")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.37, green: 0.30, blue: 0.88))
            .help("Toggle direct trackpad canvas (Z)")

            Spacer()

            Button {
                store.zoom = max(0.2, store.zoom / 1.2)
            } label: {
                Image(systemName: "minus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Zoom out")

            Text("\(Int(store.zoom * 100))%")
                .font(.system(.caption, design: .monospaced))
                .frame(width: 44)

            Button {
                store.zoom = min(5, store.zoom * 1.2)
            } label: {
                Image(systemName: "plus.magnifyingglass")
            }
            .buttonStyle(.borderless)
            .help("Zoom in")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

private struct InspectorView: View {
    @ObservedObject var store: ArchitectStore

    private let swatches: [RGBAColor] = [.ink, .violet, .mint, .coral, .sky]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Group {
                    Text("Style")
                        .font(.headline)

                    Text("Stroke")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        ForEach(Array(swatches.enumerated()), id: \.offset) { _, color in
                            Button {
                                store.currentStyle.stroke = color
                            } label: {
                                Circle()
                                    .fill(Color(nsColor: color.nsColor))
                                    .frame(width: 24, height: 24)
                                    .overlay {
                                        if store.currentStyle.stroke == color {
                                            Circle().stroke(.primary, lineWidth: 2).padding(-3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose stroke color")
                        }
                    }

                    Text("Fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Button {
                            store.currentStyle.fill = .clear
                        } label: {
                            Image(systemName: "slash.circle")
                                .frame(width: 24, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("No fill")

                        ForEach(Array(swatches.dropFirst(2).enumerated()), id: \.offset) { _, color in
                            Button {
                                store.currentStyle.fill = color
                            } label: {
                                RoundedRectangle(cornerRadius: 5)
                                    .fill(Color(nsColor: color.nsColor))
                                    .frame(width: 28, height: 24)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Choose fill color")
                        }
                    }

                    VStack(alignment: .leading) {
                        Text("Line width · \(store.currentStyle.lineWidth, specifier: "%.1f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Slider(value: $store.currentStyle.lineWidth, in: 1...8, step: 0.5)
                    }
                }

                Divider()

                Group {
                    HStack {
                        Text("Layers")
                            .font(.headline)
                        Spacer()
                        Button {
                            store.addLayer()
                        } label: {
                            Image(systemName: "plus")
                        }
                        .buttonStyle(.borderless)
                        .help("Add layer")
                    }

                    ForEach(store.activePage.layers.reversed()) { layer in
                        HStack {
                            Button {
                                store.toggleLayerVisibility(layer.id)
                            } label: {
                                Image(systemName: layer.isVisible ? "eye" : "eye.slash")
                            }
                            .buttonStyle(.borderless)
                            .help(layer.isVisible ? "Hide layer" : "Show layer")

                            Text(layer.name)
                                .lineLimit(1)
                            Spacer()
                            Button {
                                store.toggleLayerLock(layer.id)
                            } label: {
                                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                            }
                            .buttonStyle(.borderless)
                            .help(layer.isLocked ? "Unlock layer" : "Lock layer")
                        }
                        .padding(.vertical, 3)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            store.activeLayerID = layer.id
                        }
                    }
                }

                Divider()

                Group {
                    Text("Selection")
                        .font(.headline)
                    HStack {
                        Button("Group") { store.groupSelection() }
                            .disabled(store.selectedIDs.count < 2)
                        Button("Lock") { store.setSelectionLocked(true) }
                            .disabled(store.selectedIDs.isEmpty)
                    }
                    HStack {
                        Button("Duplicate") { store.duplicateSelection() }
                            .disabled(store.selectedIDs.isEmpty)
                        Button("Delete", role: .destructive) { store.deleteSelection() }
                            .disabled(store.selectedIDs.isEmpty)
                    }
                }

                Divider()
                Group {
                    Toggle("8 pt grid", isOn: $store.showGrid)
                    Toggle("16:9 frame", isOn: $store.showPresentationFrame)
                }
            }
            .padding(16)
        }
    }
}

private struct StatusBar: View {
    @ObservedObject var store: ArchitectStore

    var body: some View {
        HStack {
            Circle()
                .fill(MultitouchReader.shared.isAvailable ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(MultitouchReader.shared.isAvailable ? "Trackpad ready" : "Pointer fallback")
            Text("·")
            Text(store.statusMessage)
            Spacer()
            Text("\(store.selectedIDs.count) selected")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .frame(height: 28)
        .background(.bar)
    }
}
