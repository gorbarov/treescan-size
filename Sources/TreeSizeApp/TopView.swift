// Топ файлов — UI-SPEC раздел 8, как renderTop() в template.html
import SwiftUI
import TreeSizeCore

/// Обёртка для TopFile: сортировка как в result.top (уже по убыванию размера), без пересортировки
struct TopRow: Identifiable {
    let id: Int
    let index: Int
    let top: TopFile
}

struct TopView: View {
    @EnvironmentObject var store: AppStore

    private var filteredTop: [TopFile] {
        guard let top = store.result?.top, let dir = store.viewDir else { return [] }
        guard dir.parent != nil else { return top }
        let vp = dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
        return top.filter { $0.path.hasPrefix(vp) }
    }

    private var allCount: Int {
        store.result?.top.count ?? 0
    }

    /// Все файлы в порядке result.top (уже по убыванию размера), ничего не пересортировывать
    private var rows: [TopRow] {
        filteredTop.enumerated().map { (i, top) in
            TopRow(id: i, index: i, top: top)
        }
    }

    /// Путь viewDir + "/", или пустая строка для корня
    private var viewPrefix: String {
        guard let dir = store.viewDir, dir.parent != nil else { return "" }
        return dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
    }

    /// Количество символов для обрезки пути (как `cut` в эталоне)
    private var cutLen: Int {
        let prefix = viewPrefix
        return prefix.isEmpty ? 0 : prefix.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как #topNote в эталоне)
            if let view = store.viewDir {
                if view.parent != nil {
                    Text("**\(nf(Int64(filteredTop.count)))** из \(nf(Int64(allCount))) крупнейших файлов скана лежат в «\(view.name)».")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                } else {
                    Text("\(nf(Int64(allCount))) крупнейших файлов. Выберите папку в дереве, чтобы оставить только её файлы.")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                }
            }

            Divider()

            if !rows.isEmpty {
                tableView
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Table как в Деталях, ширина колонок: # 28, Файл гибкая, Размер 76, На диске 76, Изменён 80

    private var tableView: some View {
        Table(rows) {
            TableColumn("#") { row in
                Text("\(row.index + 1)")
                    .font(.system(.body).monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(28)

            TableColumn("Файл") { row in
                fileCell(top: row.top)
                    .padding(.leading, 10) // отступ 10 после #
            }

            TableColumn("Размер") { row in
                Text(fmtBytes(row.top.size))
                    .fontWeight(.bold)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn("На диске") { row in
                Text(fmtBytes(row.top.alloc))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn("Изменён") { row in
                Text(fmtDate(row.top.mtime))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(80)

            TableColumn("") { row in
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(row.top.path, forType: .string)
                }) {
                    Text("⧉")
                        .font(.system(size: 12))
                        .foregroundColor(.faintColor)
                }
                .buttonStyle(.plain)
            }
            .width(24)
        }
        .tableStyle(.inset)
    }

    // MARK: - Ячейка имени файла

    @ViewBuilder
    private func fileCell(top: TopFile) -> some View {
        let path = top.path
        let slashIdx = path.lastIndex(of: "/") ?? path.startIndex
        let fileName = slashIdx < path.endIndex ? String(path[path.index(after: slashIdx)...]) : path

        // Путь относительно viewDir — как p.slice(cut, slash) в эталоне
        let relPath: String = {
            let cut = cutLen
            guard cut > 0, cut < path.count else { return "." }
            let fromCut = String(path.dropFirst(cut))
            if let lastSlash = fromCut.lastIndex(of: "/") {
                return String(fromCut[..<lastSlash])
            }
            return fromCut.isEmpty ? "." : fromCut
        }()

        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 4) {
                Text(fileName)
                    .fontWeight(.bold)
                    .font(.system(size: 13))
                    .lineLimit(1)
                    .truncationMode(.tail)

                if top.cloud > 0 {
                    Text("☁")
                        .font(.system(size: 11))
                        .foregroundColor(.cloudColor)
                }
            }

            if !relPath.isEmpty {
                Text(relPath)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    // MARK: - Помощники

    private func nf(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru-RU")
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}