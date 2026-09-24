// Список дисков и типовых папок — как places() в эталоне treesize.py
import Foundation

/// Место (диск или папка) для панели «Открыть»
public struct Place {
    public let kind: String   // "disk" или "folder"
    public let name: String
    public let path: String
    public let total: Int64?
    public let free: Int64?
}

/// Диски и типовые папки
public func listPlaces() -> [Place] {
    let home = NSHomeDirectory()
    var result: [Place] = []

    func addDisk(name: String, path: String) {
        let url = URL(fileURLWithPath: path)
        guard let values = try? url.resourceValues(forKeys: [.volumeTotalCapacityKey, .volumeAvailableCapacityKey]),
              let total = values.volumeTotalCapacity,
              let free = values.volumeAvailableCapacity
        else { return }
        result.append(Place(kind: "disk", name: name, path: path,
                            total: Int64(total), free: Int64(free)))
    }

    // Macintosh HD — том с данными
    addDisk(name: "Macintosh HD", path: "/System/Volumes/Data")

    // Тома в /Volumes
    if let volumes = try? FileManager.default.contentsOfDirectory(atPath: "/Volumes") {
        for v in volumes.sorted() {
            let p = "/Volumes/\(v)"
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: p, isDirectory: &isDir), isDir.boolValue else { continue }
            // ismount — проверяем, что это точка монтирования и не корень
            guard let dest = try? FileManager.default.destinationOfSymbolicLink(atPath: p),
                  URL(fileURLWithPath: dest).standardized.path != "/"
            else {
                // Не симлинк — всё равно добавляем, если смонтировано
                addDisk(name: v, path: p)
                continue
            }
            _ = dest  // симлинк на корень — пропускаем
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
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: p, isDirectory: &isDir), isDir.boolValue {
                result.append(Place(kind: "folder", name: item, path: p, total: nil, free: nil))
            }
        }
    }

    return result
}
