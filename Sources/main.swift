import AppKit
import SwiftUI

func parseCommandLineArgs() -> (matrix: [[String]], columns: Int) {
    let args = CommandLine.arguments

    let version = "1.1.0"

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
        self.level = .popUpMenu
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

let lockFilePath = NSTemporaryDirectory() + "com.nik.AeroSpaceGridHUD.lock"

if let existingPidString = try? String(contentsOfFile: lockFilePath),
   let existingPid = Int32(existingPidString.trimmingCharacters(in: .whitespacesAndNewlines)) {
    if kill(existingPid, 0) == 0 {
        kill(existingPid, SIGKILL)
    }
}

let currentPid = ProcessInfo.processInfo.processIdentifier
try? String(currentPid).write(toFile: lockFilePath, atomically: true, encoding: .utf8)

let configuration = parseCommandLineArgs()
let app = NSApplication.shared
let delegate = AppDelegate(matrix: configuration.matrix)
app.delegate = delegate
app.run()
