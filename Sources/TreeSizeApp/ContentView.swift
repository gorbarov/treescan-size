// Главный экран: UI-SPEC раздел 4 — панель инструментов, плашки, строка сведений,
// HSplitView, строка состояния, оверлей скана
import SwiftUI
import TreeSizeCore
// MARK: - ContentView

/// Главный экран приложения
struct ContentView: View {
    @EnvironmentObject var store: AppStore
    @State private var showModeHelp = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                toolbar
                banners
                Divider()
                infoBar
                    .background(Color.panel2Bg)
                Divider()
                mainSplit
                    .background(Color.windowBg)
                Divider()
                statusBar
                    .background(Color.panel2Bg)
            }

            if store.isScanning {
                scanOverlay
            }
        }
        .background(Color.windowBg)
        .onPreferenceChange(UIFramesKey.self) { store.uiFrames = $0 }
        .coordinateSpace(name: "uitest")
    }

    // MARK: - Панель инструментов (как .top в эталоне)

    private var toolbar: some View {
        HStack(spacing: 14) {
            logo

            HStack(spacing: 0) {
                Text(AppInfo.name)
                    .fontWeight(.bold)
                    .font(.system(size: 15))
                Text(tr(" для мака"))
                    .foregroundColor(.secondary)
                    .font(.system(size: 15))
            }
            .fixedSize()

            // Путь корня — серым, обрезка посередине
            Text(store.result?.root ?? "")
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Button(tr("📂 Открыть…")) {
                store.showPlaces = true
            }
            .buttonStyle(.borderless)
            .popover(isPresented: $store.showPlaces, arrowEdge: .bottom) {
                PlacesView()
                    .environmentObject(store)
            }

            Button(tr("⟳ Пересканировать")) {
                store.rescan()
            }
            .buttonStyle(.borderless)

            // Сегмент Размер | На диске — заменяем Picker на две Button (чтобы попадать в половинки)
            HStack(spacing: 0) {
                Button(tr("Размер")) { store.mode = .size }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .fontWeight(store.mode == .size ? .semibold : .regular)
                    .foregroundColor(store.mode == .size ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(store.mode == .size ? Color.accentLinkColor : Color.clear)
                    .cornerRadius(6)
                    .uiTag("mode:size")
                    .help(tr("Сколько весят файлы. По нему считают квоту Dropbox и iCloud."))

                Button(tr("На диске")) { store.mode = .alloc }
                    .buttonStyle(.plain)
                    .font(.system(size: 12))
                    .fontWeight(store.mode == .alloc ? .semibold : .regular)
                    .foregroundColor(store.mode == .alloc ? .white : .primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 4)
                    .background(store.mode == .alloc ? Color.accentLinkColor : Color.clear)
                    .cornerRadius(6)
                    .uiTag("mode:alloc")
                    .help(tr("Сколько места файлы реально занимают на этом маке."))
            }
            .frame(width: 180)
            .background(Color.panel2Bg)
            .cornerRadius(8)

            // Кнопка ⓘ с пояснением
            Button { showModeHelp.toggle() } label: {
                Image(systemName: "info.circle")
            }
            .buttonStyle(.plain)
            .help(tr("Чем отличаются «Размер» и «На диске»?"))
            .popover(isPresented: $showModeHelp, arrowEdge: .bottom) {
                ModeHelpView()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.panelBg) // .top → var(--panel) → белый/тёмный
    }

    private var logo: some View {
        HStack(spacing: 2) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color(red: 0x2a/255, green: 0x78/255, blue: 0xd6/255))
                .frame(width: 9, height: 20)
            VStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0xed/255, green: 0xa1/255, blue: 0x00/255))
                    .frame(width: 5, height: 9)
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color(red: 0xeb/255, green: 0x68/255, blue: 0x34/255))
                    .frame(width: 5, height: 9)
            }
        }
    }

    // MARK: - Плашки (эталон #banner)

    @ViewBuilder
    private var banners: some View {
        // Dropbox-баннер
        if isDropbox && UserDefaults.standard.string(forKey: "banner") != "off" {
            HStack(spacing: 10) {
                mdText(tr("☁️ **Квоту Dropbox считают по «Размеру»**: файлы «только онлайн» на маке не занимают места, но в тариф входят. Фиолетовым — сколько лежит только в облаке. Папки с пометкой «⊘ не синхр.» лежат только на этом маке и в квоту не входят. Общие папки считаются в квоту каждого участника."))
                    .font(.system(size: 12.5))
                Spacer()
                Button(action: {
                    UserDefaults.standard.set("off", forKey: "banner")
                }) {
                    Text(tr("×"))
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                // color-mix(in srgb, var(--cloud) 10%, var(--panel))  → #6a4fd8 при 10% на panel
                Color.cloudColor.opacity(0.1)
            )
        }

        // Stuck-предупреждение
        if let stuck = store.result?.stuck, !stuck.isEmpty {
            let paths = stuck.prefix(5).map { p -> String in
                guard let root = store.result?.root else { return p }
                return String(p.dropFirst(root.count)) // относительный путь
            }
            let stuckCnt = Int64(stuck.count)
            let pathsStr = paths.map { "`\($0)`" }.joined(separator: ", ")
            let suffix = stuck.count > 5 ? tr(" и другие") : ""
            let msg: String = {
                if L10n.isRussian {
                    return "⚠️ **\(plural(stuckCnt, "папку", "папки", "папок")) прочитать не удалось**: облако не ответило за отведённое время, их размер не учтён. " + pathsStr + suffix
                } else {
                    return "⚠️ **\(stuckCnt) " + tr("⚠️ **папки прочитать не удалось**: облако не ответило за отведённое время, их размер не учтён. ") + pathsStr + suffix
                }
            }()
            HStack(alignment: .top, spacing: 10) {
                mdText(msg)
                    .font(.system(size: 12.5))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.warningBg)
        }
    }

    private var isDropbox: Bool {
        guard let root = store.result?.root else { return false }
        return root.contains("/CloudStorage/Dropbox")
    }

    // MARK: - Строка сведений (как renderInfo в эталоне)

    private func displayName(for node: Node) -> String {
        if node.parent == nil {
            let path = node.name
            return (path as NSString).lastPathComponent
        }
        return node.displayName
    }

    private var infoBar: some View {
        Group {
            if let sel = store.selected {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 22) {
                        // Имя — приоритет ширины, max-width ~40ch, не обрезать до «ts-fi…»
                        Text(displayName(for: sel))
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .layoutPriority(1) // приоритет растяжения
                            .frame(maxWidth: 260) // ~40ch × ~6.5pt ≈ 260pt, но с приоритетом
                            .fixedSize(horizontal: false, vertical: false)

                infoItem(label: tr("Размер"), value: fmtBytes(store.value(sel)))
                        infoItem(label: tr("На диске"), value: fmtBytes(sel.alloc))

                        if let parent = sel.parent {
                            let pct = store.value(parent) > 0
                                ? Double(store.value(sel)) / Double(store.value(parent))
                                : 0
                            infoItem(label: tr("Доля в родителе"), value: fmtPct(pct))
                        }

                        // «Только в облаке» всегда, даже 0 Б, фиолетовым
                        infoItem(label: tr("Только в облаке"), value: fmtBytes(sel.cloud), color: .cloudColor)

                        if isDropbox && sel.ign > 0 {
                            infoItem(label: tr("Не синхронизируется"), value: fmtBytes(sel.ign))
                            let inQuota = sel.size - sel.ign
                            infoItem(label: tr("В квоте Dropbox"), value: fmtBytes(inQuota))
                        }

                        infoItem(label: tr("Файлов"), value: formatCount(sel.files))
                        infoItem(label: tr("Папок"), value: formatCount(sel.dirs))
                        infoItem(label: tr("Последнее изменение"), value: fmtDate(sel.mtime))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .frame(height: 54)
            }
        }
    }

    private func infoItem(label: String, value: String, color: Color? = nil) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            Text(value)
                .fontWeight(.semibold)
                .font(.system(size: 13).monospacedDigit())  // системный шрифт, .monospacedDigit()
                .foregroundColor(color ?? .primary)
        }
    }

    private func formatCount(_ n: Int64) -> String {
        fmtCount(n)
    }

    // MARK: - HSplitView (48/52)

    private var mainSplit: some View {
        HSplitView {
            TreeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.panelBg)
                .frame(minWidth: 380, idealWidth: 610)

            // Правая панель: свои вкладки (как .tabs в эталоне) + контент по store.tab
            VStack(spacing: 0) {
                tabBar
                rightContent
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.panelBg)
            .frame(minWidth: 440, idealWidth: 670)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.windowBg)
    }

    // MARK: - Свои вкладки (как .tabs button в эталоне, без TabView)
    // Прижаты влево, отступ 8 pt, фон #f7f9fb / #1f232a

    private var tabBar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(AppStore.Tab.allCases, id: \.self) { tab in
                    tabButton(label: tabLabel(tab), tab: tab)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)
            .background(Color.panel2Bg)

            // Разделитель под всеми вкладками
            Rectangle()
                .fill(Color.lineColor)
                .frame(height: 1)
        }
    }

    private func tabLabel(_ tab: AppStore.Tab) -> String {
        switch tab {
        case .pie: tr("Диаграмма")
        case .details: tr("Детали")
        case .ext: tr("Расширения")
        case .age: tr("Возраст файлов")
        case .top: tr("Топ файлов")
        case .dups: tr("Дубли")
        }
    }

    private func tabButton(label: String, tab: AppStore.Tab) -> some View {
        Button(action: { store.tab = tab }) {
            Text(label)
                .font(.system(size: 13))
                .fontWeight(store.tab == tab ? .semibold : .regular)
                .foregroundColor(store.tab == tab ? .primary : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(store.tab == tab ? Color.panelBg : Color.clear)
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 7,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 7
                    )
                )
                .overlay(
                    Group {
                        if store.tab == tab {
                            UnevenRoundedRectangle(
                                topLeadingRadius: 7,
                                bottomLeadingRadius: 0,
                                bottomTrailingRadius: 0,
                                topTrailingRadius: 7
                            )
                            .stroke(Color.lineColor, lineWidth: 1)
                        }
                    }
                )
                .uiTag("tab:" + label)
        }
        .buttonStyle(.plain)
    }

    // Каждая вкладка займёт весь низ правой панели
    @ViewBuilder
    private var rightContent: some View {
        VStack(spacing: 0) {
            switch store.tab {
            case .pie:
                PieView()
            case .details:
                DetailsView()
            case .ext:
                ExtView()
            case .age:
                AgeView()
            case .top:
                TopView()
            case .dups:
                DupsView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Строка состояния (как .status в эталоне)

    private var statusBar: some View {
        HStack(spacing: 16) {
            // Путь выделенного (или выбранного в правой панели)
            Text(store.selected?.path ?? "")
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Кнопки «Показать в Finder» и «Скопировать путь»
            if let sel = store.selected {
                Button(tr("Показать в Finder")) {
                    let url = URL(fileURLWithPath: sel.path)
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.panelBg)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.lineColor, lineWidth: 1)
                )

                Button(tr("Скопировать путь")) {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(sel.path, forType: .string)
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.panelBg)
                .cornerRadius(6)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.lineColor, lineWidth: 1)
                )
            }

            // Мета-информация справа
            if let result = store.result {
                let meta = tr("Скан") + " \(result.scanned) · \(String(format: "%.1f", result.took)) " + tr("с")
                    + (result.errors > 0 ? " · " + tr("нет доступа") + ": \(result.errors)" : "")
                Text(meta)
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .font(.system(size: 12))
    }

    // MARK: - Оверлей скана

    private var scanOverlay: some View {
        Color.black.opacity(0.28)
            .edgesIgnoringSafeArea(.all)
            .overlay(
                VStack(spacing: 8) {
                    Text(tr("Сканирую ") + store.scanPath + tr("…"))
                        .fontWeight(.bold)
                    if store.progress.files > 0 {
                        Text(String(store.progress.files) + tr(" файлов · ") + "\(fmtBytes(store.progress.bytes)) · \(String(format: "%.0f", Date().timeIntervalSince1970)) " + tr("с"))
                            .foregroundColor(.secondary)
                    } else {
                        Text(tr("0 с"))
                            .foregroundColor(.secondary)
                    }
                    if !store.progress.cur.isEmpty {
                        Text(store.progress.cur)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.head)
                    }
                }
                .padding(26)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(nsColor: NSColor.windowBackgroundColor))
                )
                .shadow(radius: 8)
            )
    }
}

// MARK: - Расширение Color для дополнительных цветов

extension Color {
    /// Цвет «Только в облаке»: #6a4fd8, тёмная #9f8bff
    static let cloudColor = Color.dynamicColor(lightHex: "#6a4fd8", darkHex: "#9f8bff")

    /// Цвет линии разделителя: #dde2ea / #2c323c
    static let lineColor = Color.dynamicColor(lightHex: "#dde2ea", darkHex: "#2c323c")

    /// Фон предупреждения (stuck — жёлтый)
    static let warningBg = Color.dynamicColor(lightHex: "#fff3cd", darkHex: "#332701")
}

// MARK: - ModeHelpView: пояснение Размер vs На диске

struct ModeHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(tr("Размер и «На диске» — в чём разница"))
                .fontWeight(.bold)

            mdText(tr("**Размер** — сколько весят файлы: столько байт вы получите, если их скопировать. По нему считают квоту Dropbox и iCloud."))
                .font(.system(size: 12.5))

            mdText(tr("**На диске** — сколько места файлы реально занимают на этом маке. Обычно почти то же самое, но есть два исключения:"))
                .font(.system(size: 12.5))

            Text(tr("☁️ Файлы «только в облаке»: размер есть, а на диске — ноль."))
                .font(.system(size: 12.5))

            Text(tr("🧊 Разреженные файлы (например, диск Docker или виртуальной машины): размер может быть 460 ГБ, а занято 39 ГБ."))
                .font(.system(size: 12.5))

            Text(tr("Чтобы освободить место на маке, смотрите «На диске». Чтобы уложиться в тариф облака — «Размер»."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
        }
        .padding(16)
        .frame(width: 360)
    }
}