import Foundation

public enum Access {
    /// Есть ли у приложения «Полный доступ к диску». Открыть этот файл можно только с полным доступом;
    /// попытка не вызывает системного вопроса.
    public static func hasFullDiskAccess() -> Bool {
        let fd = open("/Library/Application Support/com.apple.TCC/TCC.db", O_RDONLY)
        if fd >= 0 { close(fd); return true }
        return false
    }

    /// Места, чтение которых без полного доступа вызывает системный вопрос. Пути абсолютные.
    public static func promptingPaths(home: String = NSHomeDirectory()) -> [String] {
        ["Desktop", "Documents", "Downloads", "Library/Mobile Documents",
         "Library/Containers", "Library/Group Containers", "Pictures/Photos Library.photoslibrary",
         "Library/Mail", "Library/Messages", "Library/Safari"].map { home + "/" + $0 }
        + ["/Volumes"]
    }

    /// Скан без полного доступа: пути для пропуска.
    /// Если корень скана внутри одного из защищённых путей, этот путь не пропускается.
    public static func effectiveSkipPaths(forRoot root: String) -> Set<String> {
        guard !Access.hasFullDiskAccess() else { return [] }
        let all = Access.promptingPaths()
        // Если корень внутри одного из путей — убираем его из пропуска
        var skip = Set(all)
        for p in all {
            if root == p || root.hasPrefix(p + "/") {
                skip.remove(p)
            }
        }
        return skip
    }
}