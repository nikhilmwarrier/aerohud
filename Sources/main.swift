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

func parseCommandLineArgs() -> (matrix: [[String]], columns: Int) {
    let args = CommandLine.arguments

    let version = "1.0.0"
    
    let usage = """
    Usage: aerohud <COLS> <workspaces...>
           aerohud -h | --help
           aerohud -v | --version
    
    Example:
      aerohud 3 1 2 3 q w e a s d
      aerohud 4 1 2 3 4 q w e r
    """
    
    if args.contains("-h") || args.contains("--help") {
        print(usage)
        exit(0)
    }

    if args.contains("-v") || args.contains("--version") {
        print(version)
        exit(0)
    }
    
    guard args.count > 2 else {
        print("Error: Missing column count or workspace keys.\n")
        print(usage)
        exit(1)
    }
    
    guard let columns = Int(args[1]), columns > 0 else {
        print("Error: Column count must be a positive integer.\n")
        print(usage)
        exit(1)
    }
    
    let workspaces = Array(args[2...])
    var matrix: [[String]] = []
    var currentRow: [String] = []
    
    for item in workspaces {
        currentRow.append(item)
        if currentRow.count == columns {
            matrix.append(currentRow)
            currentRow = []
        }
    }
    if !currentRow.isEmpty {
        matrix.append(currentRow)
    }
    
    return (matrix, columns)
}

func fetchAeroSpaceWindows(completion: @escaping ([AeroSpaceWindow]) -> Void) {
    DispatchQueue.global(qos: .userInteractive).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
        process.arguments = ["list-windows", "--all", "--format", "%{window-id}|%{app-name}|%{window-title}|%{workspace}"]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let outputString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async { completion([]) }
                return
            }
            
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

                            // 1. Instant Memory Look-up: Match running application icon instantly by process name
                            if let runningApp = workspaceShared.runningApplications.first(where: { $0.localizedName?.lowercased() == appName.lowercased() }) {
                                if let appIcon = runningApp.icon {
                                    iconImage = appIcon
                                }
                            } else {
                                // 2. Fast Path Fallback: If app is hidden/minimized or name matches bundle folder exactly
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
            DispatchQueue.main.async { completion(parsedWindows) }
        } catch {
            DispatchQueue.main.async { completion([]) }
        }
    }
}

func switchToWorkspace(_ workspace: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = ["workspace", workspace]
    try? process.run()
    NSApp.terminate(nil)
}

struct WorkspaceCardView: View {
    let key: String
    let windows: [AeroSpaceWindow]
    let isLoading: Bool
    
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
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(16)
        .frame(width: 240, height: 170, alignment: .topLeading)
        .background(VisualEffectView(material: .hudWindow, blendingMode: .withinWindow))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 5)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(NSColor.separatorColor).opacity(0.3), lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            switchToWorkspace(key)
        }
    }
}

struct GridHUDView: View {
    let gridKeys: [[String]]
    
    @State private var workspaceData: [String: [AeroSpaceWindow]] = [:]
    @State private var isLoading = true
    
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
                        WorkspaceCardView(key: key, windows: workspaceData[key] ?? [], isLoading: isLoading)
                    }
                }
            }
            Spacer()
        }
        .padding(30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.25)) 
        .onTapGesture {
            NSApp.terminate(nil)
        }
        .onAppear {
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

class HUDWindow: NSPanel {
    let validKeys: [String]
    
    init(matrix: [[String]]) {
        self.validKeys = matrix.flatMap { $0 }
        
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
        
        let contentView = NSHostingView(rootView: GridHUDView(matrix: matrix))
        self.contentView = contentView
    }
    
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 {
            NSApp.terminate(nil)
            return
        }
        
        if let chars = event.charactersIgnoringModifiers?.lowercased() {
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
    let matrix: [[String]]
    
    init(matrix: [[String]]) {
        self.matrix = matrix
        super.init()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        window = HUDWindow(matrix: matrix)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true) 
    }
}

// If new instance spawned, kill old instance.

let lockFilePath = NSTemporaryDirectory() + "com.nik.AeroSpaceGridHUD.lock"

// Try to read and kill the existing instance if it exists
if let existingPidString = try? String(contentsOfFile: lockFilePath),
   let existingPid = Int32(existingPidString.trimmingCharacters(in: .whitespacesAndNewlines)) {
    // send signal 0 to check if process exists, then kill it
    if kill(existingPid, 0) == 0 {
        kill(existingPid, SIGKILL) 
    }
}

// Write the current process ID to the lock file
let currentPid = ProcessInfo.processInfo.processIdentifier
try? String(currentPid).write(toFile: lockFilePath, atomically: true, encoding: .utf8)

let configuration = parseCommandLineArgs()
let app = NSApplication.shared
let delegate = AppDelegate(matrix: configuration.matrix)
app.delegate = delegate
app.run()
