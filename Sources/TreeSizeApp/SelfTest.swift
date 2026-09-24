// Самопроверка без окна — UI-SPEC 13
import TreeSizeCore

/// Синхронный скан + AppStore + сбор фактов для проверки
@MainActor
public func runSelfTest(root: String) -> [String: Any] {
    // Синхронный скан с параметрами по умолчанию
    let options = ScanOptions()
    let data = scanRoot(root, options: options)

    let store = AppStore()
    store.result = ScanResult(data: data)

    guard let tree = store.result?.tree else {
        return ["error": "scan failed"]
    }

    // Режим по умолчанию для этого корня
    let defaultMode: String = root.contains("/CloudStorage/Dropbox") ? "size" : "alloc"
    var facts: [String: Any] = [:]
    facts["default_mode"] = defaultMode

    // Переключаем режим на .size
    store.mode = .size

    // Раскрываем корень
    store.expanded.insert(tree.id)

    // rows_root: visibleRows.count, когда корень раскрыт
    facts["rows_root"] = store.visibleRows.count

    // Находим папку media
    var mediaNode: Node? = nil
    for child in store.children(tree) {
        if child.name == "media" {
            mediaNode = child
            break
        }
    }

    if let media = mediaNode {
        store.toggle(media)
        facts["rows_media_open"] = store.visibleRows.count
    } else {
        facts["rows_media_open"] = 0
    }

    // pie: заголовки pieSlices(for: корень)
    let slices = store.pieSlices(for: tree)
    facts["pie"] = slices.map { $0.title }

    // first_by_alloc: имя первого ребёнка корня в режиме .alloc (потом вернуть .size)
    store.mode = .alloc
    let firstKidsAlloc = store.children(tree)
    facts["first_by_alloc"] = firstKidsAlloc.first?.name ?? ""
    store.mode = .size

    // root_size
    facts["root_size"] = tree.size

    // top_media: topFiles(in: media).count
    if let media = mediaNode {
        facts["top_media"] = store.topFiles(in: media).count
    } else {
        facts["top_media"] = 0
    }

    // dups_root: dupGroups(in: корень).count
    facts["dups_root"] = store.dupGroups(in: tree).count

    // view_dir_of_photo: имя viewDir после select файла media/photo.JPG
    // Ищем photo.JPG среди детей media
    var photoNode: Node? = nil
    if let media = mediaNode, let mediaKids = media.children {
        for child in mediaKids {
            if child.name == "photo.JPG" {
                photoNode = child
                break
            }
        }
    }

    if let photo = photoNode {
        store.select(photo)
        facts["view_dir_of_photo"] = store.viewDir?.name ?? ""
    } else {
        facts["view_dir_of_photo"] = ""
    }

    // removeLocal(photo.JPG) → after_trash_*
    if let photo = photoNode {
        // Сохраняем ссылки на media для проверки после удаления
        let media = mediaNode!

        // Запоминаем количество детей media до удаления
        let rollback = store.removeLocal(photo)

        facts["after_trash_root_size"] = tree.size
        facts["after_trash_media_files"] = media.files
        facts["after_trash_top_media"] = store.topFiles(in: media).count

        // Откат
        rollback()

        facts["after_rollback_root_size"] = tree.size
        facts["after_rollback_media_files"] = media.files
    } else {
        facts["after_trash_root_size"] = 0
        facts["after_trash_media_files"] = 0
        facts["after_trash_top_media"] = 0
        facts["after_rollback_root_size"] = 0
        facts["after_rollback_media_files"] = 0
    }

    return facts
}