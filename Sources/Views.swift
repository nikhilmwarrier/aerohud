import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WorkspaceCardView: View {
    let key: String
    let windows: [AeroSpaceWindow]
    let isLoading: Bool
    let isActive: Bool
    let onWindowsChanged: () -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(key.uppercased())
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                if !windows.isEmpty && !isLoading {
                    Text("\(windows.count)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(NSColor.labelColor).opacity(0.08))
                        .cornerRadius(6)
                }
            }

            Divider()

            if isLoading {
                Spacer()
            } else if windows.isEmpty {
                Spacer()
                HStack {
                    Spacer()
                    Text("No Windows")
                        .font(.subheadline)
                        .foregroundColor(Color(NSColor.tertiaryLabelColor))
                    Spacer()
                }
                Spacer()
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(windows) { window in
                            HStack(spacing: 10) {
                                Image(nsImage: window.appIcon)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 22, height: 22)

                                VStack(alignment: .leading, spacing: 1) {
                                    Text(window.appName)
                                        .font(.system(.body, design: .default))
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                        .lineLimit(1)

                                    if !window.windowTitle.isEmpty {
                                        Text(window.windowTitle)
                                            .font(.footnote)
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                }
                            }
                            .onDrag {
                                NSItemProvider(object: window.id as NSString)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .frame(width: 240, height: 170, alignment: .topLeading)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .withinWindow)
                if isDropTargeted || isActive {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.controlAccentColor).opacity(isDropTargeted ? 0.25 : 0.12))
                }
            }
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDropTargeted || isActive
                    ? Color(NSColor.controlAccentColor)
                    : Color(NSColor.separatorColor).opacity(0.3),
                        lineWidth: isDropTargeted ? 3 : isActive ? 2.5 : 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            switchToWorkspace(key)
        }
        .onDrop(of: [.plainText], isTargeted: $isDropTargeted) { providers in
            guard let provider = providers.first else { return false }
            provider.loadObject(ofClass: NSString.self) { item, _ in
                if let windowId = item as? String {
                    DispatchQueue.main.async {
                        moveWindowToWorkspace(windowId: windowId, workspace: key) {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onWindowsChanged()
                            }

                        }
                    }
                }
            }
            return true
        }
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
                self.workspaceData = Dictionary(grouping: windows, by: { $0.workspace })
                self.isLoading = false
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
