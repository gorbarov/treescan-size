// Контекстное меню узла — UI-SPEC раздел 9, как openMenu() в template.html
import SwiftUI
import TreeSizeCore

/// Меню для узла (дерево, детали, легенда) или пути (топ, дубли).
struct NodeMenu: View {
    let node: Node?
    let path: String
    let store: AppStore

    /// Для узла, найденного в дереве
    init(node: Node, store: AppStore) {
        self.node = node
        self.path = node.path
        self.store = store
    }

    /// Для пути (топ/дубли) — узел ищется через findDescendant
    init(path: String, store: AppStore) {
        self.path = path
        self.store = store
        if let root = store.result?.tree {
            self.node = {
                if path == root.path { return root }
                return root.findDescendant(by: path)
            }()
        } else {
            self.node = nil
        }
    }

    /// Инициализация из node или path — что передали, тем и работаем
    private init(node: Node?, path: String, store: AppStore) {
        self.node = node
        self.path = path
        self.store = store
    }

    private var isRest: Bool { if let n = node { n.kind == .rest } else { false } }
    private var isRoot: Bool { node?.parent == nil }
    private var isDropbox: Bool { store.result?.root.contains("/CloudStorage/Dropbox") ?? false }
    private var name: String { path.split(separator: "/").last.map(String.init) ?? path }

    private var ignoredAncestor: Node? {
        var p = node?.parent
        while let a = p {
            if a.selfIgnored { return a }
            p = a.parent
        }
        return nil
    }

    private var trashBlocked: Bool {
        guard let root = store.result?.root else { return true }
        return !canTrash(path: path, root: root)
    }

    var body: some View {
        if isRest {
            EmptyView()
        } else {
            Group {
                Text(name)
                    .fontWeight(.semibold)
                if let n = node {
                    let sz = store.value(n)
                    Text(n.kind == .dir
                         ? "\(fmtBytes(sz)) · \(plural(n.files, tr("файл"), tr("файла"), tr("файлов")))"
                         : fmtBytes(sz))
                        .foregroundColor(.secondary)
                } else {
                    Text(fmtBytes(topDupSize(for: path)))
                        .foregroundColor(.secondary)
                }

                Divider()

                Button(tr("Показать в Finder")) {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
                Button(tr("Скопировать путь")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(path, forType: .string)
                }

                if !isRoot {
                    Divider()

                    // Dropbox — не синхронизировать
                    if isDropbox {
                        if let anc = ignoredAncestor {
                            Text(tr("Не синхронизируется: исключена папка «") + "\(anc.name)" + tr("»"))
                                .foregroundColor(.secondary)
                        } else if let n = node, n.selfIgnored {
                            Button(tr("Снова синхронизировать с Dropbox")) {
                                performIgnore(on: false)
                            }
                        } else {
                            Button(tr("Не синхронизировать с Dropbox")) {
                                performIgnore(on: true)
                            }
                        }
                    }

                    // Корзина
                    Button(tr("Переместить в корзину…")) {
                        performTrash()
                    }
                    .disabled(trashBlocked)
                }
            }
        }
    }

    // MARK: - Размер из top/dup (когда узел не найден)

    private func topDupSize(for aPath: String) -> Int64 {
        if let topFiles = store.result?.top {
            if let t = topFiles.first(where: { $0.path == aPath }) { return t.size }
        }
        if let dups = store.result?.dups {
            for d in dups {
                if d.paths.contains(aPath) { return d.size }
            }
        }
        return 0
    }

    // MARK: - Корзина (как doTrash в эталоне)

    private func performTrash() {
        let note: String
        if isDropbox && !(node?.selfIgnored == true || ignoredAncestor != nil) {
            note = tr("Из Dropbox удалится на всех устройствах. Вернуть можно из корзины мака или из удалённых файлов на dropbox.com.")
        } else {
            note = tr("Вернуть можно из корзины.")
        }
        let what: String
        if let n = node {
            let sz = fmtBytes(store.value(n))
            what = n.kind == .dir ? "\(sz), \(plural(n.files, tr("файл"), tr("файла"), tr("файлов")))" : sz
        } else { what = "" }

        let alert = NSAlert()
        alert.messageText = tr("Переместить в корзину?")
        alert.informativeText = "\(path)\n\(what)\n\n\(note)"
        alert.addButton(withTitle: tr("В корзину"))
        alert.addButton(withTitle: tr("Отмена"))
        guard alert.runModal() == .alertFirstButtonReturn else { return }

        // Повторная проверка безопасности перед действием
        guard let root = store.result?.root, canTrash(path: path, root: root) else { return }

        // Сразу убираем из модели (removeLocal)
        let undo: (() -> Void)?
        if let n = node {
            undo = store.removeLocal(n)
        } else {
            undo = nil
        }
        store.objectWillChange.send()

        // В фоне — FileManager.trashItem
        let savedPath = path
        Task.detached {
            let err = moveToTrash(savedPath)
            await MainActor.run {
                if let e = err {
                    if let u = undo { u() }
                    let alert = NSAlert()
                    alert.messageText = tr("Не удалось переместить в корзину")
                    alert.informativeText = e
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }

    // MARK: - Не синхронизировать (как doIgnore в эталоне)

    private func performIgnore(on: Bool) {
        if on {
            let alert = NSAlert()
            alert.messageText = tr("Не синхронизировать с Dropbox?")
            alert.informativeText = "\(path)\n\n" + tr("На этом маке всё останется, но из облака и с других устройств удалится и перестанет занимать квоту. Вернуть — правый клик → «Снова синхронизировать».")
            alert.addButton(withTitle: tr("Не синхронизировать"))
            alert.addButton(withTitle: tr("Отмена"))
            guard alert.runModal() == .alertFirstButtonReturn else { return }
        }

        let err = setDropboxIgnored(path, on)
        if let e = err {
            let alert = NSAlert()
            alert.messageText = tr("Не получилось: ") + "\(e)"
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        if let n = node {
            let oldIgn = n.ign
            n.selfIgnored = on
            n.ign = on ? n.size : (n.children?.reduce(0) { $0 + $1.ign } ?? 0)
            let diff = n.ign - oldIgn
            var p = n.parent
            while let ancestor = p {
                ancestor.ign += diff
                p = ancestor.parent
            }
            store.objectWillChange.send()
            store.invalidateCache()
        }
    }
}