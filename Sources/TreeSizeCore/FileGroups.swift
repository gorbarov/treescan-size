// Типы файлов - как GROUPS()/groupOf()/extOf() в эталоне template.html
import Foundation

public struct FileGroup: Identifiable {
    public let id: String
    public let title: String
    public let colorHex: String
    public let exts: [String]
}

/// 8 групп из эталона в том же порядке и с теми же цветами.
public let fileGroups: [FileGroup] = [
    FileGroup(id: "video", title: "Видео", colorHex: "#eb6834",
              exts: "mp4 mov avi mkv m4v wmv webm mts m2ts 3gp flv mpg mpeg vob braw r3d mxf prores".split(separator: " ").map(String.init)),
    FileGroup(id: "photo", title: "Фото и графика", colorHex: "#eda100",
              exts: "jpg jpeg png heic heif gif bmp tif tiff webp raw cr2 cr3 nef arw dng orf rw2 raf psd psb ai eps svg sketch fig xcf indd".split(separator: " ").map(String.init)),
    FileGroup(id: "audio", title: "Аудио", colorHex: "#e87ba4",
              exts: "mp3 wav m4a aac flac ogg aiff aif wma opus amr caf".split(separator: " ").map(String.init)),
    FileGroup(id: "doc", title: "Документы", colorHex: "#1baf7a",
              exts: "pdf doc docx xls xlsx ppt pptx key pages numbers txt md rtf odt ods odp csv epub djvu fb2 mobi".split(separator: " ").map(String.init)),
    FileGroup(id: "arch", title: "Архивы и образы", colorHex: "#4a3aa7",
              exts: "zip rar 7z tar gz tgz bz2 xz dmg iso pkg img sparseimage sparsebundle vmdk vdi qcow2 bak".split(separator: " ").map(String.init)),
    FileGroup(id: "code", title: "Код и данные", colorHex: "#008300",
              exts: "js ts json py html css sql db sqlite sqlite3 log xml yml yaml go rs java c cpp h php rb sh ipynb parquet pkl npy pt safetensors gguf bin dat".split(separator: " ").map(String.init)),
    FileGroup(id: "app", title: "Программы", colorHex: "#e34948",
              exts: "app exe msi dll dylib so apk ipa jar deb rpm".split(separator: " ").map(String.init)),
    FileGroup(id: "other", title: "Прочее", colorHex: "#8d96a3", exts: []),
]

private let extToGroup: [String: Int] = {
    var map: [String: Int] = [:]
    for (i, g) in fileGroups.enumerated() {
        for e in g.exts { map[e] = i }
    }
    return map
}()

/// Индекс группы по расширению. Прочее = последняя группа.
public func groupIndex(forExt ext: String) -> Int {
    extToGroup[ext.lowercased()] ?? fileGroups.count - 1
}