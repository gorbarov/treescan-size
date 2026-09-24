// Дерево с полосками — UI-SPEC раздел 5, как rowHtml()/flatten()/renderTree() в template.html
import SwiftUI
import TreeSizeCore

// MARK: - TreeView

struct TreeView: View {
    @EnvironmentObject var store: AppStore
    @FocusState private var isFocused: Bool

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 0) {
                    let rows = store.visibleRows
                    ForEach(rows.indices, id: \.self) { i in
                        let (node, depth) = rows[i]
                        TreeRowView(node: node, depth: depth, isSelected: node.id == store.selected?.id)
                            .id(node.id)
                            // Двойной клик — раскрыть/свернуть (как в эталоне)
                            .onTapGesture(count: 2) {
                                if node.kind == .dir && (node.children?.isEmpty == false) {
                                    store.toggle(node)
                                }
                            }
                            // Одинарный клик — выделить
                            .onTapGesture(count: 1) {
                                store.select(node)
                            }
                            // Контекстное меню — UI-SPEC раздел 9
                            .contextMenu {
                                NodeMenu(node: node, store: store)
                            }
                    }
                }
                .padding(.vertical, 4)
            }
            .onChange(of: store.selected?.id) { _, newId in
                if let id = newId {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        proxy.scrollTo(id, anchor: .center)
                    }
                }
            }
        }
        .focusable()
        .focused($isFocused)
        .onAppear { isFocused = true }
        // Клавиши ↑↓→← как в эталоне
        .onKeyPress(.upArrow) { moveUp(); return .handled }
        .onKeyPress(.downArrow) { moveDown(); return .handled }
        .onKeyPress(.rightArrow) { moveRight(); return .handled }
        .onKeyPress(.leftArrow) { moveLeft(); return .handled }
    }

    // MARK: - Навигация клавишами (как keydown в эталоне)

    private func moveUp() {
        let rows = store.visibleRows
        guard let sel = store.selected,
              let i = rows.firstIndex(where: { $0.node.id == sel.id }),
              i > 0 else { return }
        store.select(rows[i - 1].node)
    }

    private func moveDown() {
        let rows = store.visibleRows
        guard let sel = store.selected,
              let i = rows.firstIndex(where: { $0.node.id == sel.id }),
              i < rows.count - 1 else { return }
        store.select(rows[i + 1].node)
    }

    private func moveRight() {
        guard let sel = store.selected, sel.kind == .dir, let kids = sel.children, !kids.isEmpty else { return }
        if !store.expanded.contains(sel.id) {
            store.toggle(sel)
        } else if let first = store.children(sel).first {
            store.select(first)
        }
    }

    private func moveLeft() {
        guard let sel = store.selected else { return }
        if sel.kind == .dir, store.expanded.contains(sel.id) {
            store.toggle(sel)
        } else if let parent = sel.parent {
            store.select(parent)
        }
    }
}

// MARK: - TreeRowView (одна строка, как rowHtml в эталоне)

struct TreeRowView: View {
    let node: Node
    let depth: Int
    let isSelected: Bool

    @EnvironmentObject var store: AppStore

    /// Значение родителя для расчёта доли
    private var parentValue: Int64 {
        guard let p = node.parent else { return store.value(node) }
        return store.value(p)
    }

    /// Доля от родителя (0…1)
    private var proportion: CGFloat {
        parentValue > 0 ? CGFloat(store.value(node)) / CGFloat(parentValue) : 1
    }

    /// Показывать ли ☁
    private var showCloud: Bool {
        store.mode == .size && node.cloud > 0 && node.size > 0 && node.cloud >= node.size / 2
    }

    /// Имя узла: корень — полный путь, остальные — displayName
    private var displayName: String {
        node.parent == nil ? (store.result?.root ?? node.name) : node.displayName
    }

    /// Есть ли дети-папки (для стрелки)
    private var hasChildren: Bool {
        node.kind == .dir && (node.children?.isEmpty == false)
    }

    /// Цвет иконки файла по расширению
    private var fileColorHex: String {
        let ext = extOf(node.name)
        return fileGroups[groupIndex(forExt: ext)].colorHex
    }

    var body: some View {
        ZStack(alignment: .leading) {
            // Фон выделения (вся строка)
            if isSelected {
                Color.treeSelectionBg
                    .overlay(
                        Rectangle()
                            .fill(Color.treeSelectionAccent)
                            .frame(width: 2),
                        alignment: .leading
                    )
            }

            // Полоска (::before)
            barView

            // Содержимое строки
            HStack(spacing: 0) {
                // Отступ слева
                Color.clear
                    .frame(width: CGFloat(depth * 16 + 4))

                // Стрелка ▸/▾ (только у папок с детьми)
                if hasChildren {
                    Text(store.expanded.contains(node.id) ? "▾" : "▸")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .frame(width: 16, alignment: .center)
                } else {
                    Color.clear.frame(width: 16)
                }

                // Иконка папки/файла/сводки
                iconView

                // Размер: системный шрифт, жирный, .monospacedDigit() — как .sz в эталоне
                Text(fmtBytes(store.value(node)))
                    .fontWeight(.bold)
                    .font(.system(size: 13).monospacedDigit())
                    .frame(minWidth: 62, alignment: .leading)
                    .lineLimit(1)

                // Имя — с зачёркиванием и серым, если selfIgnored
                Text(displayName)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(textColor)
                    .strikethrough(node.selfIgnored, color: .secondary)

                // ☁ (фиолетовым, если cloud >= size/2 в режиме Размер)
                if showCloud {
                    Text(" ☁")
                        .font(.system(size: 11))
                        .foregroundColor(.treeCloudColor)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                // ⊘ не синхр. — серым, прямо перед колонкой процентов (как в эталоне)
                if node.selfIgnored {
                    Text("⊘ не синхр.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .padding(.trailing, 4)
                }

                // Процент от родителя (58pt, серым)
                if node.parent != nil {
                    Text(fmtPct(Double(store.value(node)) / Double(parentValue)))
                        .foregroundColor(.secondary)
                        .font(.system(size: 12).monospacedDigit())
                        .frame(width: 58, alignment: .trailing)
                        .padding(.trailing, 10)
                }
            }
            .zIndex(1) // поверх полоски
        }
        .frame(height: 26)
        .uiTag("row:" + displayName)
    }

    // MARK: - Полоска

    private var barView: some View {
        GeometryReader { geo in
            let indent = CGFloat(depth * 16 + 4)
            let left = indent + 36  // indent + tw(16) + ic(16) + margins(4)
            let available = max(0, geo.size.width - left - 62) // 62 = sz min-width
            let barW = available * proportion

            barShape
                .frame(width: max(0, barW), height: 22)
                .position(x: left + max(0, barW) / 2, y: 13)
        }
    }

    @ViewBuilder
    private var barShape: some View {
        if node.selfIgnored {
            // selfIgnored — серая штриховка (как .row.ignored::before в эталоне)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.treeAggBar)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
        } else {
            switch node.kind {
            case .dir:
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.treeDirBarStart, .treeDirBarEnd],
                                          startPoint: .leading, endPoint: .trailing))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Color.treeDirBarBorder, lineWidth: 1)
                    )
            case .file:
                RoundedRectangle(cornerRadius: 4)
                    .fill(LinearGradient(colors: [.treeFileBarStart, .treeFileBarEnd],
                                          startPoint: .leading, endPoint: .trailing))
            case .rest:
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.treeAggBar)
            }
        }
    }

    // MARK: - Иконки

    @ViewBuilder
    private var iconView: some View {
        switch node.kind {
        case .dir:
            folderIcon
        case .file:
            fileIcon
        case .rest:
            aggIcon
        }
    }

    /// Папка: жёлтый прямоугольник 16×12 скругление 2 + «ушко» 7×3 слева сверху
    private var folderIcon: some View {
        ZStack(alignment: .topLeading) {
            // Ушко 7×3
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.treeFolderColor)
                .frame(width: 7, height: 3)
            // Тело папки 16×12
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.treeFolderColor)
                .frame(width: 16, height: 12)
                .offset(y: 2)
        }
        .frame(width: 16, height: 16)
        .padding(.trailing, 4)
    }

    /// Файл: прямоугольник 11×14 цвета группы, скругление справа сверху
    private var fileIcon: some View {
        TopRightRoundedRect(radius: 1)
            .fill(Color(hex: fileColorHex))
            .frame(width: 11, height: 14)
            .padding(.horizontal, 4)
    }

    /// Сводка: пунктирная рамка (как .ic.a в эталоне)
    private var aggIcon: some View {
        RoundedRectangle(cornerRadius: 2)
            .stroke(Color.secondary, style: SwiftUI.StrokeStyle(lineWidth: 1.5, dash: [3, 2]))
            .frame(width: 16, height: 12)
            .padding(.trailing, 4)
    }

    // MARK: - Цвет текста

    private var textColor: Color {
        if node.selfIgnored || node.kind == .rest {
            return .secondary
        }
        return .primary
    }
}

// MARK: - RoundedCorner Shape (скругление только указанных углов, AppKit-совместимый)

struct TopRightRoundedRect: Shape {
    var radius: CGFloat = 1

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height, r = min(radius, min(w, h))
        p.move(to: CGPoint(x: 0, y: 0))
        p.addLine(to: CGPoint(x: w - r, y: 0))
        p.addArc(center: CGPoint(x: w - r, y: r), radius: r,
                 startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false)
        p.addLine(to: CGPoint(x: w, y: h))
        p.addLine(to: CGPoint(x: 0, y: h))
        p.closeSubpath()
        return p
    }
}

// MARK: - extOf (как в эталоне)

private func extOf(_ name: String) -> String {
    guard let d = name.lastIndex(of: ".") else { return "" }
    return String(name[name.index(after: d)...]).lowercased()
}