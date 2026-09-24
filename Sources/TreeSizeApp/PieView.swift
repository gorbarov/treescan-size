// Круговая диаграмма — UI-SPEC раздел 6, как renderPie()/pieHover()/pieClick() в template.html
import SwiftUI
import Charts
import TreeSizeCore

/// Вкладка «Диаграмма»: круговая диаграмма + легенда
struct PieView: View {
    @EnvironmentObject var store: AppStore

    // Текущий подсвеченный сектор (для hover)
    @State private var hoveredIndex: Int? = nil

    /// Секторы для отображения
    private var slices: [AppStore.PieSlice] {
        guard let dir = store.viewDir else { return [] }
        return store.pieSlices(for: dir)
    }

    /// Общая сумма значений
    private var total: Int64 {
        slices.reduce(0) { $0 + $1.value }
    }

    /// Цвета по порядку: светлая / тёмная тема
    private let pieColorsLight: [String] = [
        "#2a78d6", "#eb6834", "#1baf7a", "#eda100",
        "#e87ba4", "#008300", "#4a3aa7", "#e34948"
    ]
    private let pieColorsDark: [String] = [
        "#3987e5", "#d95926", "#199e70", "#c98500",
        "#d55181", "#008300", "#9085e9", "#e66767"
    ]

    /// Цвет для индекса (учёт текущей темы)
    private func pieColor(at index: Int) -> Color {
        guard index >= 0 && index < 8 else { return Color(hex: "#b9c1cc") }
        // Используем NSAppearance для определения тёмной темы
        // В SwiftUI доступ к цветам через environment, но для диаграммы используем dynamicColor
        return Color.dynamicColor(lightHex: pieColorsLight[index], darkHex: pieColorsDark[index])
    }

    /// Серый цвет для «Прочее»
    private var greyColor: Color {
        Color.dynamicColor(lightHex: "#b9c1cc", darkHex: "#5d646f")
    }

    var body: some View {
        VStack(spacing: 0) {
            // Хлебные крошки
            if let dir = store.viewDir {
                CrumbsView(node: dir)
            }

            Divider()

            if slices.isEmpty {
                VStack {
                    Text("Папка пустая")
                        .foregroundColor(.secondary)
                        .font(.system(size: 13))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Основное содержимое: диаграмма слева, легенда справа
                HStack(alignment: .top, spacing: 28) {
                    // Круговая диаграмма
                    pieChart
                        .frame(width: min(380, 360), height: min(380, 360))

                    // Легенда
                    legendView
                        .padding(.top, 4)
                }
                .padding(EdgeInsets(top: 18, leading: 22, bottom: 18, trailing: 22))

                // Подсказка внизу
                if !slices.isEmpty {
                    Text("Клик по сектору или строке открывает папку. Дерево слева — то же самое, полосками.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                }
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Круговая диаграмма (Chart + SectorMark)

    private var pieChart: some View {
        VStack(spacing: 0) {
            Chart {
                ForEach(slices.indices, id: \.self) { i in
                    let sl = slices[i]
                    let color = sl.colorIndex != nil ? pieColor(at: sl.colorIndex!) : greyColor
                    SectorMark(
                        angle: .value("Размер", sl.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(color)
                    .opacity(hoveredIndex == nil || hoveredIndex == i ? 1 : 0.3)
                }
            }
            .chartAngleSelection(value: $hoveredIndex)
            .chartOverlay { proxy in
                // Кастомная обработка кликов через gesture
                Color.clear
            }
            .overlay(
                // Текст в центре кольца
                VStack(spacing: 2) {
                    Text(fmtBytes(total))
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.primary)
                    if let dir = store.viewDir {
                        let title = dir.parent != nil ? dir.name : (store.result?.root ?? dir.name)
                        Text(title.count > 22 ? String(title.prefix(21)) + "…" : title)
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                    }
                }
                .allowsHitTesting(false)
            )
            .frame(maxWidth: 380, maxHeight: 380)
        }
    }

    // MARK: - Легенда

    private var legendView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                ForEach(slices.indices, id: \.self) { i in
                    let sl = slices[i]
                    let color = sl.colorIndex != nil ? pieColor(at: sl.colorIndex!) : greyColor
                    let pct = total > 0 ? Double(sl.value) / Double(total) : 0.0

                    legendRow(slice: sl, color: color, pct: pct, index: i)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 7)
                                .fill(hoveredIndex == i ? Color.treeHover : Color.clear)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                        .contentShape(RoundedRectangle(cornerRadius: 7))
                        .onHover { hovering in
                            hoveredIndex = hovering ? i : nil
                        }
                        .onTapGesture {
                            handleClick(index: i)
                        }
                }
            }
        }
    }

    /// Одна строка легенды
    private func legendRow(slice: AppStore.PieSlice, color: Color, pct: Double, index: Int) -> some View {
        HStack(spacing: 12) {
            // Цветной квадрат
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 0) {
                // Имя
                if slice.node != nil {
                    if slice.node?.kind == .dir {
                        Text(slice.title)
                            .fontWeight(.bold)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    } else {
                        Text(slice.title)
                            .font(.system(size: 13))
                            .lineLimit(1)
                    }
                } else {
                    Text("Прочее")
                        .font(.system(size: 13))
                        .lineLimit(1)
                }

                // Подпись мелко серым
                Text(subtitle(for: slice))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            // Размер жирным
            Text(fmtBytes(slice.value))
                .fontWeight(.bold)
                .font(.system(size: 13).monospacedDigit())
                .lineLimit(1)

            // Процент серым
            Text(fmtPct(pct))
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 58, alignment: .trailing)
                .lineLimit(1)
        }
    }

    /// Подпись под именем в легенде (как sub() в renderPie эталона)
    private func subtitle(for slice: AppStore.PieSlice) -> String {
        guard let node = slice.node else {
            // «Прочее»: N элементов помельче
            return "\(slice.title.lowercased()) помельче"
        }
        if node.kind == .dir {
            var parts: [String] = []
            if node.files > 0 { parts.append(plural(node.files, "файл", "файла", "файлов")) }
            if node.dirs > 0 { parts.append(plural(node.dirs, "папка", "папки", "папок")) }
            var result = parts.joined(separator: ", ")
            if node.cloud > 0 {
                result += " · ☁ \(fmtBytes(node.cloud))"
            }
            return result
        } else {
            // Файл: группа файла
            let ext = extOf(node.name)
            let gIdx = groupIndex(forExt: ext)
            return fileGroups[gIdx].title
        }
    }

    /// Обработка клика: как pieClick() в эталоне
    private func handleClick(index: Int) {
        guard index < slices.count else { return }
        let sl = slices[index]
        guard let node = sl.node else {
            // «Прочее» → переключиться на «Детали»
            store.tab = .details
            return
        }
        if node.kind == .dir {
            store.select(node, expand: true)
        } else {
            store.select(node)
        }
    }
}

// MARK: - chartAngleSelection binding

/// Binding для chartAngleSelection: преобразует Double? → Int?
extension ChartProxy {
    func angleSelection() -> Binding<Int?> {
        Binding<Int?>(
            get: { nil },
            set: { _ in }
        )
    }
}
