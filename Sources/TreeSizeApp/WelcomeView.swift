// Стартовый экран вместо пустого окна — Задание 20б
import SwiftUI
import TreeSizeCore

/// Стартовый экран, когда нет результата скана и скан не идёт.
struct WelcomeView: View {
    @EnvironmentObject var store: AppStore

    /// Статически загруженные места (диски и папки)
    @State private var places: [Place] = []

    /// Занято / всего на системном томе
    @State private var dataUsed: Int64 = 0
    @State private var dataTotal: Int64 = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Лого (как в шапке, 48 pt)
                logo
                    .padding(.top, 32)

                // Заголовок
                Text(tr("Что просканировать?"))
                    .font(.system(size: 24, weight: .bold))

                // Основная кнопка — весь диск
                mainDiskButton
                    .padding(.horizontal, 32)

                // Разделитель
                Divider()
                    .padding(.horizontal, 40)

                // Список мест
                placesList
                    .padding(.horizontal, 32)

                // Кнопка «Выбрать другую папку…»
                Button(tr("Выбрать другую папку…")) {
                    chooseFolder()
                }
                .buttonStyle(.plain)
                .font(.system(size: 13))
                .foregroundColor(.accentLinkColor)
                .padding(.top, 4)
                .padding(.bottom, 40)
            }
            .frame(maxWidth: 500)
            .frame(maxWidth: .infinity)
        }
        .background(Color.windowBg)
        .onAppear {
            places = listPlaces()
            // statfs /System/Volumes/Data
            var st = statfs()
            if statfs("/System/Volumes/Data", &st) == 0 {
                let blocks = Int64(st.f_blocks - st.f_bfree)
                let total = Int64(st.f_blocks)
                let bsize = Int64(st.f_bsize)
                dataUsed = blocks * bsize
                dataTotal = total * bsize
            }
        }
    }

    // MARK: - Логотип (48 pt, как в шапке)

    private var logo: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(red: 0x2a/255, green: 0x78/255, blue: 0xd6/255))
                .frame(width: 36, height: 60)
            VStack(spacing: 6) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0xed/255, green: 0xa1/255, blue: 0x00/255))
                    .frame(width: 20, height: 27)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0xeb/255, green: 0x68/255, blue: 0x34/255))
                    .frame(width: 20, height: 27)
            }
        }
    }

    // MARK: - Кнопка «Весь диск — Macintosh HD»

    private var mainDiskButton: some View {
        Button(action: {
            store.showPlaces = false
            store.scan(path: "/System/Volumes/Data")
        }) {
            VStack(spacing: 6) {
                HStack(spacing: 10) {
                    Text("💽")
                        .font(.system(size: 24))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(tr("Весь диск — Macintosh HD"))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        if dataTotal > 0 {
                            Text(tr("занято ") + fmtBytes(dataUsed) + tr(" из ") + fmtBytes(dataTotal))
                                .font(.system(size: 13))
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)

                // Полоса занятости
                if dataTotal > 0 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.panelBg)
                            let pct = Double(dataUsed) / Double(dataTotal)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(pct > 0.9 ? Color(hex: "#d03b3b") : Color.accentLinkColor)
                                .frame(width: geo.size.width * pct)
                        }
                        .frame(height: 8)
                    }
                    .frame(height: 8)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .background(Color.panelBg)
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lineColor, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Список мест

    private var placesList: some View {
        let filteredDisks = places.filter { $0.kind == "disk" && $0.path != "/System/Volumes/Data" }
        let filteredFolders = places.filter { $0.kind == "folder" }
        return VStack(spacing: 4) {
            // Внешние диски (без /System/Volumes/Data — он в большой кнопке)
            ForEach(filteredDisks, id: \.path) { place in
                placeRow(place)
            }

            // Разделитель
            if !filteredDisks.isEmpty && !filteredFolders.isEmpty {
                Divider()
            }

            // Папки
            ForEach(filteredFolders, id: \.path) { place in
                placeRow(place)
            }
        }
        .background(Color.panelBg)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.lineColor, lineWidth: 1))
    }

    private func placeRow(_ place: Place) -> some View {
        Button(action: {
            store.showPlaces = false
            store.scan(path: place.path)
        }) {
            if place.kind == "disk" {
                diskRow(place)
            } else {
                folderRow(place)
            }
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    private func diskRow(_ place: Place) -> some View {
        let total = place.total ?? 1
        let used = total - (place.free ?? 0)
        let pct = total > 0 ? Double(used) / Double(total) : 0.0

        return VStack(spacing: 3) {
            HStack(spacing: 10) {
                Text("💽")
                    .font(.system(size: 16))
                Text(tr(place.name))
                    .fontWeight(.semibold)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(tr("свободно ") + fmtBytes(place.free ?? 0) + tr(" из ") + fmtBytes(place.total ?? 0))
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

    private func folderRow(_ place: Place) -> some View {
        HStack(spacing: 10) {
            Text("📁")
                .font(.system(size: 16))
            VStack(alignment: .leading, spacing: 0) {
                Text(tr(place.name))
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

    // MARK: - Выбор папки

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        store.scan(path: url.path)
    }
}