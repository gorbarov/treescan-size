Ты — исполнитель проекта TreeSize.app (мак-приложение на Swift). Рабочая папка — текущая (git-репозиторий проекта):
/path/to/treebars
Эталоны (только читать): /path/to/treebars/reference/treesize.py и /path/to/treebars/reference/template.html (это и есть «reference/...» из заданий).
Сначала прочитай AGENTS.md — там обязательные правила: сборка только `swift build -c release --disable-sandbox --scratch-path /tmp/ts-build`, файлы в `tools/` не трогать, `rm` запрещён, проверка — `tools/check_task.sh NN`.
Среда: macOS 15, Swift 6.2 (Command Line Tools, Xcode нет), платформа в Package.swift — macOS 14, swift-tools-version 5.9.
Перед ответом обязательно закоммить: `git add -A && git commit -m "Задание NN: …"` (без коммита задание не принимается). В конце ответь коротко: прошла ли проверка (приведи последние строки её вывода), какие файлы создал или изменил, что не получилось.

