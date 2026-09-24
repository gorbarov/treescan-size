// Расширения — UI-SPEC раздел 8, как renderExt() в template.html
import SwiftUI
import TreeSizeCore

struct ExtView: View {
    @EnvironmentObject var store: AppStore

    private var stats: [ExtStat] {
        store.result?.ext ?? []
    }

    private var totalSize: Int64 {
        stats.reduce(0) { $0 + $1.size }
    }

    // Индексы групп с ненулевым размером, отсортированные по убыванию
    private var activeGroupIndices: [Int] {
        (0..<fileGroups.count).filter { groupSizeSum($0) > 0 }
            .sorted { groupSizeSum($0) > groupSizeSum($1) }
    }

    private func groupSizeSum(_ idx: Int) -> Int64 {
        stats.reduce(0) { groupIndex(forExt: $1.ext) == idx ? $0 + $1.size : $0 }
    }

    private func groupCloudSum(_ idx: Int) -> Int64 {
        stats.reduce(0) { groupIndex(forExt: $1.ext) == idx ? $0 + $1.cloud : $0 }
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
                // Полоса-стопка (как .stack в эталоне)
                stackBar

                // Список групп (как .glist в эталоне)
                groupList

                Divider()

                // Таблица расширений
                extTable
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Полоса-стопка

    private var stackBar: some View {
        HStack(spacing: 2) {
            ForEach(activeGroupIndices, id: \.self) { i in
                Rectangle()
                    .fill(Color(hex: fileGroups[i].colorHex))
                    .frame(maxWidth: .infinity)
                    .frame(height: 22)
            }
        }
        .frame(height: 22)
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    // MARK: - Список групп

    private var groupList: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(activeGroupIndices, id: \.self) { i in
                    let sz = groupSizeSum(i)
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(hex: fileGroups[i].colorHex))
                            .frame(width: 10, height: 10)
                        Text(fileGroups[i].title)
                            .font(.system(size: 12))
                        Text(fmtBytes(sz))
                            .fontWeight(.bold)
                            .font(.system(size: 12).monospacedDigit())
                        Text(fmtPct(Double(sz) / Double(totalSize)))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Таблица расширений (до 300)

    private var extTable: some View {
        let total = max(totalSize, 1)
        let rows = Array(stats.prefix(300))

        return ScrollView(.vertical) {
            VStack(spacing: 0) {
                // Шапка
                HStack(spacing: 0) {
                    Text("Расширение")
                        .frame(minWidth: 120, alignment: .leading)
                        .padding(.leading, 8)
                    Text("Тип")
                        .frame(width: 100, alignment: .leading)
                    Text("Размер")
                        .frame(width: 80, alignment: .trailing)
                    Text("Доля")
                        .frame(width: 140, alignment: .leading)
                    Text("Файлов")
                        .frame(width: 60, alignment: .trailing)
                    Text("Только в облаке")
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
                .background(Color.panel2Bg)

                Divider()

                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    extRow(row: row, total: total)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func extRow(row: ExtStat, total: Int64) -> some View {
        let g = fileGroups[groupIndex(forExt: row.ext)]
        let pct = Double(row.size) / Double(total)

        HStack(spacing: 0) {
            HStack(spacing: 4) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(hex: g.colorHex))
                    .frame(width: 11, height: 14)
                Text(row.ext.isEmpty ? "(без расширения)" : "." + row.ext)
                    .fontWeight(.bold)
                    .font(.system(size: 13))
            }
            .frame(minWidth: 120, alignment: .leading)
            .padding(.leading, 8)

            Text(g.title)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)

            Text(fmtBytes(row.size))
                .font(.system(.body).monospacedDigit())
                .frame(width: 80, alignment: .trailing)

            // Доля с полоской
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
            .frame(width: 140, alignment: .leading)

            Text(formatCount(row.count))
                .font(.system(.body).monospacedDigit())
                .frame(width: 60, alignment: .trailing)

            Text(row.cloud > 0 ? fmtBytes(row.cloud) : "")
                .font(.system(.body).monospacedDigit())
                .foregroundColor(.cloudColor)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .background(Color.panelBg)
    }

    // MARK: - Помощники

    private func formatCount(_ n: Int64) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "ru-RU")
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}