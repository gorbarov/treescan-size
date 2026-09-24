// Расширения — UI-SPEC раздел 8, как renderExt() в template.html
// Полоса-стопка: GeometryReader с пропорциональными сегментами
// Список групп: LazyVGrid с .adaptive(minimum: 190)
// Таблица: Table с ширинами 120/130/76/118/56/70
import SwiftUI
import TreeSizeCore

struct ExtGroupInfo: Identifiable {
    let id: Int
    let color: Color
    let title: String
    let size: Int64
}

/// Обёртка ExtStat для Identifiable
struct ExtRow: Identifiable {
    let id: Int
    let ext: String
    let size: Int64
    let count: Int64
    let cloud: Int64
}

struct ExtView: View {
    @EnvironmentObject var store: AppStore

    private var stats: [ExtStat] {
        store.result?.ext ?? []
    }

    private var totalSize: Int64 {
        stats.reduce(0) { $0 + $1.size }
    }

    /// Группы с ненулевым размером, отсортированные по убыванию
    private var groups: [ExtGroupInfo] {
        var byIdx: [Int: Int64] = [:]
        for s in stats {
            let g = groupIndex(forExt: s.ext)
            byIdx[g, default: 0] += s.size
        }
        return byIdx
            .filter { $0.value > 0 }
            .sorted { $0.value > $1.value }
            .map { ExtGroupInfo(id: $0.key, color: Color(hex: fileGroups[$0.key].colorHex), title: fileGroups[$0.key].title, size: $0.value) }
    }

    /// Строки таблицы (до 300)
    private var rows: [ExtRow] {
        stats.prefix(300).enumerated().map { (i, s) in
            ExtRow(id: i, ext: s.ext, size: s.size, count: s.count, cloud: s.cloud)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как .note в эталоне)
            Text("Типы файлов по всему скану.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.panelBg)

            Divider()

            if !stats.isEmpty {
                // Полоса-стопка (как .stack в эталоне: пропорционально размеру, зазор 2, скругление 5)
                stackBar

                // Список групп (как .glist в эталоне: flex-wrap)
                groupGrid

                Divider()

                // Таблица расширений (до 300)
                extTable
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Полоса-стопка (GeometryReader, пропорции)

    private var stackBar: some View {
        let total = max(totalSize, 1) as Int64
        return GeometryReader { g in
            let gaps = CGFloat(max(0, groups.count - 1)) * 2
            HStack(spacing: 2) {
                ForEach(groups) { gr in
                    Rectangle()
                        .fill(gr.color)
                        .frame(width: max(2, (g.size.width - gaps) * CGFloat(gr.size) / CGFloat(total)))
                }
            }
        }
        .frame(height: 22)
        .clipShape(RoundedRectangle(cornerRadius: 5))
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Список групп (LazyVGrid, .adaptive(minimum: 190), переносится)

    private var groupGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), alignment: .leading)], alignment: .leading, spacing: 4) {
            ForEach(groups) { gr in
                HStack(spacing: 5) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(gr.color)
                        .frame(width: 10, height: 10)
                    Text(gr.title)
                        .font(.system(size: 12))
                    Text(fmtBytes(gr.size))
                        .fontWeight(.bold)
                        .font(.system(size: 12).monospacedDigit())
                    Text(fmtPct(Double(gr.size) / Double(max(totalSize, 1))))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 4)
    }

    // MARK: - Таблица расширений (Table, до 300, с ширинами колонок)

    private var extTable: some View {
        Table(rows) {
            TableColumn("Расширение") { row in
                let g = fileGroups[groupIndex(forExt: row.ext)]
                HStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(Color(hex: g.colorHex))
                        .frame(width: 11, height: 14)
                    Text(row.ext.isEmpty ? "(без расширения)" : "." + row.ext)
                        .fontWeight(.bold)
                        .font(.system(size: 13))
                }
            }
            .width(120)

            TableColumn("Тип") { row in
                Text(fileGroups[groupIndex(forExt: row.ext)].title)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .width(130)

            TableColumn("Размер") { row in
                Text(fmtBytes(row.size))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(76)

            TableColumn("Доля") { row in
                let pct = Double(row.size) / Double(max(totalSize, 1))
                HStack(spacing: 4) {
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "#e6eaf0"))
                            .frame(width: 60, height: 12)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: "#2a78d6"))
                            .frame(width: max(0, 60 * pct), height: 12)
                    }
                    Text(fmtPct(pct))
                        .font(.system(.caption).monospacedDigit())
                        .foregroundColor(.secondary)
                }
            }
            .width(118)

            TableColumn("Файлов") { row in
                Text(formatCount(row.count))
                    .font(.system(.body).monospacedDigit())
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(56)

            TableColumn("Только в облаке") { row in
                Text(row.cloud > 0 ? fmtBytes(row.cloud) : "")
                    .font(.system(.body).monospacedDigit())
                    .foregroundColor(.cloudColor)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .width(70)
        }
        .tableStyle(.inset)
    }

    // MARK: - Помощники

    private func formatCount(_ n: Int64) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "ru-RU")
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}