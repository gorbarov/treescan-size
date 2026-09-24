// Поповер мест — UI-SPEC раздел 11, как renderPlaces() в template.html
import SwiftUI
import TreeSizeCore

/// Поповер «Что просканировать» — кнопка «📂 Открыть…» и ⌘O
struct PlacesView: View {
    @EnvironmentObject var store: AppStore
    @State private var places: [Place]
    @State private var customPath: String = ""

    init() {
        self._places = State(initialValue: [])
    }

    init(places: [Place]) {
        self._places = State(initialValue: places)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок
            Text("Что просканировать")
                .fontWeight(.semibold)
                .padding(.horizontal, 8)
                .padding(.bottom, 8)

            // Список дисков и папок
            ScrollView {
                VStack(spacing: 0) {
                    // Диски
                    ForEach(places.filter { $0.kind == "disk" }, id: \.path) { place in
                        placeRow(place)
                    }

                    // Разделитель
                    if places.contains(where: { $0.kind == "disk" })
                        && places.contains(where: { $0.kind == "folder" }) {
                        Divider()
                            .padding(.vertical, 6)
                    }

                    // Папки
                    ForEach(places.filter { $0.kind == "folder" }, id: \.path) { place in
                        placeRow(place)
                    }
                }
            }

            // Подвал
            VStack(spacing: 8) {
                Divider()
                    .padding(.horizontal, 0)

                Button("Выбрать папку в Finder…") {
                    chooseFolder()
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.panel2Bg)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lineColor, lineWidth: 1))

                HStack(spacing: 6) {
                    TextField("или путь: ~/Movies, /Volumes/Диск", text: $customPath)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.panel2Bg)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lineColor, lineWidth: 1))

                    Button("Сканировать") {
                        let p = (customPath as NSString).expandingTildeInPath
                        store.showPlaces = false
                        store.scan(path: p)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.panel2Bg)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.lineColor, lineWidth: 1))
                }
            }
            .padding(.top, 6)
        }
        .padding(8)
        .onAppear {
            places = listPlaces()
        }
    }

    /// Одна строка места
    private func placeRow(_ place: Place) -> some View {
        let cur = store.result?.root ?? ""
        let isCurrent = place.path == cur

        return Button(action: {
            store.showPlaces = false
            store.scan(path: place.path)
        }) {
            Group {
                if place.kind == "disk" {
                    diskRow(place, isCurrent: isCurrent)
                } else {
                    folderRow(place, isCurrent: isCurrent)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(isCurrent ? Color.treeSelectionBg : Color.clear)
        .cornerRadius(8)
        .contentShape(Rectangle())
    }

    /// Строка диска: 💽, имя, «свободно X из Y», полоса занятости на всю ширину
    private func diskRow(_ place: Place, isCurrent: Bool) -> some View {
        let total = place.total ?? 1
        let used = total - (place.free ?? 0)
        let pct = total > 0 ? Double(used) / Double(total) : 0.0

        return VStack(spacing: 3) {
            HStack(spacing: 10) {
                Text("💽")
                    .font(.system(size: 16))
                Text(place.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("свободно \(fmtBytes(place.free ?? 0)) из \(fmtBytes(place.total ?? 0))")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.panelBg)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(pct > 0.9 ? Color(hex: "#d03b3b") : Color.accentLinkColor)
                        .frame(width: geo.size.width * pct)
                }
            }
            .frame(height: 8)
        }
    }

    /// Строка папки: 📁, имя, путь серым с ~
    private func folderRow(_ place: Place, isCurrent: Bool) -> some View {
        HStack(spacing: 10) {
            Text("📁")
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 0) {
                Text(place.name)
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(place.path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Выбрать папку через NSOpenPanel
    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.showPlaces = false
        store.scan(path: url.path)
    }
}

// MARK: - Режим снимка Places для проверки

/// Создать NSHostingView с PlacesView размером 460×520
@MainActor
func snapPlacesView(store: AppStore) -> NSHostingView<AnyView> {
    let view = PlacesView().environmentObject(store)
    let hosting = NSHostingView(rootView: AnyView(view))
    hosting.frame = NSRect(x: 0, y: 0, width: 460, height: 520)
    return hosting
}