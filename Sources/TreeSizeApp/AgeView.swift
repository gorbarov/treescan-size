// Возраст файлов — UI-SPEC раздел 8, как renderAge() в template.html
import SwiftUI
import TreeSizeCore

struct AgeView: View {
    @EnvironmentObject var store: AppStore

    private var buckets: [AgeBucket] {
        store.result?.age ?? []
    }

    private var totalSize: Int64 {
        buckets.reduce(0) { $0 + $1.size }
    }

    private var maxSize: Int64 {
        buckets.map(\.size).max() ?? 1
    }

    var body: some View {
        VStack(spacing: 0) {
            // Подпись (как #ageNote в эталоне)
            Text("Распределение по дате последнего изменения файла, по всему скану. Старое и большое — первые кандидаты в архив.")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.panelBg)

            Divider()

            if !buckets.isEmpty {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(buckets, id: \.label) { bucket in
                            ageRow(bucket: bucket)
                            Divider()
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .background(Color.panelBg)
    }

    private func ageRow(bucket: AgeBucket) -> some View {
        let pct = maxSize > 0 ? Double(bucket.size) / Double(maxSize) : 0.0
        let totalPct = totalSize > 0 ? Double(bucket.size) / Double(totalSize) : 0.0

        return HStack(spacing: 14) {
            Text(bucket.label)
                .font(.system(size: 13))
                .fixedSize()
                .frame(minWidth: 90, alignment: .leading)

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#e6eaf0"))
                    .frame(height: 22)

                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(hex: "#2a78d6"))
                    .frame(width: max(0, 200 * pct), height: 22)
            }
            .frame(maxWidth: .infinity)

            Text(fmtBytes(bucket.size))
                .font(.system(size: 13, weight: .semibold).monospacedDigit())
                .fixedSize()
                .frame(minWidth: 70, alignment: .trailing)

            Text("\(fmtPct(totalPct)) · \(plural(bucket.count, "файл", "файла", "файлов"))")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize()
                .frame(minWidth: 120, alignment: .leading)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}