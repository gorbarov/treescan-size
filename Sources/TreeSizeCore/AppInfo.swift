// Видимое имя приложения, bundleID и версия — одна константа.
// Всё, что видит пользователь (шапка, заголовок окна, «О программе»),
// берётся отсюда. Внутренние имена модулей и целей не трогать.
public enum AppInfo {
    public static let name = "TreeScan Size"                       // видимое имя — меняется только здесь
    public static let bundleID = "io.github.gorbarov.treescansize"
    public static let version = "0.1.0"
}