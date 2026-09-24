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

    @State private var topSelection: Set<Int> = []

    /// Все файлы в порядке result.top (уже по убыванию размера), ничего не пересортировывать
    private var rows: [TopRow] {
        filteredTop.enumerated().map { (i, top) in
            TopRow(id: i, index: i, top: top)
        }
    }

    /// Путь viewDir + "/" (для корня — сам корень + "/", как pathOf в эталоне)
    private var viewPrefix: String {
        guard let dir = store.viewDir else { return "" }
        return dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
    }

    /// Количество символов для обрезки пути (как `cut` в эталоне)
    private var cutLen: Int {
        viewPrefix.count
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как #topNote в эталоне)
            if let view = store.viewDir {
                if view.parent != nil {
                    let n1 = nf(Int64(filteredTop.count))
                    let n2 = nf(Int64(allCount))
                    Group {
                        if L10n.isRussian {
                            Text("**\(n1)** из \(n2)\(tr(" крупнейших файлов скана лежат в «"))\(view.name)\(tr("»."))")
                        } else {
                            Text("**\(n1)** \(tr(" крупнейших файлов скана лежат в «"))\(n2)\(tr("»."))")
                        }
                    }
                    .font(.system(size: 13))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.panelBg)
                } else {
                    Text(nf(Int64(allCount)) + tr(" крупнейших файлов. Выберите папку в дереве, чтобы оставить только её файлы."))
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
        Table(rows, selection: $topSelection) {
            TableColumn("#") { row in
                Text("\(row.index + 1)")
                    .font(.system(.body).monospacedDigit())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(28)

            TableColumn(tr("Файл")) { row in
                fileCell(top: row.top)
                    .padding(.leading, 10) // отступ 10 после #
            }

            TableColumn(tr("Размер")) { row in
                Text(fmtBytes(row.top.size))
                    .fontWeight(.bold)
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn(tr("На диске")) { row in
                Text(fmtBytes(row.top.alloc))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn(tr("Изменён")) { row in
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
        .contextMenu(forSelectionType: Int.self) { ids in
            if let id = ids.first, let row = rows.first(where: { $0.id == id }) {
                NodeMenu(path: row.top.path, store: store)
            }
        }
    }

    // MARK: - Ячейка имени файла

    @ViewBuilder
    private func fileCell(top: TopFile) -> some View {
        let path = top.path
        let slashIdx = path.lastIndex(of: "/") ?? path.startIndex
        let fileName = slashIdx < path.endIndex ? String(path[path.index(after: slashIdx)...]) : path

        // Путь относительно viewDir — как p.slice(cut, slash) || '.' в эталоне
        let relPath: String = {
            let cut = cutLen
            guard cut < path.count else { return "." }
            let sub = path[path.index(path.startIndex, offsetBy: cut)...]
            if let slash = sub.lastIndex(of: "/") {
                return String(sub[..<slash])
            }
            return "."
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
        .contextMenu {
            NodeMenu(path: top.path, store: store)
        }
    }

    private func nf(_ n: Int64) -> String {
        fmtCount(n)
    }
}