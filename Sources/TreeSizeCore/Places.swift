// Список дисков и типовых папок — как places() в эталоне treesize.py
import Foundation
import Darwin

/// Место (диск или папка) для панели «Открыть»
public struct Place {
    public let kind: String   // "disk" или "folder"
    public let name: String
    public let path: String
    public let total: Int64?
    public let free: Int64?
}

/// Нормализация пути через Darwin.realpath (не resolvingSymlinksInPath)
private func realPath(_ path: String) -> String? {
    let nsPath = path as NSString
    guard let fsPath = nsPath.utf8String else { return nil }
    guard let r = Darwin.realpath(UnsafePointer<Int8>(fsPath), nil) else { return nil }
    let s = String(cString: r)
    free(r)
    return s
}

/// Диски и типовые папки
public func listPlaces() -> [Place] {
    let home = NSHomeDirectory()
    var result: [Place] = []
    // Уникальные пути — используем Set, чтобы не допустить дубликатов
    var seenPaths = Set<String>()

    func addDisk(name: String, path: String) {
        // Если realpath ведёт на / или /System/Volumes/Data — пропускаем
        if let rp = realPath(path), rp == "/" || rp == "/System/Volumes/Data" { return }
        guard !seenPaths.contains(path) else { return }
        seenPaths.insert(path)
        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacity
        else { return }
        result.append(Place(kind: "disk", name: name, path: path,
                            total: Int64(total), free: Int64(free)))
    }

    // Macintosh HD — том с данными
    if !seenPaths.contains("/System/Volumes/Data") {
        seenPaths.insert("/System/Volumes/Data")
        let url = URL(fileURLWithPath: "/System/Volumes/Data")
        if let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
           let total = values.volumeTotalCapacity,
           let free = values.volumeAvailableCapacity {
            result.append(Place(kind: "disk", name: "Macintosh HD", path: "/System/Volumes/Data",
                                total: Int64(total), free: Int64(free)))
        }
    }

    // Тома в /Volumes
    if let volumes = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") {
        for v in volumes.sorted() {
            let p = "/Volumes/\(v)"
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: p, isDirectory: &isDir), isDir.boolValue else { continue }
            // Если realpath ведёт на / или /System/Volumes/Data — пропускаем
            if let rp = realPath(p), rp == "/" || rp == "/System/Volumes/Data" { continue }
            addDisk(name: v, path: p)
        }
    }

    // Типовые папки
    let folders: [(String, String)] = [
        ("Домашняя папка", home),
        ("Загрузки", home + "/Downloads"),
        ("Документы", home + "/Documents"),
        ("Рабочий стол", home + "/Desktop"),
        ("iCloud Drive", home + "/Library/Mobile Documents/com~apple~CloudDocs"),
    ]

    for (name, path) in folders {
        guard !seenPaths.contains(path) else { continue }
        seenPaths.insert(path)
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: path, isDirectory: &isDir), isDir.boolValue {
            result.append(Place(kind: "folder", name: name, path: path, total: nil, free: nil))
        }
    }

    // CloudStorage папки
    let cs = home + "/Library/CloudStorage"
    if let items = try? FileManager.default.contentsOfDirectory(atPath: cs) {
        for item in items.sorted() {
            let p = cs + "/" + item
            guard !seenPaths.contains(p) else { continue }
            seenPaths.insert(p)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: p, isDirectory: &isDir), isDir.boolValue {
                result.append(Place(kind: "folder", name: item, path: p, total: nil, free: nil))
            }
        }
    }

    return result
}