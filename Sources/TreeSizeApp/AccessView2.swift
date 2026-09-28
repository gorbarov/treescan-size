// Второй вариант диалога доступа (после «Открыть настройки») — Задание 20б
import SwiftUI
import TreeSizeCore

/// Второй вариант диалога доступа: показывается, если доступа нет и `access.asked == true`.
/// Содержит путь к бандлу, значок для перетаскивания, кнопки: Открыть настройки, Перезапустить, Продолжить без доступа.
struct AccessView2: View {
    @Binding var showAccessSheet: Bool
    @State private var restartShown = false
    /// Если true, кнопка «Продолжить без доступа» неактивна (режим снимка)
    public var isSnapshot: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок
            Text(tr("Доступ пока не включён для этой копии {app}"))
                .fontWeight(.bold)
                .font(.system(size: 17))
                .padding(.bottom, 4)

            // Текст-пояснение
            Text(tr("macOS выдаёт доступ конкретной копии приложения. В списке «Полный доступ к диску» должна быть включена именно эта:"))
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Путь к бандлу моноширинным мелким шрифтом
            Text(Bundle.main.bundlePath)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(8)
                .background(Color.panel2Bg)
                .cornerRadius(6)

            HStack(spacing: 8) {
                Text(tr("Если в списке другая копия или её нет — перетащите значок ниже в список или нажмите «+»."))
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Значок приложения 64×64 с перетаскиванием
            iconDragView

            // Кнопки
            VStack(spacing: 10) {
                Button(action: {
                    UserDefaults.standard.set(true, forKey: "access.asked")
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                        NSWorkspace.shared.open(url)
                    }
                    restartShown = true
                }) {
                    Text(tr("Открыть настройки"))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                if restartShown {
                    Button(action: {
                        let url = Bundle.main.bundleURL
                        let cfg = NSWorkspace.OpenConfiguration()
                        cfg.createsNewApplicationInstance = true
                        NSWorkspace.shared.openApplication(at: url, configuration: cfg) { _, _ in
                            DispatchQueue.main.async { NSApp.terminate(nil) }
                        }
                    }) {
                        Text(tr("Перезапустить {app}"))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                Button(action: {
                    UserDefaults.standard.set(true, forKey: "access.skip")
                    if !isSnapshot {
                        showAccessSheet = false
                    }
                }) {
                    Text(tr("Продолжить без доступа"))
                        .frame(maxWidth: .infinity)
                }
                .disabled(isSnapshot)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .padding(24)
        .frame(width: 520, height: 420)
    }

    /// Значок приложения, который можно перетащить в список настроек
    private var iconDragView: some View {
        HStack {
            Spacer()
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 64, height: 64)
                    .onDrag { NSItemProvider(object: Bundle.main.bundleURL as NSURL) }
            }
            Spacer()
        }
        .padding(8)
        .background(Color.panel2Bg)
        .cornerRadius(8)
    }
}