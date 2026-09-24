#!/usr/bin/env swift
// make_icon.swift — рисует PNG 1024×1024, собирает build/AppIcon.icns
import Foundation
import AppKit

let size = 1024

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

// Почти белый скруглённый квадрат с отступами 40 pt
let margin: CGFloat = 40
let rect = NSRect(x: margin, y: margin,
                  width: CGFloat(size) - 2 * margin, height: CGFloat(size) - 2 * margin)
let bgPath = NSBezierPath(roundedRect: rect, xRadius: 180, yRadius: 180)
NSColor(white: 0.97, alpha: 1.0).setFill()
bgPath.fill()

// Логотип из трёх квадратов — как template.html .logo
// CSS grid: 9px + gap(2px) + 5px → маштаб 14×
let sc: CGFloat = 14
let c1w: CGFloat = 9 * sc      // синий — высокий
let c2w: CGFloat = 5 * sc      // жёлтый / оранжевый
let gap: CGFloat = 2 * sc
let totalW = c1w + gap + c2w   // ≈ 224
let totalH = c1w + gap + c2w   // ≈ 224
let ox = (CGFloat(size) - totalW) / 2
let oy = (CGFloat(size) - totalH) / 2
let cr: CGFloat = 2 * sc       // скругление

// Синий (#2a78d6) — высокая колонка слева, на всю высоту логотипа
let r1 = NSRect(x: ox, y: oy, width: c1w, height: totalH)
NSColor(calibratedRed: 0x2a / 255.0, green: 0x78 / 255.0, blue: 0xd6 / 255.0, alpha: 1).setFill()
NSBezierPath(roundedRect: r1, xRadius: cr, yRadius: cr).fill()

// Жёлтый (#eda100) — верхний правый квадрат
let r2 = NSRect(x: ox + c1w + gap, y: oy + c1w + gap, width: c2w, height: c2w)
NSColor(calibratedRed: 0xed / 255.0, green: 0xa1 / 255.0, blue: 0x00 / 255.0, alpha: 1).setFill()
NSBezierPath(roundedRect: r2, xRadius: cr, yRadius: cr).fill()

// Оранжевый (#eb6834) — нижний правый квадрат
let r3 = NSRect(x: ox + c1w + gap, y: oy, width: c2w, height: c2w)
NSColor(calibratedRed: 0xeb / 255.0, green: 0x68 / 255.0, blue: 0x34 / 255.0, alpha: 1).setFill()
NSBezierPath(roundedRect: r3, xRadius: cr, yRadius: cr).fill()

img.unlockFocus()

// Сохраняем PNG 1024×1024
let projectDir = FileManager.default.currentDirectoryPath
let buildDir = projectDir + "/build"
try FileManager.default.createDirectory(atPath: buildDir, withIntermediateDirectories: true)

let pngPath = buildDir + "/icon_1024.png"
let tiffData = img.tiffRepresentation!
let bitmapRep = NSBitmapImageRep(data: tiffData)!
let pngData = bitmapRep.representation(using: .png, properties: [:])!
try pngData.write(to: URL(fileURLWithPath: pngPath))

// Собираем iconset через sips
let iconsetDir = buildDir + "/AppIcon.iconset"
try FileManager.default.createDirectory(atPath: iconsetDir, withIntermediateDirectories: true)

// Набор размеров: 16, 32, 128, 256, 512, 1024 + @2x
let pairs: [(name: String, wh: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

// Резервируем 1024 PNG перед изменением размера — это исходник
for (name, wh) in pairs {
    let out = "\(iconsetDir)/\(name).png"
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    task.arguments = ["-z", "\(wh)", "\(wh)", pngPath, "--out", out]
    try task.run()
    task.waitUntilExit()
}

// iconutil → .icns
let icnsTask = Process()
icnsTask.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
icnsTask.arguments = ["-c", "icns", iconsetDir, "-o", "\(buildDir)/AppIcon.icns"]
try icnsTask.run()
icnsTask.waitUntilExit()

print("AppIcon.icns готов (\(buildDir)/AppIcon.icns)")