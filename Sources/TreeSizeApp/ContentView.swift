// Каркас ContentView — UI-SPEC раздел 4
import SwiftUI
import TreeSizeCore

/// Главный экран: панель инструментов, сведения, HSplitView, строка состояния, оверлей скана
struct ContentView: View {
    @EnvironmentObject var store: AppStore

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                toolbar
                    .background(Color(nsColor: .windowBackgroundColor))
                Divider()
                infoBar
                    .background(Color(nsColor: .controlBackgroundColor))
                Divider()
                mainSplit
                Divider()
                statusBar
                    .background(Color(nsColor: .controlBackgroundColor))
            }

            // Оверлей скана с прогрессом
            if store.isScanning {
                scanOverlay
            }
        }
    }

    // MARK: - Панель инструментов

    private var toolbar: some View {
        HStack(spacing: 14) {
            // Логотип из трёх квадратов
            logo

            // «TreeSize для мака»
            HStack(spacing: 0) {
                Text("TreeSize")
                    .fontWeight(.bold)
                    .font(.system(size: 15))
                Text(" для мака")
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

            // Кнопки
            Button("📂 Открыть…") {
                store.showPlaces = true
            }
            .buttonStyle(.borderless)

            Button("⟳ Пересканировать") {
                store.rescan()
            }
            .buttonStyle(.borderless)

            // Сегмент Размер | На диске — как в макете
            Picker("", selection: $store.mode) {
                Text("Размер").tag(AppStore.SizeMode.size)
                Text("На диске").tag(AppStore.SizeMode.alloc)
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color(nsColor: NSColor.windowBackgroundColor))
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

    // MARK: - Строка сведений (как renderInfo в эталоне)

    /// Имя для отображения: у корня — последний сегмент пути, у остальных — displayName
    private func displayName(for node: Node) -> String {
        if node.parent == nil {
            // Корень: последний сегмент пути
            let path = node.name  // это root-путь
            return (path as NSString).lastPathComponent
        }
        return node.displayName
    }

    /// Dropbox-корень?
    private var isDropbox: Bool {
        guard let root = store.result?.root else { return false }
        return root.contains("/CloudStorage/Dropbox")
    }

    private var infoBar: some View {
        Group {
            if let sel = store.selected {
                // Как renderInfo в эталоне: display:flex, gap:4px 22px, padding:8px 16px, align-items:baseline
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 22) {
                        // Имя жирным — первый элемент без подписи
                        Text(displayName(for: sel))
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .frame(maxWidth: 40, alignment: .leading)
                            .fixedSize()

                        // Размер
                        infoItem(label: "Размер", value: fmtBytes(store.value(sel)))

                        // На диске
                        infoItem(label: "На диске", value: fmtBytes(sel.alloc))

                        // Доля в родителе (не у корня)
                        if let parent = sel.parent {
                            let pct = store.value(parent) > 0
                                ? Double(store.value(sel)) / Double(store.value(parent))
                                : 0
                            infoItem(label: "Доля в родителе", value: fmtPct(pct))
                        }

                        // Только в облаке (всегда, фиолетовым)
                        if sel.cloud > 0 {
                            infoItem(label: "Только в облаке", value: fmtBytes(sel.cloud), color: .purple)
                        }

                        // Dropbox-поля: только если корень в Dropbox и ign > 0
                        if isDropbox && sel.ign > 0 {
                            infoItem(label: "Не синхронизируется", value: fmtBytes(sel.ign))
                            let inQuota = sel.size - sel.ign
                            infoItem(label: "В квоте Dropbox", value: fmtBytes(inQuota))
                        }

                        // Файлов
                        infoItem(label: "Файлов", value: "\(sel.files)")

                        // Папок
                        infoItem(label: "Папок", value: "\(sel.dirs)")

                        // Последнее изменение
                        infoItem(label: "Последнее изменение", value: fmtDate(sel.mtime))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .frame(height: 54) // фикс. высота как в шаблоне
            }
        }
    }

    /// Элемент строки сведений: подпись серым 13px, значение жирным
    private func infoItem(label: String, value: String, color: Color? = nil) -> some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundColor(.secondary)
                .font(.system(size: 13))
            Text(value)
                .fontWeight(.semibold)
                .font(.system(.body, design: .monospaced).monospacedDigit())
                .foregroundColor(color ?? .primary)
        }
    }

    // MARK: - HSplitView (48/52)

    private var mainSplit: some View {
        HSplitView {
            // Левая панель — дерево (задание 05)
            TreeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(minWidth: 380, idealWidth: 610)

            // Правая панель — вкладки (заглушки)
            TabView {
                Text("Диаграмма — задание 06")
                    .tabItem { Text("Диаграмма") }
                    .tag(AppStore.Tab.pie)
                Text("Детали — задание 07")
                    .tabItem { Text("Детали") }
                    .tag(AppStore.Tab.details)
                Text("Расширения — задание 08")
                    .tabItem { Text("Расширения") }
                    .tag(AppStore.Tab.ext)
                Text("Возраст файлов — задание 08")
                    .tabItem { Text("Возраст файлов") }
                    .tag(AppStore.Tab.age)
                Text("Топ файлов — задание 08")
                    .tabItem { Text("Топ файлов") }
                    .tag(AppStore.Tab.top)
                Text("Дубли — задание 08")
                    .tabItem { Text("Дубли") }
                    .tag(AppStore.Tab.dups)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .frame(minWidth: 440, idealWidth: 670)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Строка состояния

    private var statusBar: some View {
        HStack(spacing: 16) {
            // Путь выделенного
            Text(store.selected?.path ?? "")
                .foregroundColor(.primary)
                .lineLimit(1)
                .truncationMode(.head)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Справа: «Скан … · … с · нет доступа: N»
            if let result = store.result {
                let meta = "Скан \(result.scanned) · \(String(format: "%.1f", result.took)) с"
                    + (result.errors > 0 ? " · нет доступа: \(result.errors)" : "")
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
                    Text("Сканирую \(store.scanPath)…")
                        .fontWeight(.bold)
                    if store.progress.files > 0 {
                        Text("\(store.progress.files) файлов · \(fmtBytes(store.progress.bytes)) · \(String(format: "%.0f", Date().timeIntervalSince1970)) с")
                            .foregroundColor(.secondary)
                    } else {
                        Text("0 с")
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