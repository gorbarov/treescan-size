// Перенос Scanner и list_dir из эталона reference/treesize.py.
// Логика переносится построчно, не «улучшается» — иначе разойдётся с эталоном (см. tools/compare.py).
import Foundation
#if canImport(Darwin)
import Darwin
#endif

let SF_DATALESS: UInt32 = 0x40000000      // macOS: файл есть только в облаке (File Provider)
let KEEP_FILES_PER_DIR = 400              // сколько самых больших файлов папки хранить поимённо
let TOP_FILES = 1000
// (порог в днях; nil — «дальше без ограничения», label)
let AGE_BUCKETS: [(limit: Double?, label: String)] = [
    (30, "до 1 месяца"), (90, "1–3 месяца"), (365, "3–12 месяцев"),
    (730, "1–2 года"), (1825, "2–5 лет"), (nil, "старше 5 лет"),
]
let IGNORE_ATTRS = ["com.apple.fileprovider.ignore#P", "com.dropbox.ignored"]   // «не синхронизировать» в Dropbox

/// Папка помечена Dropbox как «не синхронизировать» (атрибут xattr).
func isIgnored(_ path: String) -> Bool {
    for a in IGNORE_ATTRS {
        if getxattr(path, a, nil, 0, 0, XATTR_NOFOLLOW) >= 0 {
            return true
        }
    }
    return false
}

/// Крупнейший файл папки: (размер, имя, на диске, в облаке, изменён).
public struct FileEntry {
    public var size: Int64
    public var name: String
    public var alloc: Int64
    public var cloud: Int64
    public var mtime: Int64
}

public final class Dir {
    public var name: String
    public var size: Int64 = 0
    public var alloc: Int64 = 0
    public var cloud: Int64 = 0
    public var files: Int64 = 0
    public var dirs: Int64 = 0
    public var mtime: Int64 = 0
    public var kids: [Dir] = []      // подпапки
    public var fl: [FileEntry] = []  // крупнейшие файлы
    // «мелочь»: файлов, размер, на диске, облако, mtime, папок, не синхр.
    public var restFiles: Int64 = 0
    public var restSize: Int64 = 0
    public var restAlloc: Int64 = 0
    public var restCloud: Int64 = 0
    public var restMtime: Int64 = 0
    public var restDirs: Int64 = 0
    public var restIgn: Int64 = 0
    public var err: Int64 = 0
    public var ign: Int64 = 0        // байт внутри, помеченных «не синхронизировать»
    public var selfign: Bool = false // сама папка помечена

    public init(name: String) { self.name = name }
}

public struct ScanOptions {
    public var oneFS: Bool
    public var minShare: Double
    public var dupMin: Int64
    public var timeout: Double

    public init(oneFS: Bool = true, minShare: Double = 2e-6, dupMin: Int64 = 5 * 1024 * 1024, timeout: Double = 10) {
        self.oneFS = oneFS
        self.minShare = minShare
        self.dupMin = dupMin
        self.timeout = timeout
    }
}

/// Список папки через opendir/readdir с lstat каждого элемента — в отдельном потоке.
///
/// File Provider (Dropbox, iCloud) иногда навсегда зависает на чтении папки.
/// Если за `timeout` секунд не пришло ни одного нового элемента, бросаем папку
/// (поток остаётся висеть — не страшно, программа его не ждёт).
/// Возвращает (элементы, код ошибки opendir) или nil при зависании.
private final class DirListingState {
    let lock = NSLock()
    var items: [(name: String, path: String, st: stat?)] = []
    var err: Int32 = 0
    var done = false
}

func listDir(_ path: String, timeout: Double) -> (items: [(name: String, path: String, st: stat?)], err: Int32)? {
    let res = DirListingState()
    let sem = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .userInitiated).async {
        guard let dirp = opendir(path) else {
            res.lock.lock(); res.err = errno; res.done = true; res.lock.unlock()
            sem.signal()
            return
        }
        defer { closedir(dirp) }
        while let entry = readdir(dirp) {
            var nameBuf = entry.pointee.d_name
            let name = withUnsafeBytes(of: &nameBuf) { raw -> String in
                String(cString: raw.baseAddress!.assumingMemoryBound(to: CChar.self))
            }
            if name == "." || name == ".." { continue }
            let full = path + "/" + name
            var st = stat()
            let r = lstat(full, &st)
            res.lock.lock()
            res.items.append((name, full, r == 0 ? st : nil))
            res.lock.unlock()
        }
        res.lock.lock(); res.done = true; res.lock.unlock()
        sem.signal()
    }
    var seen = -1
    var idle = 0.0
    while true {
        _ = sem.wait(timeout: .now() + 0.5)
        res.lock.lock()
        let done = res.done
        let n = res.items.count
        let items = done ? res.items : []
        let err = res.err
        res.lock.unlock()
        if done {
            return (items, err)
        }
        idle = (n != seen) ? 0.0 : idle + 0.5
        seen = n
        if idle >= timeout {
            return nil
        }
    }
}

public final class Scanner {
    public let options: ScanOptions
    public let now: Double

    // топ-1000 файлов по размеру (аналог heapq в эталоне): (размер, путь, на диске, облако, изменён)
    private var top: [(size: Int64, path: String, alloc: Int64, cloud: Int64, mtime: Int64)] = []
    private var topMinIndex = -1
    // расширение -> (размер, число файлов, в облаке)
    private var ext: [String: (size: Int64, count: Int64, cloud: Int64)] = [:]
    // 6 корзин возраста: (размер, число файлов)
    private var age: [(size: Int64, count: Int64)]
    // "size|ext" -> пути (только size >= dupMin)
    private var dups: [String: [String]] = [:]
    private var seenInodes: Set<String> = []

    public private(set) var errors: Int64 = 0
    public private(set) var stuck: [String] = []

    // прогресс — читается из другого потока (UI), поэтому под замком
    private let lock = NSLock()
    private var _nfiles: Int64 = 0
    private var _bytes: Int64 = 0
    private var _cur: String = ""
    private var lastReport: Double = 0

    public var nfiles: Int64 { lock.lock(); defer { lock.unlock() }; return _nfiles }
    public var bytes: Int64 { lock.lock(); defer { lock.unlock() }; return _bytes }
    public var cur: String { lock.lock(); defer { lock.unlock() }; return _cur }

    public init(options: ScanOptions) {
        self.options = options
        self.age = Array(repeating: (0, 0), count: AGE_BUCKETS.count)
        self.now = Date().timeIntervalSince1970
    }

    private func progress(_ path: String) {
        lock.lock()
        _cur = path
        let t = Date().timeIntervalSince1970
        let shouldPrint = t - lastReport > 1.5
        if shouldPrint { lastReport = t }
        let n = _nfiles
        lock.unlock()
        if shouldPrint {
            let short = path.count < 70 ? path : "…" + String(path.suffix(69))
            let numStr = groupThousands(n)
            let line = "\r  " + numStr.leftPad(9) + " файлов  " + short.rightPad(72)
            FileHandle.standardError.write(line.data(using: .utf8)!)
        }
    }

    public func scan(_ path: String, _ name: String, _ dev: Int32) -> Dir {
        let d = Dir(name: name)
        progress(path)
        guard let listing = listDir(path, timeout: options.timeout) else {
            lock.lock(); stuck.append(path); lock.unlock()
            let msg = "\r  ⚠ не отвечает \(Int(options.timeout)) с, пропускаю: \(path)\n"
            FileHandle.standardError.write(msg.data(using: .utf8)!)
            d.err = 1
            return d
        }
        if listing.err != 0 {
            lock.lock(); errors += 1; lock.unlock()
            d.err = 1
            return d
        }
        var files: [FileEntry] = []
        for (eName, ePath, stOpt) in listing.items {
            guard let s = stOpt else {
                lock.lock(); errors += 1; lock.unlock()
                continue
            }
            let mode = s.st_mode
            if (mode & S_IFMT) == S_IFLNK { continue }
            if (mode & S_IFMT) == S_IFDIR {
                if options.oneFS && s.st_dev != dev { continue }
                let sub = scan(ePath, eName, dev)
                d.kids.append(sub)
                d.size += sub.size; d.alloc += sub.alloc; d.cloud += sub.cloud
                d.files += sub.files; d.dirs += sub.dirs + 1
                d.err += sub.err
                d.ign += sub.ign
                if sub.mtime > d.mtime { d.mtime = sub.mtime }
                continue
            }
            var size = Int64(s.st_size)
            if s.st_nlink > 1 {
                let key = "\(s.st_dev):\(s.st_ino)"
                if seenInodes.contains(key) {
                    size = 0        // жёсткая ссылка — место уже посчитано
                } else {
                    seenInodes.insert(key)
                }
            }
            let alloc: Int64 = size != 0 ? Int64(s.st_blocks) * 512 : 0
            let cloud: Int64 = (s.st_flags & SF_DATALESS) != 0 ? size : 0
            var mt = Int64(s.st_mtimespec.tv_sec)
            if Double(mt) > now + 86400 { mt = 0 }   // битые даты из будущего не считаем
            lock.lock(); _nfiles += 1; lock.unlock()
            d.files += 1; d.size += size; d.alloc += alloc; d.cloud += cloud
            if mt > d.mtime { d.mtime = mt }
            files.append(FileEntry(size: size, name: eName, alloc: alloc, cloud: cloud, mtime: mt))
            account(path: ePath, name: eName, size: size, alloc: alloc, cloud: cloud, mtime: mt)
        }
        // Мелочь сворачиваем сразу, чтобы скан всего диска не съедал память.
        let floor = Double(bytes) * options.minShare
        files.sort { $0.size > $1.size }
        var keep = 0
        while keep < files.count && keep < KEEP_FILES_PER_DIR && (keep < 3 || Double(files[keep].size) >= floor) {
            keep += 1
        }
        for f in files[keep...] {
            d.restFiles += 1; d.restSize += f.size; d.restAlloc += f.alloc; d.restCloud += f.cloud
            if f.mtime > d.restMtime { d.restMtime = f.mtime }
        }
        d.fl = Array(files[..<keep])
        if d.kids.count > 3 {
            d.kids.sort { $0.size > $1.size }
            let small = d.kids[3...].filter { Double($0.size) < floor }
            if !small.isEmpty {
                d.kids.removeLast(small.count)
                for k in small {
                    d.restFiles += k.files; d.restSize += k.size; d.restAlloc += k.alloc; d.restCloud += k.cloud
                    d.restMtime = max(d.restMtime, k.mtime); d.restDirs += 1 + k.dirs; d.restIgn += k.ign
                }
            }
        }
        if isIgnored(path) {
            d.ign = d.size
            d.selfign = true
        }
        return d
    }

    private func account(path: String, name: String, size: Int64, alloc: Int64, cloud: Int64, mtime: Int64) {
        lock.lock(); _bytes += size; lock.unlock()
        // топ-1000 по размеру
        if top.count < TOP_FILES {
            top.append((size, path, alloc, cloud, mtime))
            if top.count == TOP_FILES { recomputeTopMin() }
        } else if size > top[topMinIndex].size {
            top[topMinIndex] = (size, path, alloc, cloud, mtime)
            recomputeTopMin()
        }
        // расширение
        let e = extOf(name)
        if var x = ext[e] {
            x.size += size; x.count += 1; x.cloud += cloud
            ext[e] = x
        } else {
            ext[e] = (size, 1, cloud)
        }
        // возраст
        let days = (now - Double(mtime)) / 86400
        for i in 0..<AGE_BUCKETS.count {
            let lim = AGE_BUCKETS[i].limit
            if lim == nil || days < lim! {
                age[i].size += size; age[i].count += 1
                break
            }
        }
        // дубли — только от заданного размера
        if size >= options.dupMin {
            let key = "\(size)|\(e)"
            dups[key, default: []].append(path)
        }
    }

    private func recomputeTopMin() {
        var mi = 0
        for i in 1..<top.count where top[i].size < top[mi].size { mi = i }
        topMinIndex = mi
    }

    /// Итоги скана для сборки отчёта (Report.swift).
    public func topResult() -> [(size: Int64, path: String, alloc: Int64, cloud: Int64, mtime: Int64)] { top }
    public func extResult() -> [(ext: String, size: Int64, count: Int64, cloud: Int64)] {
        ext.map { (ext: $0.key, size: $0.value.size, count: $0.value.count, cloud: $0.value.cloud) }
    }
    public func ageResult() -> [(label: String, size: Int64, count: Int64)] {
        zip(AGE_BUCKETS, age).map { (label: $0.0.label, size: $0.1.size, count: $0.1.count) }
    }
    public func dupsResult() -> [(size: Int64, paths: [String])] {
        dups.compactMap { key, paths in
            guard paths.count > 1 else { return nil }
            let size = Int64(key.split(separator: "|", maxSplits: 1)[0])!
            return (size: size, paths: paths.sorted())
        }
    }
}

/// Извлечение расширения — как в эталоне: точка не первая и не последняя, само расширение не длиннее 12 символов.
public func extOf(_ name: String) -> String {
    // считаем кодовые точки, как len() в Python: у «й» в разложенной форме их две
    let scalars = Array(name.unicodeScalars)
    guard let dot = scalars.lastIndex(of: ".") else { return "" }
    let len = scalars.count
    if dot > 0 && dot < len - 1 && (len - dot) <= 12 {
        var tail = String.UnicodeScalarView()
        tail.append(contentsOf: scalars[(dot + 1)...])
        return String(tail).lowercased()
    }
    return ""
}

private func groupThousands(_ n: Int64) -> String {
    let s = String(n)
    var out = ""
    for (i, ch) in s.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { out.append(" ") }
        out.append(ch)
    }
    return String(out.reversed())
}

private extension String {
    func leftPad(_ width: Int) -> String {
        count >= width ? self : String(repeating: " ", count: width - count) + self
    }
    func rightPad(_ width: Int) -> String {
        count >= width ? self : self + String(repeating: " ", count: width - count)
    }
}
