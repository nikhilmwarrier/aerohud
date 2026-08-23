import AppKit
import SwiftUI

@available(macOS 26.0, *)
struct LiquidGlassBackground: View {
    let cornerRadius: CGFloat
    let isActive: Bool
    let isDropTargeted: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(.clear)
                .glassEffect(in: RoundedRectangle(cornerRadius: cornerRadius))
            if isDropTargeted || isActive {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(NSColor.controlAccentColor).opacity(isDropTargeted ? 0.25 : 0.12))
            }
        }
    }
}

@available(macOS 26.0, *)
struct LiquidGlassOverlay: View {
    let cornerRadius: CGFloat
    let isActive: Bool
    let isDropTargeted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                isDropTargeted || isActive
                    ? Color(NSColor.controlAccentColor)
                    : Color(NSColor.separatorColor).opacity(0.3),
                lineWidth: isDropTargeted ? 3 : isActive ? 2.5 : 1
            )
    }
}

struct LegacyGlassBackground: View {
    let cornerRadius: CGFloat
    let isActive: Bool
    let isDropTargeted: Bool

    var body: some View {
        ZStack {
            VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
            if isDropTargeted || isActive {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color(NSColor.controlAccentColor).opacity(isDropTargeted ? 0.25 : 0.12))
            }
        }
    }
}

struct LegacyGlassOverlay: View {
    let cornerRadius: CGFloat
    let isActive: Bool
    let isDropTargeted: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(
                isDropTargeted || isActive
                    ? Color(NSColor.controlAccentColor)
                    : Color(NSColor.separatorColor).opacity(0.3),
                lineWidth: isDropTargeted ? 3 : isActive ? 2.5 : 1
            )
    }
}

struct WindowRowView: View {
    let window: AeroSpaceWindow

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 10) {
            Image(nsImage: window.appIcon).resizable().frame(width: 22, height: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(window.appName).font(.body).lineLimit(1)
                if !window.windowTitle.isEmpty {
                    Text(window.windowTitle).font(.footnote).foregroundColor(.secondary).lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(NSColor.separatorColor))
                .opacity(isHovered ? 0.3 : 0)
        )
        .onHover { isHovered = $0 }
        .draggable(window.id)
        .onTapGesture { focusWindow(windowId: window.id) }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

struct WorkspaceCardView: View {
    let key: String
    let windows: [AeroSpaceWindow]
    let isLoading: Bool
    let isActive: Bool
    let onWindowsChanged: () -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(key.uppercased()).font(.system(.title3, design: .rounded)).fontWeight(.bold)
                Spacer()
                if !windows.isEmpty && !isLoading {
                    Text("\(windows.count)").font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color(NSColor.labelColor).opacity(0.08)).cornerRadius(6)
                }
            }

            Divider()

            // Content
            ZStack {
                // Persistent ScrollView so ForEach can animate insertions/removals smoothly
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(windows) { window in
                            WindowRowView(window: window)
                        }
                    }
                }

                // Empty state text overlaid independently
                if windows.isEmpty {
                    Text("No Windows")
                        .font(.subheadline)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(isLoading ? nil : .default, value: windows.count)
        }
        .padding(16)
        .frame(width: 240, height: 170, alignment: .topLeading)
        .background(
            Group {
                if #available(macOS 26.0, *) {
                    LiquidGlassBackground(
                        cornerRadius: 16,
                        isActive: isActive,
                        isDropTargeted: isDropTargeted
                    )
                } else {
                    LegacyGlassBackground(
                        cornerRadius: 16,
                        isActive: isActive,
                        isDropTargeted: isDropTargeted
                    )
                }
            }
        )
        .overlay(
            Group {
                if #available(macOS 26.0, *) {
                    LiquidGlassOverlay(
                        cornerRadius: 16,
                        isActive: isActive,
                        isDropTargeted: isDropTargeted
                    )
                } else {
                    LegacyGlassOverlay(
                        cornerRadius: 16,
                        isActive: isActive,
                        isDropTargeted: isDropTargeted
                    )
                }
            }
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture { switchToWorkspace(key) }
        .dropDestination(for: String.self) { items, _ in
            if let windowId = items.first {
                moveWindowToWorkspace(windowId: windowId, workspace: key, completion: onWindowsChanged)
            }
            return true
        } isTargeted: { isDropTargeted = $0 }
    }
}

struct GridHUDView: View {
    let gridKeys: [[String]]

    @State private var workspaceData: [String: [AeroSpaceWindow]] = [:]
    @State private var isLoading = true
    @State private var activeWorkspace: String? = nil
    @State private var bgOpacity: Double = 0.0

    init(matrix: [[String]]) {
        self.gridKeys = matrix
    }

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 4) {
                Text("Click a desktop or press its key to jump. ⎋ to cancel.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)

            ForEach(gridKeys, id: \.self) { row in
                HStack(spacing: 20) {
                    ForEach(row, id: \.self) { key in
                        WorkspaceCardView(
                            key: key,
                            windows: workspaceData[key] ?? [],
                            isLoading: isLoading,
                            isActive: key == activeWorkspace,
                            onWindowsChanged: {
                                fetchAeroSpaceWindows { windows in
                                    self.workspaceData = Dictionary(grouping: windows, by: { $0.workspace })
                                }
                            }
                        )
                    }
                }
            }
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(bgOpacity))
        .onTapGesture {
            NSApp.terminate(nil)
        }
        .onAppear {
            withAnimation(.linear(duration: 0.12)) {
                self.bgOpacity = 0.25
            }

            fetchActiveWorkspace { workspace in
                self.activeWorkspace = workspace
            }

            fetchAeroSpaceWindows { windows in
                // Populate data immediately
                self.workspaceData = Dictionary(grouping: windows, by: { $0.workspace })
                
                // Allow the view to render the initial state, then enable animations
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
