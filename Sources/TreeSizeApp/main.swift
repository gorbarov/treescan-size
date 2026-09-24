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
        takeSnapshot(args: args)
    }
    RunLoop.current.run()
} else {
    // Нормальный запуск GUI
    NSApplication.shared.setActivationPolicy(.regular)
    TreeSizeUIApp.main()
}
