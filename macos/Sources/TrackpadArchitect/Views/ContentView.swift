import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @ObservedObject var store: ArchitectStore
    @Environment(\.openWindow) private var openWindow
    @State private var showInspector = false

    var body: some View {
        NavigationSplitView {
            SidebarView(store: store)
                .navigationSplitViewColumnWidth(min: 175, ideal: 205, max: 240)
        } detail: {
            HSplitView {
                ZStack {
                    CanvasHost(store: store)
                        .accessibilityLabel("Architecture canvas")
                        .background(Color(red: 0.985, green: 0.98, blue: 0.94))

                    VStack(spacing: 0) {
                        FloatingToolShelf(store: store)
                            .padding(.top, 16)
                        Spacer()
                        StatusPill(store: store)
                            .padding(.bottom, 14)
                    }
                    .padding(.horizontal, 16)
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
            HStack(spacing: 11) {
                BrandLogo(size: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Trackpad")
                    Text("Architect")
                }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color(red: 0.05, green: 0.04, blue: 0.28))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 10)

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

private struct FloatingToolShelf: View {
    @ObservedObject var store: ArchitectStore

    var body: some View {
        HStack(spacing: 3) {
            Button {
                store.zenMode = true
                store.statusMessage = "Touch the trackpad to draw"
            } label: {
                HStack(spacing: 7) {
                    Circle()
                        .fill(Color(red: 0.65, green: 0.95, blue: 0.69))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color(red: 0.65, green: 0.95, blue: 0.69), radius: 5)
                    Text("CANVAS")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                }
                .padding(.horizontal, 11)
                .frame(height: 34)
                .background(
                    store.zenMode
                        ? Color(red: 0.37, green: 0.30, blue: 0.88)
                        : Color.white.opacity(0.08)
                )
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .help("Direct trackpad canvas (Z)")

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 4)

            ForEach(CanvasTool.allCases) { tool in
                Button {
                    store.tool = tool
                    store.zenMode = false
                    store.statusMessage = "\(tool.title) tool"
                } label: {
                    Image(systemName: tool.symbol)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 30, height: 30)
                        .foregroundStyle(
                            !store.zenMode && store.tool == tool
                                ? Color.white
                                : Color.white.opacity(0.66)
                        )
                        .background(
                            !store.zenMode && store.tool == tool
                                ? Color(red: 0.37, green: 0.30, blue: 0.88)
                                : Color.clear
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("\(tool.title) tool")
                .accessibilityLabel("\(tool.title) tool")
            }

            Rectangle()
                .fill(Color.white.opacity(0.16))
                .frame(width: 1, height: 22)
                .padding(.horizontal, 4)

            Button {
                store.autoLayout(.leftToRight)
            } label: {
                Image(systemName: "rectangle.3.group")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .foregroundStyle(Color.white.opacity(0.72))
            }
            .buttonStyle(.plain)
            .help("Auto-layout")
        }
        .padding(6)
        .background(Color(red: 0.05, green: 0.04, blue: 0.28).opacity(0.96))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.11), lineWidth: 1)
        }
        .shadow(color: Color.black.opacity(0.22), radius: 16, y: 8)
        .fixedSize()
    }
}

private struct BrandLogo: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.27, style: .continuous)
                .fill(Color(red: 0.05, green: 0.04, blue: 0.28))
            RoundedRectangle(cornerRadius: size * 0.21, style: .continuous)
                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                .padding(size * 0.13)
            Path { path in
                path.move(to: CGPoint(x: size * 0.22, y: size * 0.62))
                path.addCurve(
                    to: CGPoint(x: size * 0.76, y: size * 0.35),
                    control1: CGPoint(x: size * 0.40, y: size * 0.25),
                    control2: CGPoint(x: size * 0.57, y: size * 0.77)
                )
            }
            .stroke(
                Color(red: 0.65, green: 0.95, blue: 0.69),
                style: StrokeStyle(lineWidth: max(2, size * 0.075), lineCap: .round)
            )
            Circle()
                .fill(Color(red: 1.0, green: 0.55, blue: 0.47))
                .frame(width: size * 0.16, height: size * 0.16)
                .offset(x: size * 0.25, y: -size * 0.21)
        }
        .frame(width: size, height: size)
        .shadow(color: Color(red: 0.37, green: 0.30, blue: 0.88).opacity(0.28), radius: 7, y: 3)
        .accessibilityHidden(true)
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

private struct StatusPill: View {
    @ObservedObject var store: ArchitectStore

    var body: some View {
        HStack {
            Circle()
                .fill(MultitouchReader.shared.isAvailable ? Color.green : Color.orange)
                .frame(width: 7, height: 7)
            Text(MultitouchReader.shared.isAvailable ? "Trackpad ready" : "Pointer fallback")
            Text("·")
            Text(store.zenMode ? "Touch to draw" : store.statusMessage)
            Text("·")
            Text("Z")
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundStyle(Color(red: 0.05, green: 0.04, blue: 0.28))
                .frame(width: 18, height: 18)
                .background(Color.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            Text(store.zenMode ? "to exit drawing" : "to draw")
                .foregroundStyle(Color.white)
            Text("·")
            Text("\(Int(store.zoom * 100))%")
            if !store.selectedIDs.isEmpty {
                Text("·")
                Text("\(store.selectedIDs.count) selected")
            }
        }
        .font(.system(size: 10, weight: .medium, design: .monospaced))
        .foregroundStyle(Color.white.opacity(0.76))
        .padding(.horizontal, 12)
        .frame(height: 26)
        .background(Color(red: 0.05, green: 0.04, blue: 0.28).opacity(0.86))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.14), radius: 8, y: 4)
        .fixedSize()
    }
}
