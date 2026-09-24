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

    /// Убрать узел из модели — как removeLocal() в эталоне template.html.
    /// Вычитает из предков, чистит top/dups, перевыбор.
    /// Возвращает замыкание отката. Сам файл не трогает.
    public func removeLocal(_ node: Node) -> () -> Void {
        let nodePath = node.path
        let pre = nodePath + "/"

        // Сохраняем состояние для отката (как saved = {top, dups, SEL, MSEL} в эталоне)
        let savedTop = result?.top ?? []
        let savedDups = result?.dups ?? []
        let savedSelected = selected

        // trashDelta: как в эталоне — {s, a, c, f, d, eff}
        // d: у папки node.dirs + 1 (сама папка), у файла node.dirs
        let deltaDirs = node.dirs + (node.kind == .dir ? 1 : 0)
        // effIgn: как effIgn() в эталоне — если есть предок с selfIgnored, то size, иначе ign
        var hasIgnoredAncestor = false
        var a: Node? = node.parent
        while let anc = a {
            if anc.selfIgnored { hasIgnoredAncestor = true; break }
            a = anc.parent
        }
        let effIgn = hasIgnoredAncestor ? node.size : node.ign

        // Top: убираем записи с путём узла или внутри него (как D.top.filter в эталоне)
        result?.top = savedTop.filter { $0.path != nodePath && !$0.path.hasPrefix(pre) }

        // Dups: из каждой группы убираем пути узла/внутри; группа остаётся, если >= 2 путей
        result?.dups = savedDups.compactMap { group in
            let kept = group.paths.filter { $0 != nodePath && !$0.hasPrefix(pre) }
            guard kept.count > 1 else { return nil }
            return DupGroup(size: group.size, paths: kept)
        }

        // Убираем из детей родителя
        let savedParent = node.parent
        let savedChildrenIndex = savedParent?.children?.firstIndex(where: { $0.id == node.id })
        if let parent = savedParent, let idx = savedChildrenIndex {
            parent.children?.remove(at: idx)
        }

        // shiftUp: вычитаем из предков (как shiftUp(node.p, dl, 1) в эталоне)
        var p: Node? = savedParent
        while let ancestor = p {
            ancestor.size -= node.size
            ancestor.alloc -= node.alloc
            ancestor.cloud -= node.cloud
            ancestor.files -= node.files
            ancestor.dirs -= deltaDirs
            // a.x = a.si ? a.s : a.x - sign*eff  (как shiftUp в эталоне)
            if ancestor.selfIgnored {
                ancestor.ign = ancestor.size
            } else {
                ancestor.ign -= effIgn
            }
            p = ancestor.parent
        }

        // Если выделение было внутри удалённого — выделяем родителя
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

        // Замыкание отката (как в эталоне: восстанавливает saved целиком)
        return {
            // shiftUp обратно: shiftUp(start, dl, -1)
            var p: Node? = savedParent
            while let ancestor = p {
                ancestor.size += node.size
                ancestor.alloc += node.alloc
                ancestor.cloud += node.cloud
                ancestor.files += node.files
                ancestor.dirs += deltaDirs
                if ancestor.selfIgnored {
                    ancestor.ign = ancestor.size
                } else {
                    ancestor.ign += effIgn
                }
                p = ancestor.parent
            }

            // Восстанавливаем в детях родителя
            if let parent = savedParent, let idx = savedChildrenIndex {
                if parent.children == nil { parent.children = [] }
                parent.children!.insert(node, at: idx)
            }

            // Восстанавливаем top и dups целиком (сохраняя порядок)
            self.result?.top = savedTop
            self.result?.dups = savedDups
            self.selected = savedSelected
        }
    }
}