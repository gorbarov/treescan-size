import Foundation

public enum Access {
    /// Есть ли у приложения «Полный доступ к диску». Проверяет два признака (достаточно любого):
    /// 1. Открытие TCC.db (как раньше);
    /// 2. opendir Safari — без полного доступа macOS отвечает EPERM, без системного вопроса.
    /// Больше ничего не открывает, чтобы не вызывать системный вопрос.
    public static func hasFullDiskAccess() -> Bool {
        // Признак 1: TCC.db
        let fd = open("/Library/Application Support/com.apple.TCC/TCC.db", O_RDONLY)
        if fd >= 0 { close(fd); return true }
        // Признак 2: Safari
        let safari = NSHomeDirectory() + "/Library/Safari"
        if let dir = opendir(safari) {
            closedir(dir)
            return true
        }
        return false
    }

    /// Места, чтение которых без полного доступа вызывает системный вопрос. Пути абсолютные.
    public static func promptingPaths(home: String = NSHomeDirectory()) -> [String] {
        ["Desktop", "Documents", "Downloads", "Library/Mobile Documents",
         "Library/Containers", "Library/Group Containers", "Pictures/Photos Library.photoslibrary",
         "Library/Mail", "Library/Messages", "Library/Safari"].map { home + "/" + $0 }
        + ["/Volumes"]
    }

    /// Пути для пропуска при скане без полного доступа.
    /// - Parameter hasAccess: принудительный флаг доступа (по умолчанию реальная проверка).
    ///   Нужен для тестов: передай `false`, чтобы получить пути для пропуска независимо от реального доступа.
    /// - Parameter root: корень скана.
    /// - Returns: набор путей для пропуска.
    /// Для каждого защищённого пути добавляется вариант с префиксом `/System/Volumes/Data`,
    /// потому что на macOS при скане «Macintosh HD» корень — `/System/Volumes/Data`,
    /// а реальные защищённые папки лежат по `/System/Volumes/Data/Users/<имя>/Desktop`.
    /// Если корень скана внутри одного из защищённых путей, этот путь не пропускается
    /// (пользователь сам туда пошёл — вопрос ожидаем).
    public static func effectiveSkipPaths(hasAccess: Bool? = nil, forRoot root: String) -> Set<String> {
        let realAccess = hasAccess ?? hasFullDiskAccess()
        guard !realAccess else { return [] }
        let home = NSHomeDirectory()
        let dataPrefix = "/System/Volumes/Data"
        var skip = Set<String>()
        for p in promptingPaths(home: home) {
            skip.insert(p)
            // Вариант с /System/Volumes/Data (для скана корня Macintosh HD)
            if !p.hasPrefix(dataPrefix) {
                skip.insert(dataPrefix + p)
            }
        }
        // Если корень внутри одного из путей — убираем его из пропуска
        for p in skip {
            if root == p || root.hasPrefix(p + "/") {
                skip.remove(p)
            }
        }
        return skip
    }
}