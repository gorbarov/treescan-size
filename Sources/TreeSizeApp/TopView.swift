// Топ файлов — UI-SPEC раздел 8, как renderTop() в template.html
import SwiftUI
import TreeSizeCore

struct TopView: View {
    @EnvironmentObject var store: AppStore

    private var allTop: [TopFile] {
        store.result?.top ?? []
    }

    private var filteredTop: [TopFile] {
        guard let dir = store.viewDir else { return [] }
        guard dir.parent != nil else { return allTop }
        let vp = dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
        return allTop.filter { $0.path.hasPrefix(vp) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как #topNote в эталоне)
            if let view = store.viewDir {
                if view.parent != nil {
                    Text("**\(nf(Int64(filteredTop.count)))** из \(nf(Int64(allTop.count))) крупнейших файлов скана лежат в «\(view.name)».")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                } else {
                    Text("\(nf(Int64(allTop.count))) крупнейших файлов. Выберите папку в дереве, чтобы оставить только её файлы.")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                }
            }

            Divider()

            if !allTop.isEmpty {
                topTable
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Таблица топа

    private var topTable: some View {
        let vp = store.viewDir?.path ?? ""
        let cut = vp.hasSuffix("/") ? vp.count : vp.count + 1

        return ScrollView(.vertical) {
            VStack(spacing: 0) {
                // Шапка
                HStack(spacing: 0) {
                    Text("#")
                        .frame(width: 30, alignment: .trailing)
                    Text("Файл")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Размер")
                        .frame(width: 80, alignment: .trailing)
                    Text("На диске")
                        .frame(width: 80, alignment: .trailing)
                    Text("Изменён")
                        .frame(width: 76, alignment: .trailing)
                    Text("")
                        .frame(width: 24)
                }
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.panel2Bg)

                Divider()

                ForEach(Array(filteredTop.enumerated()), id: \.offset) { i, top in
                    topRow(top: top, index: i, cut: cut)
                    Divider()
                }
            }
        }
    }

    @ViewBuilder
    private func topRow(top: TopFile, index: Int, cut: Int) -> some View {
        let path = top.path
        let slashIdx = path.lastIndex(of: "/") ?? path.startIndex
        let fileName = slashIdx < path.endIndex ? String(path[path.index(after: slashIdx)...]) : path

        // Путь относительно viewDir — как p.slice(cut, slash) в эталоне
        let relPath: String = {
            guard cut < path.count else { return "." }
            let fromCut = String(path.dropFirst(cut))
            if let lastSlash = fromCut.lastIndex(of: "/") {
                return String(fromCut[..<lastSlash])
            }
            return fromCut.isEmpty ? "." : fromCut
        }()

        HStack(spacing: 0) {
            Text("\(index + 1)")
                .font(.system(.body).monospacedDigit())
                .foregroundColor(.secondary)
                .frame(width: 30, alignment: .trailing)

            // Имя + папка
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                    Text(fileName)
                        .fontWeight(.bold)
                        .font(.system(size: 13))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    if top.cloud > 0 {
                        Text("☁")
                            .font(.system(size: 11))
                            .foregroundColor(.cloudColor)
                    }
                }

                Text(relPath)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(fmtBytes(top.size))
                .fontWeight(.bold)
                .font(.system(.body).monospacedDigit())
                .frame(width: 80, alignment: .trailing)

            Text(fmtBytes(top.alloc))
                .font(.system(.body).monospacedDigit())
                .frame(width: 80, alignment: .trailing)

            Text(fmtDate(top.mtime))
                .font(.system(.body).monospacedDigit())
                .frame(width: 76, alignment: .trailing)

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(top.path, forType: .string)
            }) {
                Text("⧉")
                    .font(.system(size: 12))
                    .foregroundColor(.faintColor)
            }
            .buttonStyle(.plain)
            .frame(width: 24)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
    }

    // MARK: - Помощники

    private func nf(_ n: Int64) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "ru-RU")
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}