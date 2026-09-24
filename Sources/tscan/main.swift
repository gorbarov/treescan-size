// tscan — консольный сканер папки, пишет JSON (и, если попросили, HTML) в формате эталона treesize.py.
//
//   tscan <папка> --json out.json [--html out.html --template путь]
//         [--min-share 2e-6] [--dup-min N] [--timeout 10] [--all-fs]
//   tscan --model-check <папка>
import Foundation
import TreeSizeCore

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

func countNodes(_ n: Node) -> Int64 {
    var cnt: Int64 = 1
    if let c = n.children {
        for ch in c { cnt += countNodes(ch) }
    }
    return cnt
}

var folder: String?
var jsonOut: String?
var htmlOut: String?
var templatePath: String?
var minShare = 2e-6
var dupMin: Int64 = 5 * 1024 * 1024
var timeout = 10.0
var oneFS = true
var modelCheck = false
var actionsCheck: String?

var args = Array(CommandLine.arguments.dropFirst())
var i = 0
func nextValue(_ flag: String) -> String {
    i += 1
    guard i < args.count else { fail("\(flag): не хватает значения") }
    return args[i]
}
while i < args.count {
    let a = args[i]
    switch a {
    case "--json": jsonOut = nextValue(a)
    case "--html": htmlOut = nextValue(a)
    case "--template": templatePath = nextValue(a)
    case "--min-share": minShare = Double(nextValue(a)) ?? minShare
    case "--dup-min": dupMin = Int64(nextValue(a)) ?? dupMin
    case "--timeout": timeout = Double(nextValue(a)) ?? timeout
    case "--all-fs": oneFS = false
    case "--model-check": modelCheck = true; folder = nextValue(a)
    case "--actions-check": actionsCheck = nextValue(a)
    default:
        if a.hasPrefix("--") { fail("неизвестный флаг: \(a)") }
        if folder == nil { folder = a } else { fail("лишний аргумент: \(a)") }
    }
    i += 1
}

guard let folderArg = folder else {
    // --actions-check не требует аргумента folder
    if let acRoot = actionsCheck {
        let home = NSHomeDirectory()

        // protected-тест — те же пути, что и в эталоне
        let protectedPaths = [
            "/",
            "/Users",
            home,
            home + "/Library",
            home + "/Downloads",
            "/Applications",
            "/Applications/Foo.app",
            "/System/Volumes/Data/Users",
            "/System/Volumes/Data/Users/x/Downloads/y",
            "/Volumes/X",
            "/Volumes/X/a",
            "/System/Library",
            "/tmp/ts-fixture/media",
        ]
        for p in protectedPaths {
            let result = isProtected(p)
            var display = p
            if p == home { display = "~" }
            else if p.hasPrefix(home + "/") { display = "~" + p.dropFirst(home.count) }
            print("protected \(display) = \(result)")
        }

        // allowed-тест
        let allowedPaths = [
            acRoot,
            acRoot + "/media",
            acRoot + "/media/film.mov",
            acRoot + "/../etc/passwd",
            acRoot + "2/x",
            acRoot + "/nope.txt",
        ]
        for p in allowedPaths {
            let result = isActionAllowed(path: p, root: acRoot)
            print("allowed \(p) = \(result)")
        }

        // places
        let places = listPlaces()
        print("places_at_least_2 = \(places.count >= 2)")

        exit(0)
    }
    fail("укажи папку: tscan <папка> --json out.json")
}

let root = (folderArg as NSString).expandingTildeInPath
var isDir: ObjCBool = false
guard FileManager.default.fileExists(atPath: root, isDirectory: &isDir), isDir.boolValue else {
    fail("Нет такой папки: \(root)")
}
let absRoot = (root as NSString).isAbsolutePath ? root : FileManager.default.currentDirectoryPath + "/" + root
if htmlOut != nil && templatePath == nil {
    fail("--html требует --template")
}

let options = ScanOptions(oneFS: oneFS, minShare: minShare, dupMin: dupMin, timeout: timeout)

if modelCheck {
    L10n.forceLang("ru")
    let data = scanRoot(absRoot, options: options)
    let result = ScanResult(data: data)
    print("root: \(URL(fileURLWithPath: result.tree.name).lastPathComponent)")
    print("nodes: \(countNodes(result.tree))")
    print("children:")
    if let kids = result.tree.children {
        let sorted = kids.filter { !($0.kind == .rest && $0.files == 0 && $0.dirs == 0) }
            .sorted { $0.size > $1.size }
        for c in sorted {
            let pct = Double(c.size) / Double(result.tree.size)
            print("  \(fmtBytes(c.size)) | \(c.displayName) | \(fmtPct(pct))")
        }
    }

    // fmt-тест
    let fmtInputs: [(Int64, String)] = [
        (0, "0 Б"),
        (1023, "1023 Б"),
        (1024, "1,00 КБ"),
        (1536, "1,50 КБ"),
        (10485760, "10,0 МБ"),
        (132499741081, "123 ГБ"),
        (1099511627776, "1,00 ТБ"),
    ]
    print("fmt: " + fmtInputs.map { "\($0.0)=\(fmtBytes($0.0))" }.joined(separator: "; "))

    // pct-тест
    let pctInputs: [(Double, String)] = [
        (0.6449, "64 %"),
        (0.0667, "6,7 %"),
        (0.00049, "0,0 %"),
        (1.0, "100 %"),
    ]
    print("pct: " + pctInputs.map { "\($0.0)=\(fmtPct($0.0))" }.joined(separator: "; "))

    // plural-тест
    print("plural: " + [1, 3, 5, 11, 21, 1234].map { plural(Int64($0), "файл", "файла", "файлов") }.joined(separator: "; "))

    // date-тест
    print("date: 0=\(fmtDate(0)); 1420088400=\(fmtDate(1420088400))")
    exit(0)
}

let data = scanRoot(absRoot, options: options)

if let jsonOut {
    let jsonData = try! JSONSerialization.data(withJSONObject: data, options: [])
    try! jsonData.write(to: URL(fileURLWithPath: (jsonOut as NSString).expandingTildeInPath))
}
if let htmlOut, let templatePath {
    let template = try! String(contentsOfFile: (templatePath as NSString).expandingTildeInPath, encoding: .utf8)
    let html = renderHTML(data: data, template: template)
    try! html.write(toFile: (htmlOut as NSString).expandingTildeInPath, atomically: true, encoding: .utf8)
}
