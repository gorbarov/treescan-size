<p align="center">
  <img src="docs/screenshots/icon.png" width="128" alt="TreeScan Size icon">
</p>

<h1 align="center">TreeScan Size</h1>

<p align="center">
  <b>Что занимает место на Mac — видно по дереву папок с полосками размера.</b><br>
  Бесплатно, код открыт. Без сети и слежки. Понимает Dropbox, iCloud и OneDrive.
</p>

<p align="center">
  <a href="https://github.com/gorbarov/treescan-size/releases/latest"><img src="https://img.shields.io/github/v/release/gorbarov/treescan-size?label=download&color=2a78d6" alt="Download"></a>
  <img src="https://img.shields.io/badge/macOS-14%2B-lightgrey" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Apple%20Silicon-native-lightgrey" alt="Apple Silicon">
  <img src="https://img.shields.io/badge/SwiftUI-100%25-orange" alt="SwiftUI">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green" alt="MIT"></a>
  <img src="https://img.shields.io/badge/languages-9-blueviolet" alt="9 languages">
</p>

<p align="center">
  <a href="README.md">English</a> · <b>Русский</b> · <a href="README.es.md">Español</a> · <a href="README.de.md">Deutsch</a> · <a href="README.fr.md">Français</a> · <a href="README.pt-BR.md">Português</a> · <a href="README.ko.md">한국어</a> · <a href="README.zh-CN.md">简体中文</a> · <a href="README.ja.md">日本語</a>
</p>

<p align="center">
  <img src="docs/screenshots/pie-en.png" width="900" alt="TreeScan Size: folder tree with size bars and a chart">
</p>

---

## Зачем

Finder не расскажет, какие папки съели ваш диск. Большинство анализаторов диска для Mac рисуют кольца или мозаику прямоугольников. **TreeScan Size показывает то, что пользователи Windows знают по TreeSize:** обычное дерево папок, где у каждой строки полоска размера и доля в родительской папке. Пролистали вниз — и понятно, что чистить.

## Возможности

|  |  |
|---|---|
| 🌳 **Дерево с полосками размера** | У каждой папки размер и доля в родительской, самые большие сверху. Управление стрелками, клик в любом месте строки. |
| ⚡ **Живой скан** | Дерево заполняется прямо во время скана, прогресс-бар показывает процент от занятого на диске. Не нужно ждать, глядя на крутилку. |
| ☁️ **Понимает облака** | Файлы Dropbox, iCloud и OneDrive «только онлайн» отмечены: они входят в тариф облака, но не занимают места на Mac. Папку Dropbox можно исключить из синхронизации прямо из меню. |
| ⚖️ **«Размер» и «На диске»** | *Размер* — сколько весят файлы, по нему считают квоту облака. *На диске* — сколько они реально занимают на этом Mac. Диск Docker или виртуальной машины может «весить» 460 ГБ и занимать 39 ГБ — видны обе цифры. |
| 🔍 **Шесть вкладок** | Диаграмма, Детали, Расширения, Возраст файлов, Топ файлов, Дубли (кандидаты ищутся без скачивания облачных файлов). |
| 🛡️ **Безопасно и приватно** | Удаление только в Корзину и после подтверждения, системные папки защищены. Без сети, аналитики и аккаунтов. См. [PRIVACY.md](PRIVACY.md). |
| 🌍 **9 языков** | English, 简体中文, 日本語, 한국어, Deutsch, Español, Français, Português, Русский. Светлая и тёмная темы. |

## Скриншоты

| Живой скан | Топ файлов | Дубли |
|---|---|---|
| <img src="docs/screenshots/live-en.png" alt="Live scan with progress"> | <img src="docs/screenshots/top-en.png" alt="Top files in a folder"> | <img src="docs/screenshots/duplicates-en.png" alt="Duplicate candidates"> |

| Что сканировать? | Тёмная тема | «Размер» и «На диске» с пояснением |
|---|---|---|
| <img src="docs/screenshots/welcome-en.png" alt="Start screen"> | <img src="docs/screenshots/details-dark-en.png" alt="Details, dark theme"> | <img src="docs/screenshots/mode-help-en.png" alt="Size vs On disk help"> |

## Установка

Требуется **macOS 14 Sonoma или новее** на **Apple Silicon**.

1. Скачайте **TreeScan-Size.zip** из [Releases](https://github.com/gorbarov/treescan-size/releases/latest), распакуйте и перенесите приложение в «Программы».
2. Сборка **пока не нотаризована**, поэтому macOS блокирует первый запуск:
   - **macOS 15 и новее:** откройте приложение один раз, нажмите *Готово*, затем **Системные настройки → Конфиденциальность и безопасность → Всё равно открыть**.
   - **macOS 14:** щёлкните приложение правой кнопкой → **Открыть** → **Открыть**.
   - Или в Терминале: `xattr -dr com.apple.quarantine "/Applications/TreeScan Size.app"`
3. При первом запуске приложение запрашивает **Полный доступ к диску** — один переключатель в Системных настройках вместо десятка вопросов macOS про Рабочий стол, Документы, iCloud и данные других приложений. Можно отказаться: тогда защищённые папки помечаются 🔒 и не читаются.

### Сборка из исходного кода

```bash
git clone https://github.com/gorbarov/treescan-size && cd treescan-size
scripts/make_app.sh          # Command Line Tools are enough (Swift 5.9+), no Xcode needed
open "build/TreeScan Size.app"
```

## Сравнение с другими инструментами

| | TreeScan Size | DaisyDisk | GrandPerspective | OmniDiskSweeper | Disk Inventory X |
|---|---|---|---|---|---|
| Основной вид | дерево с полосками + диаграмма | кольцевая диаграмма | мозаика (treemap) | список в колонках | мозаика + список |
| Цена | бесплатно | платно | бесплатно (платно в App Store) | бесплатно | бесплатно |
| Исходный код | открытый, MIT | закрытый | открытый, GPL | закрытый | открытый, GPL |

Чего нет у других: отметка облачных файлов «только онлайн», исключение папки Dropbox из синхронизации прямо из меню, переключатель «Размер / На диске», живое дерево во время скана, поиск дублей без скачивания облачных файлов.

*На основе публичных описаний по состоянию на сентябрь 2026 — поправки приветствуются.*

## Как это сделано

TreeScan Size — это ещё и эксперимент. **Код написала дешёвая модель** DeepSeek V4 Flash, а Claude Opus был тимлидом: писал ТЗ, резал работу на ~25 небольших заданий с заранее посчитанными ответами, читал каждую рискованную строку. Эталоном служили Python-скрипт и HTML-отчёт ([reference/](reference/)).

Коротко, что выяснилось:
- Дешёвая модель хорошо идёт по проложенному пути: перенести логику по эталону, собрать интерфейс по скелету кода.
- Зелёных тестов мало: однажды она отключила защиту системных папок в меню Корзины, а все тесты проходили. Поймало только ревью кода.
- Тестовая папка на 500 файлов не покажет того, что видно на 2,9 миллиона: на настоящем диске одна вкладка рисовалась 9 минут. Это нашла проверка на реальном объёме, остальное — живой человек.

Вся история — задания, проверки, уроки — в [docs/FINDINGS.md](docs/FINDINGS.md) и [docs/RESEARCH.md](docs/RESEARCH.md) ; логи прогонов приложены к [релизу](https://github.com/gorbarov/treescan-size/releases/latest).

## Участие в проекте

Будем рады сообщениям об ошибках, переводам и вычитке носителями языка — см. [CONTRIBUTING.md](CONTRIBUTING.md).

## Лицензия и товарные знаки

[MIT](LICENSE). TreeScan Size сделан по мотивам TreeSize для Windows, но **не связан с JAM Software и не одобрен ею**. TreeSize — зарегистрированный товарный знак Joachim Marder e.K. (JAM Software). Dropbox, iCloud, OneDrive и macOS — товарные знаки соответствующих владельцев.
