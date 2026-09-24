// Круговая диаграмма — UI-SPEC раздел 6, как renderPie()/pieHover()/pieClick() в template.html
import SwiftUI
import Charts
import TreeSizeCore

/// Вкладка «Диаграмма»: круговая диаграмма + легенда
struct PieView: View {
    @EnvironmentObject var store: AppStore

    @State private var hoveredIndex: Int? = nil
    @State private var selectedAngle: Int? = nil

    private var slices: [AppStore.PieSlice] {
        guard let dir = store.viewDir else { return [] }
        return store.pieSlices(for: dir)
    }

    private var total: Int64 {
        slices.reduce(0) { $0 + $1.value }
    }

    private let pieColorsLight: [String] = [
        "#2a78d6", "#eb6834", "#1baf7a", "#eda100",
        "#e87ba4", "#008300", "#4a3aa7", "#e34948"
    ]
    private let pieColorsDark: [String] = [
        "#3987e5", "#d95926", "#199e70", "#c98500",
        "#d55181", "#008300", "#9085e9", "#e66767"
    ]

    private func pieColor(at index: Int) -> Color {
        guard index >= 0 && index < 8 else { return Color(hex: "#b9c1cc") }
        return Color.dynamicColor(lightHex: pieColorsLight[index], darkHex: pieColorsDark[index])
    }

    private var greyColor: Color {
        Color.dynamicColor(lightHex: "#b9c1cc", darkHex: "#5d646f")
    }

    private var centerTitle: String {
        guard let dir = store.viewDir else { return "" }
        if dir.parent == nil {
            let path = store.result?.root ?? dir.name
            return (path as NSString).lastPathComponent
        }
        let t = dir.name
        return t.count > 22 ? String(t.prefix(21)) + "…" : t
    }

    var body: some View {
        if let dir = store.viewDir {
            GeometryReader { geo in
                let side = min(geo.size.width * 0.36, 380)
                VStack(alignment: .leading, spacing: 0) {
                    // Хлебные крошки
                    CrumbsView(node: dir)

                    Divider()

                    if slices.isEmpty {
                        VStack {
                            Text("Папка пустая")
                                .foregroundColor(.secondary)
                                .font(.system(size: 13))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Кольцо + легенда (как .piebox в эталоне: display:flex; gap:28px; padding:18px 22px; align-items:flex-start)
                        HStack(alignment: .top, spacing: 28) {
                            ringView(side: side)
                            .contextMenu {
                                if let a = selectedAngle, a < slices.count, let n = slices[a].node {
                                    NodeMenu(node: n, store: store)
                                }
                            }

                            legendView
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(20)
                    }

                    Spacer(minLength: 0)
                }
                .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            }
            .background(Color.panelBg)
        }
    }

    // MARK: - Кольцо

    private func ringView(side: CGFloat) -> some View {
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
        .overlay(
            VStack(spacing: 2) {
                Text(fmtBytes(total))
                    .font(.system(size: 17, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                    .foregroundColor(.primary)
                Text(centerTitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .allowsHitTesting(false)
        )
        .frame(width: side, height: side)
    }

    // MARK: - Легенда

    private var legendView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 4) {
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
                        .contextMenu {
                            if let n = sl.node {
                                NodeMenu(node: n, store: store)
                            }
                        }
                }

                // Подсказка
                Text("Клик по сектору или строке открывает папку. Дерево слева — то же самое, полосками.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
            }
            .padding(.top, 4)
        }
    }

    private func legendRow(slice: AppStore.PieSlice, color: Color, pct: Double, index: Int) -> some View {
        HStack(alignment: .center, spacing: 12) {
            // Квадрат 12×12
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 12, height: 12)

            // Имя + подпись — растягивается, прижато к левому краю
            VStack(alignment: .leading, spacing: 0) {
                Text(slice.title)
                    .font(.system(size: 13))
                    .fontWeight(slice.node?.kind == .dir ? .bold : .regular)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(subtitle(for: slice))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Размер 90pt, прижато к правому краю
            Text(fmtBytes(slice.value))
                .fontWeight(.bold)
                .font(.system(size: 13).monospacedDigit())
                .lineLimit(1)
                .frame(width: 90, alignment: .trailing)

            // Процент 58pt, прижато к правому краю
            Text(fmtPct(pct))
                .font(.system(size: 12).monospacedDigit())
                .foregroundColor(.secondary)
                .lineLimit(1)
                .frame(width: 58, alignment: .trailing)
        }
        .uiTag("legend:" + slice.title)
    }

    private func subtitle(for slice: AppStore.PieSlice) -> String {
        guard let node = slice.node else {
            let count = Int64(slice.restCount)
            return plural(count, "элемент", "элемента", "элементов") + " помельче"
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
            let ext = extOf(node.name)
            let gIdx = groupIndex(forExt: ext)
            return fileGroups[gIdx].title
        }
    }

    private func handleClick(index: Int) {
        guard index < slices.count else { return }
        let sl = slices[index]
        guard let node = sl.node else {
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
