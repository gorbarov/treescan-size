---
title: TreeSize для мака — нативное приложение
type: project
updated: 2026-09-24
sources: [docs/SPEC.md, docs/PLAN.md, reference/README.md]
agent: claude-code
---

# TreeSize.app

Мак-приложение «чем забит диск» на основе [reference](reference/README.md): сканер и действия на Swift, интерфейс — тот же HTML-отчёт в окне приложения. Строится «ради спортивного интереса» (CEO, 24.09.2026) силами дешёвых агентов по готовому плану.

- ТЗ — [docs/SPEC.md](docs/SPEC.md)
- План по этапам с проверками — [docs/PLAN.md](docs/PLAN.md)
- Правила для исполнителя — [AGENTS.md](AGENTS.md)
- Отчёт исполнителя — `docs/REPORT.md` (появится по ходу)

## Проверка

```bash
tools/make_fixture.sh /tmp/ts-fixture     # тестовая папка с неудобными случаями
python3 tools/compare.py /tmp/ts-fixture  # Swift против эталона на Python
```

## Статус

| Этап | Что | Исполнитель | Статус |
|---|---|---|---|
| 0 | ТЗ, план, фикстура, сравнение, мост в шаблоне | Claude (Opus) | готово 24.09.2026 |
| 1 | Сканер на Swift, `tscan` | агент на Sonnet | готово 24.09.2026: совпадает с эталоном на фикстуре, `~/Downloads` и всём Dropbox; 12,9 с против 11,8 с у Python |
| 2 | Окно, WKWebView, мост | DeepSeek через OpenCode или Sonnet — решает CEO | ждёт решения |
| 3 | .app, иконка, подпись | — | ждёт этапа 2 |

Сборка идёт без Xcode, только на Command Line Tools (Swift 6.2). Папки `.build/` и `build/` исключены из синхронизации Dropbox.
