// Детали — UI-SPEC раздел 7, как renderDetails()/DCOLS в template.html
// Table с сортировкой, двойной клик по папке → select
import SwiftUI
import TreeSizeCore
import AppKit

struct DetailsView: View {
    @EnvironmentObject var store: AppStore

    /// Текущая сортировка: по умолчанию по value (размер в текущем режиме), по убыванию
    @State private var sortOrder: [KeyPathComparator<DetailsRow>] = [
        .init(\.value, order: .reverse)
    ]
    @State private var selection: Set<Int> = []

    private var viewDir: Node? { store.viewDir }

    private var rows: [DetailsRow] {
        guard let dir = viewDir else { return [] }
        let kids = store.children(dir)
        let tot = store.value(dir)
        return kids.map { node in
            let pct = tot > 0 ? Double(store.value(node)) / Double(tot) : 0.0
            return DetailsRow(
                id: node.id,
                node: node,
                value: store.value(node),
                size: node.size,
                alloc: node.alloc,
                cloud: node.cloud,
                files: node.files,
                dirs: node.dirs,
                pct: pct,
                mtime: node.mtime,
                isDir: node.kind == .dir,
                isFile: node.kind == .file,
                name: node.name,
                displayName: node.displayName,
                ext: extOf(node.name),
                kind: node.kind
            )
        }
        .sorted(using: sortOrder)
    }

    var body: some View {
        VStack(spacing: 0) {
            CrumbsView(node: viewDir)

            Divider()

            if viewDir != nil {
                if rows.isEmpty {
                    VStack {
                        Text("Пусто")
                            .foregroundColor(.secondary)
                            .font(.system(size: 13))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    tableView
                        .background(Color.panelBg)
                }
            }
        }
        .background(Color.panelBg)
        .onChange(of: viewDir?.id) { _, _ in
            selection = []
        }
    }

    // MARK: - Table

    private var tableView: some View {
        Table(rows, selection: $selection, sortOrder: $sortOrder) {
            TableColumn("Имя", value: \.name) { row in
                HStack(spacing: 4) {
                    iconView(for: row)
                        .frame(width: 16, alignment: .center)
                    Text(row.displayName)
                        .fontWeight(row.isDir ? .bold : .regular)
                        .foregroundColor(row.kind == .rest ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .width(min: 110, ideal: 140)

            TableColumn("Размер", value: \.size) { row in
                Text(fmtBytes(row.size))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn("На диске", value: \.alloc) { row in
                Text(fmtBytes(row.alloc))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn("Только в облаке", value: \.cloud) { row in
                if row.cloud > 0 {
                    Text(fmtBytes(row.cloud))
                        .foregroundColor(.cloudColor)
                        .font(.system(.body).monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(64)

            TableColumn("Файлов", value: \.files) { row in
                Text(formatCount(row.files))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(52)

            TableColumn("Папок", value: \.dirs) { row in
                // у файлов пусто, как в эталоне: n.t === 1 ? '' : NF.format(n.d)
                if !row.isFile {
                    Text(formatCount(row.dirs))
                        .font(.system(.body).monospacedDigit())
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .width(46)

            TableColumn("% от родителя", value: \.pctForSort) { row in
                percentBar(pct: row.pct)
            }
            .width(118)

            TableColumn("Изменено", value: \.mtime) { row in
                Text(fmtDate(row.mtime))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)
        }
        .tableStyle(.inset)
        .contextMenu(forSelectionType: Int.self) { ids in
            if let id = ids.first, let row = rows.first(where: { $0.id == id }) {
                contextMenuItems(for: row)
            }
        } primaryAction: { ids in
            guard let id = ids.first, let row = rows.first(where: { $0.id == id }) else { return }
            if row.isDir {
                store.select(row.node, expand: true)
            }
        }
    }

    // MARK: - Контекстное меню (раздел 9 — строка деталей)

    @ViewBuilder
    private func contextMenuItems(for row: DetailsRow) -> some View {
        let path = row.node.path
        let title: String = path.split(separator: "/").last.map(String.init) ?? row.name

        Text(title)
        Text(fmtBytes(store.value(row.node)))
            .foregroundColor(.secondary)

        Divider()

        Button("Показать в Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
        }

        Button("Скопировать путь") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(path, forType: .string)
        }
    }

    // MARK: - Иконки

    @ViewBuilder
    private func iconView(for row: DetailsRow) -> some View {
        switch row.kind {
        case .dir:
            folderIcon
        case .file:
            fileIcon(for: row.ext)
        case .rest:
            aggIcon
        }
    }

    /// Жёлтая папка: ушко 7×3 сверху + тело 16×12 (как folderIcon в TreeView)
    private var folderIcon: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#e9b53b"))
                .frame(width: 7, height: 3)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(hex: "#e9b53b"))
                .frame(width: 16, height: 12)
                .offset(y: 2)
        }
        .frame(width: 16, height: 16)
    }

    /// Файл: 11×14 цвета группы, скругление справа сверху
    private func fileIcon(for ext: String) -> some View {
        let gIdx = groupIndex(forExt: ext)
        let colorHex = fileGroups[gIdx].colorHex
        return TopRightRoundedRect(radius: 1)
            .fill(Color(hex: colorHex))
            .frame(width: 11, height: 14)
            .padding(.horizontal, 4)
    }

    /// Сводка: пунктирная рамка
    private var aggIcon: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.secondary, style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            .frame(width: 16, height: 12)
    }

    // MARK: - Полоска процента (как pbar в эталоне: <span class="pbar"><i style="width:...%"></i></span><span>%</span>)

    private func percentBar(pct: Double) -> some View {
        HStack(spacing: 4) {
            ZStack(alignment: .leading) {
                // Фон 60×12
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#e6eaf0"))
                    .frame(width: 60, height: 12)

                // Синяя заливка #2a78d6
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color(hex: "#2a78d6"))
                    .frame(width: max(0, 60 * pct), height: 12)
            }

            Text(fmtPct(pct))
                .font(.system(.caption).monospacedDigit())
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Помощники

    /// Форматирование счётчика с разделителями тысяч (как NF.format в эталоне)
    private func formatCount(_ n: Int64) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "ru-RU")
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - DetailsRow

struct DetailsRow: Identifiable {
    let id: Int
    let node: Node
    /// value = size или alloc по режиму (как V(n) в эталоне)
    let value: Int64
    let size: Int64
    let alloc: Int64
    let cloud: Int64
    let files: Int64
    let dirs: Int64
    /// Доля от родителя (0…1)
    let pct: Double
    let mtime: Int64
    let isDir: Bool
    let isFile: Bool
    let name: String
    let displayName: String
    let ext: String
    let kind: NodeKind

    /// Для сортировки по «% от родителя»: на самом деле сортируем по value,
    /// как в эталоне: k === 'p' ? V(x) : x[k]
    var pctForSort: Int64 { value }
}