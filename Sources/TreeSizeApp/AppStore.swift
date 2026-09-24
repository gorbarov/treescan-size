// Состояние приложения — UI-SPEC раздел 3
import TreeSizeCore

@MainActor
public final class AppStore: ObservableObject {
    @Published public var result: ScanResult? = nil
    @Published public var selected: Node? = nil
    @Published public var expanded: Set<Int> = []
    @Published public var mode: SizeMode = .size
    @Published public var tab: Tab = .details
    @Published public var isScanning: Bool = false
    @Published public var progress: (files: Int64, bytes: Int64, cur: String) = (0, 0, "")
    @Published public var scanPath: String = ""

    public enum SizeMode: String, Sendable {
        case size, alloc
    }

    public enum Tab: String, Sendable {
        case details, pie, ext, age, top, dups
    }

    public struct PieSlice {
        public let node: Node?
        public let title: String
        public let value: Int64
        public let colorIndex: Int?
    }

    public init() {}

    // MARK: - Режим

    public func value(_ n: Node) -> Int64 {
        mode == .size ? n.size : n.alloc
    }

    // MARK: - Дети

    public func children(_ n: Node) -> [Node] {
        guard let kids = n.children else { return [] }
        return kids
            .filter { !($0.kind == .rest && $0.files == 0 && $0.dirs == 0) }
            .sorted { value($0) > value($1) }
    }

    // MARK: - Плоский список

    public var visibleRows: [(node: Node, depth: Int)] {
        guard let root = result?.tree else { return [] }
        var rows: [(Node, Int)] = []
        addVisible(from: root, depth: 0, to: &rows)
        return rows
    }

    private func addVisible(from node: Node, depth: Int, to rows: inout [(Node, Int)]) {
        rows.append((node, depth))
        if expanded.contains(node.id) {
            for child in children(node) {
                addVisible(from: child, depth: depth + 1, to: &rows)
            }
        }
    }

    // MARK: - Выделение

    public func select(_ n: Node) {
        selected = n
        var p: Node? = n.parent
        while let ancestor = p {
            expanded.insert(ancestor.id)
            p = ancestor.parent
        }
    }

    public func toggle(_ n: Node) {
        if expanded.contains(n.id) {
            expanded.remove(n.id)
        } else {
            expanded.insert(n.id)
        }
    }

    // MARK: - Папка правой панели

    public var viewDir: Node? {
        guard let sel = selected else { return nil }
        return sel.kind == .file ? sel.parent : sel
    }

    // MARK: - Диаграмма

    public func pieSlices(for dir: Node) -> [PieSlice] {
        let kids = children(dir)
        let total = kids.reduce(0) { $0 + value($1) }
        guard total > 0 else { return [] }

        let threshold = Int64(Double(total) * 0.01) // 1 %
        var slices: [PieSlice] = []
        var otherValue: Int64 = 0

        for kid in kids {
            let v = value(kid)
            if v >= threshold && kid.kind != .rest && slices.count < 8 {
                slices.append(PieSlice(node: kid, title: kid.name, value: v, colorIndex: slices.count))
            } else {
                otherValue += v
            }
        }

        if otherValue > 0 {
            slices.append(PieSlice(node: nil, title: "Прочее", value: otherValue, colorIndex: nil))
        }

        return slices
    }

    // MARK: - Топ файлов

    public func topFiles(in dir: Node) -> [TopFile] {
        guard let top = result?.top else { return [] }
        guard dir.parent != nil else { return top }
        let prefix = dir.path + "/"
        return top.filter { $0.path.hasPrefix(prefix) }
    }

    // MARK: - Дубли

    public func dupGroups(in dir: Node) -> [DupGroup] {
        guard let dups = result?.dups else { return [] }
        guard dir.parent != nil else { return dups }
        let prefix = dir.path + "/"
        return dups.filter { group in
            group.paths.contains { $0.hasPrefix(prefix) }
        }
    }

    // MARK: - Корзина (шаг 2, без FileManager)

    public func removeLocal(_ node: Node) -> () -> Void {
        let nodePath = node.path

        let savedParent = node.parent
        let savedChildrenIndex = savedParent?.children?.firstIndex(where: { $0.id == node.id })
        let savedSize = node.size
        let savedAlloc = node.alloc
        let savedCloud = node.cloud
        let savedFiles = node.files
        let savedDirs = node.dirs
        let savedIgn = node.ign

        // Запоминаем top-записи, которые удаляем
        var removedTop: [(index: Int, entry: TopFile)] = []
        if let top = result?.top {
            for (i, t) in top.enumerated() where t.path == nodePath {
                removedTop.append((i, t))
            }
        }
        for (i, _) in removedTop.sorted(by: { $0.index > $1.index }) {
            result?.top.remove(at: i)
        }

        // Запоминаем dup-группы, которые удаляем
        var removedDups: [(index: Int, group: DupGroup)] = []
        if let dups = result?.dups {
            for (i, g) in dups.enumerated() {
                if g.paths.contains(where: { $0 == nodePath || $0.hasPrefix(nodePath + "/") }) {
                    removedDups.append((i, g))
                }
            }
        }
        for (i, _) in removedDups.sorted(by: { $0.index > $1.index }) {
            result?.dups.remove(at: i)
        }

        // Вычитаем из предков
        var p: Node? = savedParent
        while let ancestor = p {
            ancestor.size -= savedSize
            ancestor.alloc -= savedAlloc
            ancestor.cloud -= savedCloud
            ancestor.files -= savedFiles
            ancestor.dirs -= savedDirs
            ancestor.ign -= savedIgn
            p = ancestor.parent
        }

        // Убираем из детей родителя
        if let parent = savedParent, let idx = savedChildrenIndex {
            parent.children?.remove(at: idx)
        }

        // Если выделение было внутри удалённого — выделяем родителя
        let savedSelected = selected
        if let sel = selected {
            var cur: Node? = sel
            var inside = false
            while let n = cur {
                if n.id == node.id { inside = true; break }
                cur = n.parent
            }
            if inside {
                selected = savedParent
            }
        }

        // Замыкание отката
        return {
            // Восстанавливаем предков
            var p: Node? = savedParent
            while let ancestor = p {
                ancestor.size += savedSize
                ancestor.alloc += savedAlloc
                ancestor.cloud += savedCloud
                ancestor.files += savedFiles
                ancestor.dirs += savedDirs
                ancestor.ign += savedIgn
                p = ancestor.parent
            }

            // Восстанавливаем в детях родителя
            if let parent = savedParent, let idx = savedChildrenIndex {
                if parent.children == nil { parent.children = [] }
                parent.children!.insert(node, at: idx)
            }

            // Восстанавливаем top
            for (_, entry) in removedTop {
                self.result?.top.append(entry)
            }
            // Восстанавливаем dups
            for (_, group) in removedDups {
                self.result?.dups.append(group)
            }

            // Восстанавливаем выделение
            self.selected = savedSelected
        }
    }
}