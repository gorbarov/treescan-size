import Foundation
import TreeSizeCore
import AppKit

let args = CommandLine.arguments

if args.contains("--selftest") {
    guard let rootIdx = args.firstIndex(of: "--root"), rootIdx + 1 < args.count else {
        fputs("--root <папка> обязателен\n", stderr)
        exit(1)
    }
    let root = args[rootIdx + 1]
    Task { @MainActor in
        let facts = runSelfTest(root: root)
        let jsonData = try! JSONSerialization.data(withJSONObject: facts, options: [.sortedKeys])
        fputs(String(data: jsonData, encoding: .utf8)! + "\n", stdout)
        exit(0)
    }
    RunLoop.current.run()
}

if args.contains("--uitest") {
    guard let rootIdx = args.firstIndex(of: "--root"), rootIdx + 1 < args.count else {
        fputs("--root <папка> обязателен\n", stderr)
        exit(1)
    }
    let root = args[rootIdx + 1]
    let snapPath: String? = {
        if let idx = args.firstIndex(of: "--snapshot"), idx + 1 < args.count {
            return args[idx + 1]
        }
        return nil
    }()
    NSApplication.shared.setActivationPolicy(.regular)
    Task { @MainActor in
        let f = runUITest(root: root, snapshotPath: snapPath)
        let jsonData = try! JSONSerialization.data(withJSONObject: f, options: [.sortedKeys])
        fputs(String(data: jsonData, encoding: .utf8)! + "\n", stdout)
        exit(0)
    }
    RunLoop.current.run()
}

if args.contains("--snapshot") {
    NSApplication.shared.setActivationPolicy(.accessory)
    Task { @MainActor in
        if args.contains("--places") {
            snapshotPlaces(args: args)
        } else if args.contains("--access") {
            if args.contains("--access-asked") {
                snapshotAccess2(args: args)
            } else {
                snapshotAccess(args: args)
            }
        } else if args.contains("--mode-help") {
            snapshotModeHelp(args: args)
        } else if args.contains("--scanning") {
            takeSnapshotScanning(args: args)
        } else if args.contains("--live-demo") {
            takeSnapshotLiveDemo(args: args)
        } else if args.contains("--welcome") {
            snapshotWelcome(args: args)
        } else {
            takeSnapshot(args: args)
        }
    }
    RunLoop.current.run()
} else {
    // Нормальный запуск GUI
    NSApplication.shared.setActivationPolicy(.regular)
    TreeSizeUIApp.main()
}
