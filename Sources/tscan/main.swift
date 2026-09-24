// tscan — консольный сканер папки, пишет JSON (и, если попросили, HTML) в формате эталона treesize.py.
//
//   tscan <папка> --json out.json [--html out.html --template путь]
//         [--min-share 2e-6] [--dup-min N] [--timeout 10] [--all-fs]
import Foundation
import TreeSizeCore

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write((msg + "\n").data(using: .utf8)!)
    exit(1)
}

var folder: String?
var jsonOut: String?
var htmlOut: String?
var templatePath: String?
var minShare = 2e-6
var dupMin: Int64 = 5 * 1024 * 1024
var timeout = 10.0
var oneFS = true

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
    default:
        if a.hasPrefix("--") { fail("неизвестный флаг: \(a)") }
        if folder == nil { folder = a } else { fail("лишний аргумент: \(a)") }
    }
    i += 1
}

guard let folderArg = folder else { fail("укажи папку: tscan <папка> --json out.json") }
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
