// Английский словарь переводов (интерфейс)
extension L10n {
    static let en: [String: String] = [
        // MARK: - Общие
        " для мака": " for Mac",
        "📂 Открыть…": "📂 Open…",
        "⟳ Пересканировать": "⟳ Rescan",
        "Размер": "Size",
        "На диске": "On disk",
        "Показать в Finder": "Show in Finder",
        "Скопировать путь": "Copy path",
        "Отмена": "Cancel",
        "×": "×",

        // MARK: - Dropbox-баннер
        "☁️ **Квоту Dropbox считают по «Размеру»**: файлы «только онлайн» на маке не занимают места, но в тариф входят. Фиолетовым — сколько лежит только в облаке. Папки с пометкой «⊘ не синхр.» лежат только на этом маке и в квоту не входят. Общие папки считаются в квоту каждого участника.":
            "☁️ **Dropbox quota counts “Size”**: files marked “online only” take no space on Mac but count toward your plan. Purple indicates cloud-only data. Folders marked “⊘ not synced” exist only on this Mac and don't count toward quota. Shared folders count toward each member's quota.",

        // MARK: - Stuck-баннер (с подстановками)
        "⚠️ **папку прочитать не удалось**: облако не ответило за отведённое время, их размер не учтён. ":
            "⚠️ **folder could not be read**: the cloud didn't respond in time, its size wasn't counted. ",
        "⚠️ **папки прочитать не удалось**: облако не ответило за отведённое время, их размер не учтён. ":
            "⚠️ **folders could not be read**: the cloud didn't respond in time, their sizes weren't counted. ",
        "⚠️ **папок прочитать не удалось**: облако не ответило за отведённое время, их размер не учтён. ":
            "⚠️ **folders could not be read**: the cloud didn't respond in time, their sizes weren't counted. ",
        " и другие": " and others",

        // MARK: - Info bar
        "Доля в родителе": "Share in parent",
        "Только в облаке": "Only in cloud",
        "Не синхронизируется": "Not syncing",
        "В квоте Dropbox": "In Dropbox quota",
        "Файлов": "Files",
        "Папок": "Folders",
        "Последнее изменение": "Last modified",

        // MARK: - Табы
        "Диаграмма": "Chart",
        "Детали": "Details",
        "Расширения": "Extensions",
        "Возраст файлов": "File age",
        "Топ файлов": "Top files",
        "Дубли": "Duplicates",

        // MARK: - Строка состояния
        "Скан": "Scan",
        "нет доступа": "no access",
        "с": "s",

        // MARK: - Оверлей скана
        "Сканирую ": "Scanning ",
        "…": "…",
        " файлов · ": " files · ",
        "0 с": "0 s",

        // MARK: - Details
        "Пусто": "Empty",
        "Имя": "Name",
        "Изменено": "Modified",
        "% от родителя": "% of parent",

        // MARK: - Ext
        "Типы файлов по всему скану.": "File types across the entire scan.",
        "Расширение": "Extension",
        "(без расширения)": "(no extension)",
        "Тип": "Type",
        "Доля": "Share",

        // MARK: - Top
        "Изменён": "Modified",
        "Файл": "File",
        " крупнейших файлов скана лежат в «": " largest scan files are in “",
        "».": "”.",
        " крупнейших файлов. Выберите папку в дереве, чтобы оставить только её файлы.": " largest files. Select a folder in the tree to filter by it.",

        // MARK: - Dups
        "Файлы от ": "Files from ",
        " с одинаковым размером и расширением. Содержимое не сверялось, чтобы не скачивать облачные файлы, поэтому **это кандидаты, а не доказанные дубли**. Если все окажутся копиями, освободится до **":
            " with the same size and extension. Contents weren't compared to avoid downloading cloud files, so **these are candidates, not confirmed duplicates**. If all are copies, up to **",
        "** (": "** (",
        ", из ": ", of ",
        " по всему скану).": " across the scan).",
        ").": ").",
        "Кандидатов в дубли не нашлось.": "No duplicate candidates found.",
        "— лишних ": "— excess ",

        // MARK: - Pie
        "Папка пустая": "Folder is empty",
        "Клик по сектору или строке открывает папку. Дерево слева — то же самое, полосками.":
            "Click a sector or row to open the folder. The tree on the left shows the same data as bars.",
        " элемент": " item",
        " элемента": " items",
        " элементов": " items",
        " и ": " and ",
        " помельче": " — small items",

        // MARK: - Age
        "Распределение по дате последнего изменения файла, по всему скану. Старое и большое — первые кандидаты в архив.":
            "Distribution by last modification date across the entire scan. Old and large — primary candidates for archiving.",

        // MARK: - Crumbs
        "↑ Вверх": "↑ Up",
        "›": "›",

        // MARK: - Places
        "Что просканировать": "What to scan",
        "Выбрать папку в Finder…": "Choose folder in Finder…",
        "или путь: ~/Movies, /Volumes/Диск": "or path: ~/Movies, /Volumes/Drive",
        "Сканировать": "Scan",
        "свободно ": "free ",
        " из ": " of ",

        // MARK: - Tree
        "⊘ не синхр.": "⊘ not synced",

        // MARK: - Node menu
        "Не синхронизируется: исключена папка «": "Not syncing: excluded folder “",
        "»": "”",
        "Снова синхронизировать с Dropbox": "Sync with Dropbox again",
        "Не синхронизировать с Dropbox": "Stop syncing with Dropbox",
        "Переместить в корзину…": "Move to Trash…",
        "Переместить в корзину?": "Move to Trash?",
        "В корзину": "Move to Trash",
        "Не удалось переместить в корзину": "Failed to move to trash",
        "Не синхронизировать с Dropbox?": "Stop syncing with Dropbox?",
        "Не получилось: ": "Failed: ",
        "Не синхронизировать": "Don't sync",

        // MARK: - Подписи в меню
        "Из Dropbox удалится на всех устройствах. Вернуть можно из корзины мака или из удалённых файлов на dropbox.com.":
            "It will be deleted from Dropbox on all devices. Can be restored from Mac Trash or dropbox.com deleted files.",
        "Вернуть можно из корзины.": "Can be restored from Trash.",
        "На этом маке всё останется, но из облака и с других устройств удалится и перестанет занимать квоту. Вернуть — правый клик → «Снова синхронизировать».":
            "Everything stays on this Mac, but it will be removed from the cloud and other devices and stop counting toward quota. To restore — right-click → “Sync with Dropbox again”.",

        // MARK: - Menu app
        "Открыть…": "Open…",
        "Пересканировать": "Rescan",

        // MARK: - Группы файлов
        "Видео": "Video",
        "Фото и графика": "Photos & graphics",
        "Аудио": "Audio",
        "Документы": "Documents",
        "Архивы и образы": "Archives & disk images",
        "Код и данные": "Code & data",
        "Программы": "Apps",
        "Прочее": "Other",

        // MARK: - Корзины возраста
        "до 1 месяца": "< 1 month",
        "1–3 месяца": "1–3 months",
        "3–12 месяцев": "3–12 months",
        "1–2 года": "1–2 years",
        "2–5 лет": "2–5 years",
        "старше 5 лет": "> 5 years",

        // MARK: - Places folder names
        "Домашняя папка": "Home",
        "Загрузки": "Downloads",
        "Рабочий стол": "Desktop",

        // MARK: - Множественные формы для plural()
        "файл": "file",
        "файла": "files",
        "файлов": "files",
        "папка": "folder",
        "папки": "folders",
        "папок": "folders",
        "группа": "group",
        "группы": "groups",
        "групп": "groups",
    ]
}