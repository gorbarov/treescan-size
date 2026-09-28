// Самопроверка без окна — UI-SPEC 13
import TreeSizeCore
import Darwin

/// Синхронный скан + AppStore + сбор фактов для проверки
@MainActor
public func runSelfTest(root: String) -> [String: Any] {
    L10n.forceLang("ru")
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
    store.expanded.insert(tree.path)

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

    // --- dir_trash: removeLocal папки media на свежем скане ---
    do {
        let data2 = scanRoot(root, options: ScanOptions())
        let store2 = AppStore()
        store2.result = ScanResult(data: data2)
        guard let tree2 = store2.result?.tree else { return facts }

        // Находим media
        var media2: Node? = nil
        for child in store2.children(tree2) {
            if child.name == "media" { media2 = child; break }
        }

        if let m = media2 {
            let rollback2 = store2.removeLocal(m)

            facts["dir_trash_root_dirs"] = tree2.dirs
            facts["dir_trash_top_total"] = store2.result?.top.count ?? 0
            facts["dir_trash_dups_root"] = store2.dupGroups(in: tree2).count

            rollback2()

            facts["dir_rollback_root_dirs"] = tree2.dirs
            facts["dir_rollback_top_total"] = store2.result?.top.count ?? 0
        }
    }

    // --- ign_trash: removeLocal файла ignored/big.bin на свежем скане ---
    do {
        let data3 = scanRoot(root, options: ScanOptions())
        let store3 = AppStore()
        store3.result = ScanResult(data: data3)
        guard let tree3 = store3.result?.tree else { return facts }

        // Находим ignored/big.bin
        var ignoredDir: Node? = nil
        for child in store3.children(tree3) {
            if child.name == "ignored" { ignoredDir = child; break }
        }

        if let ignDir = ignoredDir, let ignKids = ignDir.children {
            var bigBin: Node? = nil
            for child in ignKids {
                if child.name == "big.bin" { bigBin = child; break }
            }

            if let bb = bigBin {
                _ = store3.removeLocal(bb)
                facts["ign_trash_root_ign"] = tree3.ign
                facts["ign_trash_ignored_dir_ign_equals_size"] = ignDir.ign == ignDir.size
            }
        }
    }

    // --- canTrash факты (проверка безопасности корзины) ---
    facts["can_trash_file"] = canTrash(path: "/tmp/ts-fixture/media/film.mov", root: "/tmp/ts-fixture")
    facts["can_trash_scan_root"] = canTrash(path: "/tmp/ts-fixture", root: "/tmp/ts-fixture")
    facts["can_trash_home_under_users"] = canTrash(path: NSHomeDirectory(), root: "/Users")
    facts["can_trash_applications_app"] = canTrash(path: "/Applications/Safari.app", root: "/Applications")
    facts["can_trash_applications_dir"] = canTrash(path: "/Applications", root: "/")

    // --- places_unique_paths: все listPlaces() имеют разные path и ни у одного realpath не повторяется
    do {
        let places = listPlaces()
        let paths = places.map(\.path)
        let realpaths = places.compactMap { p -> String? in
            let nsPath = p.path as NSString
            guard let fsPath = nsPath.utf8String else { return nil }
            guard let r = Darwin.realpath(UnsafePointer<Int8>(fsPath), nil) else { return nil }
            let s = String(cString: r)
            free(r)
            return s
        }
        let pathsUnique = Set(paths).count == paths.count
        let realpathsUnique = Set(realpaths).count == realpaths.count
        facts["places_unique_paths"] = pathsUnique && realpathsUnique
    }

    // --- shouldSkip ---
    facts["shouldskip_root_slash_volumes_data"] = Scanner.shouldSkip(path: "/System/Volumes/Data", root: "/")
    facts["shouldskip_root_volumes_data"] = Scanner.shouldSkip(path: "/System/Volumes/Data", root: "/System/Volumes/Data")
    facts["shouldskip_root_slash_volumes_vm"] = Scanner.shouldSkip(path: "/System/Volumes/VM", root: "/")

    // --- node(at:) находит узел ---
    let nodeAtMedia = store.node(at: root + "/media")
    facts["node_at_media_name"] = nodeAtMedia?.name ?? "(nil)"

    // --- Повторная сборка ScanResult сохраняет раскрытие по пути ---
    do {
        let dataCopy = data  // копируем те же данные
        let store2 = AppStore()
        store2.result = ScanResult(data: dataCopy)
        if let tree2 = store2.result?.tree {
            store2.expanded.insert(tree2.path)
            let mediaPath = root + "/media"
            if let media2 = store2.node(at: mediaPath) {
                store2.expanded.insert(media2.path)
            }
            // visibleRows включает media и её детей
            facts["rebuild_rows_with_expanded_media"] = store2.visibleRows.count
        }
    }

    return facts
}