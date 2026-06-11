import SwiftUI
import AppKit
import Foundation

struct AeroSpaceWindow: Identifiable {
    let id: String
    let appName: String
    let windowTitle: String
    let workspace: String
    let appIcon: NSImage
}

// Executes any general AeroSpace command safely in the background
func runAeroSpace(arguments: [String]) -> String {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = arguments
    
    let outputPipe = Pipe()
    process.standardOutput = outputPipe
    
    do {
        try process.run()
        process.waitUntilExit()
        let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: data, encoding: .utf8) ?? ""
    } catch {
        print("Error executing AeroSpace command \(arguments): \(error)")
        return ""
    }
}

func fetchAeroSpaceWindows() -> [AeroSpaceWindow] {
    let outputString = runAeroSpace(arguments: ["list-windows", "--all", "--format", "%{window-id}|%{app-name}|%{window-title}|%{workspace}"])
    if outputString.isEmpty { return [] }
    
    var parsedWindows: [AeroSpaceWindow] = []
    let lines = outputString.components(separatedBy: .newlines)
    let workspaceShared = NSWorkspace.shared
    
    for line in lines {
        let components = line.components(separatedBy: "|")
        if components.count >= 4 {
            let id = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let appName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let windowTitle = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
            let workspace = components[3].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !id.isEmpty {
                var iconImage = workspaceShared.icon(forFile: "/System/Library/CoreServices/Finder.app")
                
                let standardPath = "/Applications/\(appName).app"
                let systemPath = "/System/Applications/\(appName).app"
                let userPath = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Applications/\(appName).app"
                
                if FileManager.default.fileExists(atPath: standardPath) {
                    iconImage = workspaceShared.icon(forFile: standardPath)
                } else if FileManager.default.fileExists(atPath: systemPath) {
                    iconImage = workspaceShared.icon(forFile: systemPath)
                } else if FileManager.default.fileExists(atPath: userPath) {
                    iconImage = workspaceShared.icon(forFile: userPath)
                }
                
                parsedWindows.append(AeroSpaceWindow(
                    id: id,
                    appName: appName,
                    windowTitle: windowTitle,
                    workspace: workspace,
                    appIcon: iconImage
                ))
            }
        }
    }
    return parsedWindows
}

// Helper to switch workspaces and kill the app cleanly
func switchToWorkspace(_ workspace: String) {
    _ = runAeroSpace(arguments: ["workspace", workspace])
    NSApp.terminate(nil)
}

struct WorkspaceCardView: View {
    let key: String
    let windows: [AeroSpaceWindow]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(key.uppercased())
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                if !windows.isEmpty {
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
            
            if windows.isEmpty {
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
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .frame(width: 260, height: 180, alignment: .topLeading)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        // Click action: instantly switches to this workspace
        .onTapGesture {
            switchToWorkspace(key)
        }
    }
}


struct GridHUDView: View {
    let gridKeys = [
        ["1", "2", "3"],
        ["q", "w", "e"],
        ["a", "s", "d"]
    ]
    
    let workspaceData: [String: [AeroSpaceWindow]]
    
    init() {
        let windows = fetchAeroSpaceWindows()
        self.workspaceData = Dictionary(grouping: windows, by: { $0.workspace })
    }
    
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 4) {
                // Text("AeroSpace Grid Monitor")
                //     .font(.system(.title2, design: .default))
                //     .fontWeight(.bold)
                //     .foregroundColor(.primary)
                Text("Click a desktop or press its key to jump. ⎋ to cancel.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 50)
            
            ForEach(gridKeys, id: \.self) { row in
                HStack(spacing: 24) {
                    ForEach(row, id: \.self) { key in
                        WorkspaceCardView(key: key, windows: workspaceData[key] ?? [])
                    }
                }
            }
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Background tint layer intercepts clicks outside cards to exit
        .background(Color.black.opacity(0.25)) 
        .onTapGesture {
            NSApp.terminate(nil)
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


class HUDWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, 
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.hasShadow = false
        
        let contentView = NSHostingView(rootView: GridHUDView())
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    // Intercept hardware key triggers safely
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape Key
            NSApp.terminate(nil)
            return
        }
        
        // Read characters typed directly while the window is active
        if let chars = event.charactersIgnoringModifiers?.lowercased() {
            let validKeys = ["1", "2", "3", "q", "w", "e", "a", "s", "d"]
            if validKeys.contains(chars) {
                switchToWorkspace(chars)
                return
            }
        }
        
        super.keyDown(with: event)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var window: HUDWindow?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = HUDWindow()
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) 
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
