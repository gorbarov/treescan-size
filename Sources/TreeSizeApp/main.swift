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

if args.contains("--snapshot") {
    NSApplication.shared.setActivationPolicy(.accessory)
    Task { @MainActor in
        if args.contains("--places") {
            snapshotPlaces(args: args)
        } else if args.contains("--access") {
            snapshotAccess(args: args)
        } else if args.contains("--mode-help") {
            snapshotModeHelp(args: args)
        } else if args.contains("--scanning") {
            takeSnapshotScanning(args: args)
        } else if args.contains("--live-demo") {
            takeSnapshotLiveDemo(args: args)
        } else {
            takeSnapshot(args: args)
        }
    }
    RunLoop.current.run()
} else if args.contains("--uitest") {
    guard let rootIdx = args.firstIndex(of: "--root"), rootIdx + 1 < args.count else {
        fputs("--root <папка> обязателен\n", stderr)
        exit(1)
    }
    let root = args[rootIdx + 1]
    NSApplication.shared.setActivationPolicy(.regular)
    Task { @MainActor in
        let f = runUITest(root: root)
        let jsonData = try! JSONSerialization.data(withJSONObject: f, options: [.sortedKeys])
        fputs(String(data: jsonData, encoding: .utf8)! + "\n", stdout)
        exit(0)
    }
    RunLoop.current.run()
} else {
    // Нормальный запуск GUI
    NSApplication.shared.setActivationPolicy(.regular)
    TreeSizeUIApp.main()
}
