import AppKit
import Foundation

func fetchAeroSpaceWindows(completion: @escaping ([AeroSpaceWindow]) -> Void) {
    DispatchQueue.global(qos: .userInteractive).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
        process.arguments = ["list-windows", "--all", "--format", "%{window-id}###%{app-name}###%{window-title}###%{workspace}"]

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
                let components = line.components(separatedBy: "###")
                if components.count >= 4 {
                    let id = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let appName = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let windowTitle = components[2].trimmingCharacters(in: .whitespacesAndNewlines)
                    let workspace = components[3].trimmingCharacters(in: .whitespacesAndNewlines)

                    if !id.isEmpty {
                        var iconImage = workspaceShared.icon(forFile: "/System/Library/CoreServices/Finder.app")

                        if let runningApp = workspaceShared.runningApplications.first(where: { $0.localizedName?.lowercased() == appName.lowercased() }) {
                            if let appIcon = runningApp.icon {
                                iconImage = appIcon
                            }
                        } else {
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

func fetchActiveWorkspace(completion: @escaping (String?) -> Void) {
    DispatchQueue.global(qos: .userInteractive).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
        process.arguments = ["list-workspaces", "--focused"]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe

        do {
            try process.run()
            process.waitUntilExit()

            let data = outputPipe.fileHandleForReading.readDataToEndOfFile()
            guard let workspace = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines), !workspace.isEmpty else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            DispatchQueue.main.async { completion(workspace) }
        } catch {
            DispatchQueue.main.async { completion(nil) }
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

func focusWindow(windowId: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
    process.arguments = ["focus", "--window-id", windowId]
    try? process.run()
    process.waitUntilExit()
    NSApp.terminate(nil)
}

func moveWindowToWorkspace(windowId: String, workspace: String, completion: @escaping () -> Void) {
    DispatchQueue.global(qos: .userInteractive).async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/aerospace")
        process.arguments = ["move-node-to-workspace", "--window-id", windowId, workspace]
        try? process.run()
        process.waitUntilExit()
        DispatchQueue.main.async(execute: completion)
    }
}
