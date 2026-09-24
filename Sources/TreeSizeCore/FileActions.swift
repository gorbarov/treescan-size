// Действия над файлами и проверки путей — как в эталоне treesize.py
import AppKit
import Darwin

// IGNORE_ATTRS определён в Scanner.swift

/// Разрешить симлинки через libc realpath — как os.path.realpath() в эталоне.
/// Если realpath не сработал (путь не существует), возвращаем нормализованный путь.
private func resolveRealPath(_ path: String) -> String {
    let nsPath = path as NSString
    if let fsPath = nsPath.utf8String {
        if let r = Darwin.realpath(UnsafePointer<Int8>(fsPath), nil) {
            let s = String(cString: r)
            free(r)
            return s
        }
    }
    // realpath не сработал (путь не существует) — возвращаем нормализованный
    return URL(fileURLWithPath: path).standardized.path
}

/// Защищённые папки: корни дисков, системные, домашняя — как protected() в эталоне.
public func isProtected(_ path: String) -> Bool {
    let p = resolveRealPath(path)
    let home = resolveRealPath(NSHomeDirectory())

    if p == home || p == home + "/Library" {
        return true
    }

    var parts = (p as NSString).pathComponents
    if p.hasPrefix("/System/Volumes/Data") {
        parts = ["/"] + Array(parts.dropFirst(4))
    }

    return parts.count <= 2
        || (parts.count <= 3 && (parts[1] == "Users" || parts[1] == "Volumes"))
        || parts[1] == "System" || parts[1] == "usr"
        || parts[1] == "bin" || parts[1] == "sbin"
}

/// Можно ли выполнять действие над путём в просканированной папке — как serve() эталона.
public func isActionAllowed(path: String, root: String) -> Bool {
    let absPath = URL(fileURLWithPath: (path as NSString).expandingTildeInPath).standardized.path
    let rootReal = resolveRealPath(root)

    // Корень запрещён
    if absPath == rootReal { return false }

    let parentDir = (absPath as NSString).deletingLastPathComponent
    let parentReal = resolveRealPath(parentDir)

    // Родитель — корень или внутри корня
    guard parentReal == rootReal || parentReal.hasPrefix(rootReal + "/") else { return false }

    // Путь существует (lstat)
    var sb = stat()
    guard let fsPath = (absPath as NSString).utf8String else { return false }
    _ = fsPath
    let result = Darwin.lstat(UnsafePointer<Int8>(fsPath), &sb)
    guard result == 0 else { return false }

    return true
}

/// Показать файл в Finder
public func revealInFinder(_ path: String) {
    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
}

/// Переместить в корзину, ждать до 3 с, пока не исчезнет. Вернуть nil при успехе или текст ошибки.
public func moveToTrash(_ path: String) -> String? {
    let url = URL(fileURLWithPath: path)
    do {
        var resultingUrl: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &resultingUrl)
        for _ in 0..<30 {
            if !FileManager.default.fileExists(atPath: path) {
                return nil
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        return "команда корзины отработала, но файл остался на месте"
    } catch {
        return error.localizedDescription
    }
}

/// Установить / снять пометку Dropbox «не синхронизировать»
public func setDropboxIgnored(_ path: String, _ on: Bool) -> String? {
    guard let fsPath = (path as NSString).utf8String else { return "недопустимый путь" }
    if on {
        for attr in IGNORE_ATTRS {
            let result = attr.withCString { attrPtr in
                "1".withCString { valPtr in
                    Darwin.setxattr(UnsafePointer<Int8>(fsPath), attrPtr, valPtr, 1, 0, XATTR_NOFOLLOW)
                }
            }
            if result != 0 {
                return String(cString: Darwin.strerror(errno))
            }
        }
        return nil
    } else {
        for attr in IGNORE_ATTRS {
            attr.withCString { attrPtr in
                Darwin.removexattr(UnsafePointer<Int8>(fsPath), attrPtr, XATTR_NOFOLLOW)
            }
        }
        return nil
    }
}

/// Проверить, помечена ли папка как «не синхронизировать» в Dropbox
public func isDropboxIgnored(_ path: String) -> Bool {
    guard let fsPath = (path as NSString).utf8String else { return false }
    return IGNORE_ATTRS.contains { attr in
        attr.withCString { attrPtr in
            Darwin.getxattr(UnsafePointer<Int8>(fsPath), attrPtr, nil, 0, 0, XATTR_NOFOLLOW) >= 0
        }
    }
}

/// Скопировать текст в буфер обмена
public func copyToPasteboard(_ text: String) {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
}
