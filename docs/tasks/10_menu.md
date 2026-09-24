# Задание 10. Контекстное меню, корзина, «не синхронизировать», поповер «Открыть…»

Прочитай docs/UI-SPEC.md, разделы 9 и 11. Эталон — `openMenu`, `doTrash`, `removeLocal`, `doIgnore`, `renderPlaces`, `runScan`.

- Одно меню `NodeMenu(node:)`. Навесить `.contextMenu` на строки дерева, таблицы «Детали», легенды диаграммы, топа и дублей. Для топа и дублей узел ищи по пути; если не нашёлся — меню по пути.
- Корзина и «не синхронизировать» — через функции из `FileActions.swift` (задание 02), с подтверждением `NSAlert` и откатом (`removeLocal` из задания 03).
- Поповер мест — из кнопки «📂 Открыть…» и ⌘O. Выбор папки — `NSOpenPanel`.

**Не проверяй корзину и «не синхронизировать» на реальных файлах. Их проверит CEO.** Можно проверить на `/tmp/ts-fixture`, если очень нужно, но не обязательно.

Проверка:
- сборка;
- `tools/check_task.sh 03` — OK;
- `tools/check_task.sh 10 --select /tmp/ts-fixture/docs` — снимок не сломался;
- `tools/check_task.sh 10p --places` — снимок поповера мест.

Подсказки по реализации:
- Меню: `.contextMenu { NodeMenu(node: node) }`; внутри — `Button`, `Divider`, для неактивного — `Button(...).disabled(true)`. Для `Table` — `.contextMenu(forSelectionType: Node.ID.self) { ids in ... }`.
- Подтверждение — синхронно через `NSAlert`: `alert.addButton(withTitle: "В корзину")`, `alert.addButton(withTitle: "Отмена")`, `alert.runModal() == .alertFirstButtonReturn`.
- Корзина в фоне: `Task.detached { let err = moveToTrash(path); await MainActor.run { if let err { undo(); показать NSAlert } } }`, где `undo` — замыкание из `store.removeLocal(node)`, вызванного **до** запуска фоновой задачи.
- Поповер: `.popover(isPresented: $store.showPlaces) { PlacesView() }` на кнопке «📂 Открыть…».
- Снимок: добавь режим `--places`, который рисует `PlacesView` отдельным снимком вместо окна (NSHostingView с `PlacesView` размером 460×520). Проверка: `tools/check_task.sh 10p --places`.
