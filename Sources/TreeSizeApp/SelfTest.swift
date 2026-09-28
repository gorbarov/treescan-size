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

    // --- findDescendant: префиксный спуск ---
    facts["findDescendant_media_film_mov"] = tree.findDescendant(by: root + "/media/film.mov")?.name ?? "(nil)"
    facts["findDescendant_nope_x"] = tree.findDescendant(by: root + "/nope/x") == nil

    // --- findDescendant: файл, свёрнутый в сводку (не существует в дереве) ---
    // В фикстуре есть папка "many" с 50 файлами, из них только 3 сохраняются поимённо.
    // Полный путь к одному из свёрнутых: root + "/many/small_10.txt"
    let collapsedFile = root + "/many/small_10.txt"
    facts["findDescendant_rest_file"] = tree.findDescendant(by: collapsedFile) == nil

    // --- findDescendant: скорость 10 000 вызовов с несуществующим путём ---
    let fakePath = root + "/nonexistent/folder/file.txt"
    let t0 = Date()
    for _ in 0..<10_000 {
        _ = tree.findDescendant(by: fakePath)
    }
    let elapsed = Date().timeIntervalSince(t0)
    facts["findDescendant_speed"] = elapsed < 0.5

    // --- assignPaths с корнем /: путь ребёнка "Users" равен "/Users" ---
    do {
        let rootNode = Node.build(from: [0, "/", 0, 0, 0, 0, 0, 0, 0, [
            [0, "Users", 0, 0, 0, 0, 0, 0, 0, [
                [1, "test.txt", 100, 100, 0, 1, 0, 1000000, 0]
            ]],
            [0, "Applications", 0, 0, 0, 0, 0, 0, 0]
        ]])
        rootNode.assignPaths()
        let usersChild = rootNode.children?.first(where: { $0.name == "Users" })
        if usersChild?.path == "/Users" {
            facts["root_slash_assign_paths"] = "OK"
        } else {
            facts["root_slash_assign_paths"] = "FAIL: \(usersChild?.path ?? "nil")"
        }
    }

    // --- live-скан: с live=true даёт то же итоговое дерево ---
    do {
        let liveScanner = Scanner(options: ScanOptions())
        liveScanner.live = true
        let liveData = scanRoot(root, options: ScanOptions(), scanner: liveScanner)
        let liveResult = ScanResult(data: liveData)
        if let liveTree = liveResult.tree as Node? {
            facts["live_root_size"] = liveTree.size
            facts["live_root_files"] = liveTree.files
            facts["live_root_dirs"] = liveTree.dirs
        }
    }

    // --- liveSnapshot на /Applications: снимки из другого потока каждые 5 мс ---
    do {
        let appsRoot = "/Applications"
        var isDir: ObjCBool = false
        let appsExist = FileManager.default.fileExists(atPath: appsRoot, isDirectory: &isDir) && isDir.boolValue
        if appsExist {
            let snapScanner = Scanner(options: ScanOptions())
            snapScanner.live = true
            var snapshots: [(size: Int64, time: Date)] = []
            var scanDone = false
            let lock = NSLock()

            // Скан в фоне
            DispatchQueue.global(qos: .userInitiated).async {
                _ = scanRoot(appsRoot, options: ScanOptions(), scanner: snapScanner)
                lock.lock()
                scanDone = true
                lock.unlock()
            }

            // Полинг снимков каждые 5 мс
            var prevSize: Int64 = -1
            var monotonic = true
            while true {
                Thread.sleep(forTimeInterval: 0.005)
                if let snap = snapScanner.liveSnapshot() {
                    snapshots.append((snap.size, Date()))
                    if prevSize >= 0 && snap.size < prevSize {
                        monotonic = false
                    }
                    prevSize = snap.size
                }
                lock.lock()
                let done = scanDone
                lock.unlock()
                if done { break }
            }

            facts["live_big_snapshots"] = snapshots.count
            facts["live_big_monotonic"] = monotonic
            // Итоговый размер — через отдельный скан
            let finalScanner = Scanner(options: ScanOptions())
            finalScanner.live = true
            let finalData = scanRoot(appsRoot, options: ScanOptions(), scanner: finalScanner)
            let finalResult = ScanResult(data: finalData)
            if let lastSnapSize = snapshots.last?.size {
                facts["live_big_final_le"] = lastSnapSize <= finalResult.tree.size
            } else {
                facts["live_big_final_le"] = false
            }
        } else {
            facts["live_big_snapshots"] = 0
            facts["live_big_monotonic"] = false
            facts["live_big_final_le"] = false
        }
    }

    return facts
}