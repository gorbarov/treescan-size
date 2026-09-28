// Окно запроса полного доступа к диску — Задание 19
import SwiftUI
import TreeSizeCore

struct AccessView: View {
    @Binding var showAccessSheet: Bool
    @State private var restartShown = false
    /// Если true, кнопка «Продолжить без доступа» неактивна (режим снимка)
    public var isSnapshot: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Заголовок жирным 17 pt
            Text(tr("Дайте {app} полный доступ к диску"))
                .fontWeight(.bold)
                .font(.system(size: 17))
                .padding(.bottom, 4)

            // Текст-пояснение
            Text(tr("Без него macOS будет спрашивать разрешение на каждую защищённую папку: Рабочий стол, Документы, Загрузки, iCloud, данные других приложений. С полным доступом — ни одного вопроса и честный размер всего диска."))
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)

            // Нумерованный список шагов
            VStack(alignment: .leading, spacing: 6) {
                Text(tr("1. Нажмите «Открыть настройки»."))
                    .font(.system(size: 13))
                Text(tr("2. Включите {app} в списке «Полный доступ к диску» (если его нет — нажмите «+» и выберите {app} в Программах)."))
                    .font(.system(size: 13))
                Text(tr("3. Перезапустите {app}."))
                    .font(.system(size: 13))
            }
            .padding(.leading, 8)

            // Мелкий серый текст
            Text(tr("{app} ничего не отправляет в сеть и удаляет только в Корзину, после подтверждения."))
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            // Кнопки
            VStack(spacing: 10) {
                // Основная кнопка
                Button(action: {
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

                // Вторичная кнопка — неактивна в режиме снимка
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

                // Кнопка перезапуска, появляется после нажатия «Открыть настройки»
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
            }
        }
        .padding(24)
        .frame(width: 520, height: 380)
    }
}