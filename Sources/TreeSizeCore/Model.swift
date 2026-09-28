// Модель дерева: сборка из вывода serialize()
import Foundation

public enum NodeKind {
    case dir, file, rest
}

public final class Node: Identifiable {
    public let id: Int
    public let kind: NodeKind
    public var name: String
    public var size: Int64
    public var alloc: Int64
    public var cloud: Int64
    public var files: Int64
    public var dirs: Int64
    public let mtime: Int64
    public var ign: Int64
    public var selfIgnored: Bool
    public var scanning: Bool = false   // папка в процессе сканирования (живое дерево)
    public var skipped: Bool = false   // пропущена из-за отсутствия полного доступа к диску
    public weak var parent: Node?
    public var children: [Node]?
    /// Полный путь, кэшируется при assignPaths() после построения дерева
    public private(set) var path: String = ""

    private static var nextId = 0

    private init(id: Int, kind: NodeKind, name: String, size: Int64, alloc: Int64, cloud: Int64,
                 files: Int64, dirs: Int64, mtime: Int64, ign: Int64, selfIgnored: Bool,
                 parent: Node?, children: [Node]?, skipped: Bool = false) {
        self.id = id
        self.kind = kind
        self.name = name
        self.size = size
        self.alloc = alloc
        self.cloud = cloud
        self.files = files
        self.dirs = dirs
        self.mtime = mtime
        self.ign = ign
        self.selfIgnored = selfIgnored
        self.parent = parent
        self.children = children
        self.skipped = skipped
    }

    @discardableResult
    public static func build(from arr: [Any], parent: Node? = nil) -> Node {
        let id = nextId; nextId += 1
        let kindVal = arr[0] as? Int ?? 0
        let nameRaw = arr[1] as? String ?? ""
        let size = (arr[2] as? NSNumber)?.int64Value ?? 0
        let alloc = (arr[3] as? NSNumber)?.int64Value ?? 0
        let cloud = (arr[4] as? NSNumber)?.int64Value ?? 0
        let files = (arr[5] as? NSNumber)?.int64Value ?? 0
        let dirs = (arr[6] as? NSNumber)?.int64Value ?? 0
        let mtime = (arr[7] as? NSNumber)?.int64Value ?? 0

        let kind: NodeKind
        var kidsArr: [Any]? = nil
        var ign: Int64 = 0
        var selfIgnored = false
        var nodeSkipped = false
        var dirScanning = false

        switch kindVal {
        case 0:
            kind = .dir
            kidsArr = nil
            if arr.count > 8 {
                // serialize() всегда кладёт ign на 8-ю позицию
                if let rawIgn = (arr[8] as? NSNumber)?.int64Value {
                    if rawIgn == -1 {
                        selfIgnored = true
                        ign = size
                    } else if rawIgn == -2 {
                        nodeSkipped = true
                        ign = 0
                    } else {
                        selfIgnored = false
                        ign = rawIgn
                    }
                    if arr.count > 9 {
                        // Флаг scanning (Bool) на 9-й позиции, если true
                        if arr[9] is Bool {
                            dirScanning = arr[9] as! Bool
                            if arr.count > 10 { kidsArr = arr[10] as? [Any] }
                        } else {
                            kidsArr = arr[9] as? [Any]
                        }
                    }
                } else if let kids = arr[8] as? [Any] {
                    // формат без ign (JS-совместимость)
                    kidsArr = kids
                }
            }
        case 1:
            kind = .file
            if arr.count > 8 {
                let rawIgn = (arr[8] as? NSNumber)?.int64Value ?? 0
                selfIgnored = rawIgn == -1
                nodeSkipped = rawIgn == -2
                ign = selfIgnored ? size : (nodeSkipped ? 0 : rawIgn)
            }
            kidsArr = nil
        case 2:
            kind = .rest
            if arr.count > 8 {
                let rawIgn = (arr[8] as? NSNumber)?.int64Value ?? 0
                selfIgnored = rawIgn == -1
                nodeSkipped = rawIgn == -2
                ign = selfIgnored ? size : (nodeSkipped ? 0 : rawIgn)
            }
            kidsArr = nil
        default:
            kind = .rest
            kidsArr = nil
        }

        let node = Node(id: id, kind: kind, name: nameRaw, size: size, alloc: alloc,
                        cloud: cloud, files: files, dirs: dirs, mtime: mtime,
                        ign: ign, selfIgnored: selfIgnored, parent: parent, children: nil,
                        skipped: nodeSkipped)
        node.scanning = dirScanning

        if let ka = kidsArr {
            node.children = ka.map { Node.build(from: $0 as! [Any], parent: node) }
        }

        return node
    }

    public static func resetIds() {
        nextId = 0
    }

    /// Заполнить path у всего дерева рекурсивно (вызывается после build).
    /// Разделитель не удваивается, если parentPath уже оканчивается на "/" (корень "/").
    public func assignPaths(parentPath: String = "") {
        let n = kind == .rest ? "\u{2026}" : name
        if parentPath.isEmpty {
            path = n
        } else {
            let sep = parentPath.hasSuffix("/") ? "" : "/"
            path = parentPath + sep + n
        }
        if let kids = children {
            for child in kids {
                child.assignPaths(parentPath: path)
            }
        }
    }

    /// Найти потомка по пути — спуск по префиксу, без полного обхода.
    /// На каждом уровне идёт только в того ребёнка, чей путь совпадает с target
    /// или является префиксом target (target.hasPrefix(child.path + "/")).
    /// Если такого нет — nil (узел свёрнут в сводку или не существует).
    public func findDescendant(by target: String) -> Node? {
        if path == target { return self }
        guard let children = children else { return nil }
        for child in children {
            if child.path == target { return child }
            if target.hasPrefix(child.path + "/") {
                return child.findDescendant(by: target)
            }
        }
        return nil
    }

    /// Имя для отображения: у сводки — «[N файлов и M папок помельче]», у остальных — name
    public var displayName: String {
        if kind == .rest {
            var parts: [String] = []
            if files > 0 { parts.append(plural(files, tr("файл"), tr("файла"), tr("файлов"))) }
            if dirs > 0 { parts.append(plural(dirs, tr("папка"), tr("папки"), tr("папок"))) }
            return "[" + parts.joined(separator: tr(" и ")) + tr(" помельче") + "]"
        }
        return name
    }
}

// MARK: - Суб-структуры ScanResult

public struct TopFile {
    public let size: Int64
    public let path: String
    public let alloc: Int64
    public let cloud: Int64
    public let mtime: Int64
}

public struct ExtStat {
    public let ext: String
    public let size: Int64
    public let count: Int64
    public let cloud: Int64
}

public struct AgeBucket {
    public let label: String
    public let size: Int64
    public let count: Int64
}

public struct DupGroup {
    public let size: Int64
    public let paths: [String]

    public init(size: Int64, paths: [String]) {
        self.size = size
        self.paths = paths
    }
}

public struct ScanResult {
    public let root: String
    public let scanned: String
    public let took: Double
    public let errors: Int64
    public var stuck: [String]
    public let tree: Node
    public var top: [TopFile]
    public let ext: [ExtStat]
    public let age: [AgeBucket]
    public var dups: [DupGroup]
    public let dupMin: Int64

    public init(data: [String: Any]) {
        root = data["root"] as? String ?? ""
        scanned = data["scanned"] as? String ?? ""
        took = data["took"] as? Double ?? 0
        errors = (data["errors"] as? NSNumber)?.int64Value ?? 0
        stuck = data["stuck"] as? [String] ?? []

        Node.resetIds()
        let built = Node.build(from: data["tree"] as! [Any])
        built.name = root
        built.assignPaths()
        tree = built

        let topRaw = data["top"] as? [[Any]] ?? []
        var topList: [TopFile] = []
        for t in topRaw where t.count >= 5 {
            topList.append(TopFile(
                size: (t[0] as? NSNumber)?.int64Value ?? 0,
                path: t[1] as? String ?? "",
                alloc: (t[2] as? NSNumber)?.int64Value ?? 0,
                cloud: (t[3] as? NSNumber)?.int64Value ?? 0,
                mtime: (t[4] as? NSNumber)?.int64Value ?? 0
            ))
        }
        top = topList

        let extRaw = data["ext"] as? [[Any]] ?? []
        var extList: [ExtStat] = []
        for e in extRaw where e.count >= 4 {
            extList.append(ExtStat(
                ext: e[0] as? String ?? "",
                size: (e[1] as? NSNumber)?.int64Value ?? 0,
                count: (e[2] as? NSNumber)?.int64Value ?? 0,
                cloud: (e[3] as? NSNumber)?.int64Value ?? 0
            ))
        }
        ext = extList

        let ageRaw = data["age"] as? [[Any]] ?? []
        var ageList: [AgeBucket] = []
        for a in ageRaw where a.count >= 3 {
            ageList.append(AgeBucket(
                label: a[0] as? String ?? "",
                size: (a[1] as? NSNumber)?.int64Value ?? 0,
                count: (a[2] as? NSNumber)?.int64Value ?? 0
            ))
        }
        age = ageList

        let dupRaw = data["dups"] as? [[Any]] ?? []
        var dupList: [DupGroup] = []
        for d in dupRaw where d.count >= 2 {
            dupList.append(DupGroup(
                size: (d[0] as? NSNumber)?.int64Value ?? 0,
                paths: d[1] as? [String] ?? []
            ))
        }
        dups = dupList

        dupMin = (data["dupMin"] as? NSNumber)?.int64Value ?? 0
    }

    /// Конструктор для живого дерева (снимок во время скана): только дерево, остальные списки пустые.
    /// - Parameter treeArr: сериализованное дерево (массив из serialize).
    /// - Parameter rootPath: полный путь корня.
    /// - Parameter scanned: дата/время снимка.
    public init(liveTree treeArr: [Any], rootPath: String, scanned: String) {
        self.root = rootPath
        self.scanned = scanned
        self.took = 0
        self.errors = 0
        self.stuck = []
        self.top = []
        self.ext = []
        self.age = []
        self.dups = []
        self.dupMin = 0

        Node.resetIds()
        let built = Node.build(from: treeArr)
        built.name = root
        built.assignPaths()
        tree = built
    }
}
