// Дубли — UI-SPEC раздел 8, как renderDup() в template.html
import SwiftUI
import TreeSizeCore

struct DupsView: View {
    @EnvironmentObject var store: AppStore

    private var allDups: [DupGroup] {
        store.result?.dups ?? []
    }

    private var filteredDups: [DupGroup] {
        guard let dir = store.viewDir else { return [] }
        guard dir.parent != nil else { return allDups }
        let vp = dir.path.hasSuffix("/") ? dir.path : dir.path + "/"
        return allDups.filter { group in
            group.paths.contains { $0.hasPrefix(vp) }
        }
    }

    private var wasteSize: Int64 {
        filteredDups.reduce(0) { $0 + $1.size * Int64($1.paths.count - 1) }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как #dupNote в эталоне)
            if let dupMin = store.result?.dupMin {
                if filteredDups.count < allDups.count {
                    Text("Файлы от \(fmtBytes(dupMin)) с одинаковым размером и расширением. Содержимое не сверялось, чтобы не скачивать облачные файлы, поэтому **это кандидаты, а не доказанные дубли**. Если все окажутся копиями, освободится до **\(fmtBytes(wasteSize))** (\(formatCount(Int64(filteredDups.count))) групп, из \(formatCount(Int64(allDups.count))) по всему скану).")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                } else {
                    Text("Файлы от \(fmtBytes(dupMin)) с одинаковым размером и расширением. Содержимое не сверялось, чтобы не скачивать облачные файлы, поэтому **это кандидаты, а не доказанные дубли**. Если все окажутся копиями, освободится до **\(fmtBytes(wasteSize))** (\(formatCount(Int64(filteredDups.count))) групп).")
                        .font(.system(size: 13))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.panelBg)
                }
            }

            Divider()

            // Список групп дублей (как #dup в эталоне)
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    if filteredDups.isEmpty {
                        Text("Кандидатов в дубли не нашлось.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ForEach(filteredDups.indices, id: \.self) { idx in
                            dupGroupView(group: filteredDups[idx])
                            Divider()
                        }
                    }
                }
            }
        }
        .background(Color.panelBg)
    }

    // MARK: - Одна группа дублей (как .dup в эталоне)

    private func dupGroupView(group: DupGroup) -> some View {
        let waste = group.size * Int64(group.paths.count - 1)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 12) {
                Text(fmtBytes(group.size))
                    .font(.system(size: 13, weight: .bold).monospacedDigit())

                Text("× \(group.paths.count) — лишних \(fmtBytes(waste))")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)

            ForEach(group.paths, id: \.self) { path in
                HStack(spacing: 4) {
                    Text(path)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(path, forType: .string)
                    }) {
                        Text("⧉")
                            .font(.system(size: 12))
                            .foregroundColor(.faintColor)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.leading, 18)
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 14)
    }

    // MARK: - Помощники

    private func formatCount(_ n: Int64) -> String {
        let nf = NumberFormatter()
        nf.numberStyle = .decimal
        nf.locale = Locale(identifier: "ru-RU")
        return nf.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}