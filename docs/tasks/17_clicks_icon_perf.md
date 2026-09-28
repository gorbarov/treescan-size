# Задание 17. Клики в дереве, иконка, тормоза после скана

По живой проверке CEO: клик по стрелке или иконке папки не раскрывает её; иконка приложения не похожа на логотип из HTML; на большом скане всё подвисает.

## 1. Клики в дереве (`Sources/TreeSizeApp/TreeView.swift`)

- Клик по стрелке ▸/▾ **или** по иконке папки — раскрыть/свернуть (`store.toggle(node)`) и выделить строку. Для этого стрелку и `iconView` оберни в одну область с `.contentShape(Rectangle())` и `.onTapGesture { store.select(node); store.toggle(node) }` (только если у папки есть дети).
- Одинарный клик по остальной строке — выделить **сразу**, без задержки. Сейчас `.onTapGesture(count: 2)` стоит перед `.onTapGesture(count: 1)`, и SwiftUI ждёт, не будет ли второго клика. Сделай так:

```swift
TreeRowView(...)
    .onTapGesture(count: 2) { if node.kind == .dir && node.children?.isEmpty == false { store.toggle(node) } }
    .simultaneousGesture(TapGesture().onEnded { store.select(node) })
```

## 2. Иконка (`scripts/make_icon.swift`)

Логотип в HTML (`reference`: `.logo` в template.html) — сетка: колонки 9 и 5, строки 9 и 5, зазор 2. Синий занимает обе строки левой колонки (9 × 16). **Жёлтый — правая колонка, верхняя строка: 5 в ширину × 9 в высоту.** Оранжевый — правая колонка, нижняя строка: 5 × 5. Сейчас жёлтый нарисован 5 × 5, поэтому между ним и оранжевым дыра. Исправь `r2`: высота `c1w` (9 единиц), нижний край на `oy + c2w + gap`. Скругление 2 единицы оставь. Пересобери `scripts/make_app.sh`, проверь `build/icon_1024.png` — жёлтый высокий, оранжевый маленький квадрат под ним, зазоры 2 единицы везде одинаковые.

## 3. Тормоза (`Sources/TreeSizeApp/AppStore.swift`)

1. **Модель собирать не на главном потоке.** Сейчас `ScanResult(data: data)` вызывается внутри `MainActor.run`. Перенеси в фоновую задачу:

```swift
Task.detached {
    let data = scanRoot(path, options: options, scanner: scanner)
    let built = ScanResult(data: data)          // тяжёлое — здесь, в фоне
    await MainActor.run {
        guard let store = weakSelf else { return }
        store.result = built
        ...
    }
}
```

2. **Цикл прогресса должен заканчиваться.** Сейчас `return` внутри `MainActor.run` выходит только из замыкания, цикл `while true` живёт вечно, и каждый новый скан добавляет ещё один. Сделай так, чтобы `MainActor.run` возвращал `Bool` (идёт ли скан), и при `false` делай `break`.

3. **Кэш отсортированных детей.** `children(_:)` сортирует детей при каждом вызове, а `visibleRows` вызывает его для каждой раскрытой папки при каждой перерисовке. Заведи `private var childrenCache: [Int: [Node]] = [:]` (ключ — `node.id`), заполняй в `children(_:)`, очищай при смене `result`, при смене `mode` и после любого удаления или изменения узлов (`removeLocal`, пометка «не синхронизировать»).

## Проверка

- `tools/check_task.sh 03` — OK.
- `swift run -c release --disable-sandbox --scratch-path /tmp/ts-build TreeSizeApp --root /tmp/ts-fixture --uitest` — если этот режим умеет клик по строке, пусть проходит как раньше.
- Снимок: `--root /tmp/ts-fixture --snapshot /tmp/ts-build/snap_17.png --tab pie` — дерево как раньше.
- Иконка: `build/icon_1024.png` — пропорции как в HTML.

Коммит «Задание 17: клики, иконка, тормоза», раздел в конце REPORT.md (только дописать).
