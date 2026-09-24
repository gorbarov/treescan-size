# Задание 15. Разметка в плашках и подписях

После перевода интерфейса (задание 14) строки с разметкой `**жирный**` показываются как есть — со звёздочками. Пример: плашка Dropbox «**Dropbox quota counts «Size»**: …». Причина: `Text(tr("…"))` получает `String`, а SwiftUI разбирает markdown только у `LocalizedStringKey` или `AttributedString`.

Сделай:
1. В TreeSizeCore или TreeSizeApp — хелпер:
```swift
/// Текст интерфейса с разметкой **жирный** после перевода.
func mdText(_ s: String) -> Text {
    if let a = try? AttributedString(markdown: s, options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) { return Text(a) }
    return Text(s)
}
```
2. Найди все строки интерфейса, где в русском оригинале или переводе есть `**`: `grep -rn '\*\*' Sources/TreeSizeCore/L10n_*.swift Sources/TreeSizeApp`. Покажи их через `mdText(tr(...))` — плашка Dropbox, плашка «не удалось прочитать», подпись на вкладке «Дубли» и любые другие.
3. Больше ничего не меняй.

Проверка:
- `tools/check_task.sh 03`;
- снимок: `TREEBARS_LANG=en /tmp/ts-build/release/TreeSizeApp --root "/tmp/tbdemo/Users/alex/Library/CloudStorage/Dropbox" --snapshot /tmp/ts-build/snap_15.png --tab dups` — на снимке нет ни одной пары звёздочек `**`, вместо них жирный шрифт;
- то же с `TREEBARS_LANG=ru`.

Коммит «Задание 15: разметка в плашках», раздел в конце REPORT.md (только дописать).
