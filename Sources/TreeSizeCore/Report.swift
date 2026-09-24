// Сборка data (JSON) и HTML-отчёта — перенос serialize/scan_root/render_html из эталона.
import Foundation
#if canImport(Darwin)
import Darwin
#endif

/// [тип, имя, размер, на диске, в облаке, файлов, папок, изменён, не синхр. (-1 — сама папка), дети?]
/// тип: 0 папка, 1 файл, 2 сводка мелочи «[N файлов и M папок помельче]» (имя = "").
public func serialize(_ d: Dir, thr: Int64) -> [Any] {
    var items: [(size: Int64, kind: Int, idx: Int)] = []
    items.reserveCapacity(d.kids.count + d.fl.count)
    for (i, k) in d.kids.enumerated() { items.append((k.size, 0, i)) }
    for (i, f) in d.fl.enumerated() { items.append((f.size, 1, i)) }
    items.sort { $0.size > $1.size }   // Swift sort(by:) стабилен — как python-сортировка

    var out: [[Any]] = []
    var agg: [Int64] = [d.restFiles, d.restSize, d.restAlloc, d.restCloud, d.restMtime]
    var aggDirs = d.restDirs
    var aggIgn = d.restIgn
    for (i, item) in items.enumerated() {
        let keep = item.size >= thr || i < 3
        if item.kind == 0 {
            let obj = d.kids[item.idx]
            if keep {
                out.append(serialize(obj, thr: thr))
            } else {
                agg[0] += obj.files; agg[1] += obj.size; agg[2] += obj.alloc; agg[3] += obj.cloud
                agg[4] = max(agg[4], obj.mtime); aggDirs += 1 + obj.dirs; aggIgn += obj.ign
            }
        } else {
            let obj = d.fl[item.idx]
            if keep {
                out.append([1, obj.name, obj.size, obj.alloc, obj.cloud, 1, 0, obj.mtime, 0])
            } else {
                agg[0] += 1; agg[1] += obj.size; agg[2] += obj.alloc; agg[3] += obj.cloud
                agg[4] = max(agg[4], obj.mtime)
            }
        }
    }
    if agg[0] != 0 || aggDirs != 0 {
        out.append([2, "", agg[1], agg[2], agg[3], agg[0], aggDirs, agg[4], aggIgn])
    }
    var node: [Any] = [0, d.name, d.size, d.alloc, d.cloud, d.files, d.dirs, d.mtime, d.selfign ? Int64(-1) : d.ign]
    if !out.isEmpty {
        node.append(out)
    }
    return node
}

private func groupThousandsPublic(_ n: Int64) -> String {
    let s = String(n)
    var out = ""
    for (i, ch) in s.reversed().enumerated() {
        if i > 0 && i % 3 == 0 { out.append(" ") }
        out.append(ch)
    }
    return String(out.reversed())
}

/// Полный скан папки → словарь `data`, как у `scan_root` эталона.
/// `scanner`, если передан, используется как есть (чтобы снаружи можно было опрашивать
/// nfiles/bytes/cur, пока скан идёт в фоновом потоке); иначе создаётся новый.
public func scanRoot(_ root: String, options: ScanOptions, scanner: Scanner? = nil) -> [String: Any] {
    FileHandle.standardError.write("Сканирую \(root)\n".data(using: .utf8)!)
    let t0 = Date().timeIntervalSince1970
    let sc = scanner ?? Scanner(options: options)
    var rootStat = stat()
    _ = stat(root, &rootStat)   // os.stat следует за симлинками — как в эталоне
    let tree = sc.scan(root, root, rootStat.st_dev)
    let took = Date().timeIntervalSince1970 - t0
    FileHandle.standardError.write(("\r" + String(repeating: " ", count: 100) + "\r").data(using: .utf8)!)
    let gb = Double(tree.size) / 1_073_741_824.0
    let doneMsg = "Готово за \(Int(took)) с: \(groupThousandsPublic(tree.files)) файлов, " +
        "\(groupThousandsPublic(tree.dirs)) папок, \(String(format: "%.1f", gb)) ГБ\n"
    FileHandle.standardError.write(doneMsg.data(using: .utf8)!)

    var dupGroups = sc.dupsResult()
    dupGroups.sort { $0.size * Int64($0.paths.count - 1) > $1.size * Int64($1.paths.count - 1) }

    let thr = max(1, Int64(Double(tree.size) * options.minShare))

    let df = DateFormatter()
    df.dateFormat = "yyyy-MM-dd HH:mm"

    var data: [String: Any] = [:]
    data["root"] = root
    data["host"] = ProcessInfo.processInfo.hostName
    data["scanned"] = df.string(from: Date())
    data["took"] = (took * 10).rounded() / 10
    data["errors"] = sc.errors
    data["stuck"] = sc.stuck
    data["tree"] = serialize(tree, thr: thr)
    data["top"] = sc.topResult().map { [$0.size, $0.path, $0.alloc, $0.cloud, $0.mtime] }
    data["ext"] = sc.extResult().sorted { $0.size > $1.size }.map { [$0.ext, $0.size, $0.count, $0.cloud] }
    data["age"] = sc.ageResult().map { [$0.label, $0.size, $0.count] }
    data["dups"] = dupGroups.prefix(300).map { [$0.size, $0.paths] }
    data["dupMin"] = options.dupMin
    return data
}

/// HTML-отчёт: JSON без пробелов, "</" экранирован (чтобы не разрывал </script>), вставлен в шаблон.
public func renderHTML(data: [String: Any], template: String) -> String {
    let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
    let raw = String(data: jsonData, encoding: .utf8)!
    let payload = raw.replacingOccurrences(of: "</", with: "<\\/")
    return template.replacingOccurrences(of: "/*__DATA__*/{}", with: payload)
}
