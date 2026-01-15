#!/usr/bin/swift

import Cocoa

// App icon generator for Clicky
// Generates all required sizes for macOS app icon

func createAppIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    
    image.lockFocus()
    
    guard let context = NSGraphicsContext.current?.cgContext else {
        image.unlockFocus()
        return image
    }
    
    // Background with gradient
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = size * 0.22 // macOS style rounded corners
    
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    
    // Create gradient
    let colors = [
        NSColor(calibratedRed: 0.58, green: 0.29, blue: 0.94, alpha: 1.0).cgColor, // Purple
        NSColor(calibratedRed: 0.25, green: 0.47, blue: 0.96, alpha: 1.0).cgColor, // Blue
        NSColor(calibratedRed: 0.2, green: 0.78, blue: 0.89, alpha: 1.0).cgColor   // Cyan
    ]
    
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors as CFArray,
        locations: [0.0, 0.5, 1.0]
    )!
    
    context.saveGState()
    path.addClip()
    context.drawLinearGradient(
        gradient,
        start: CGPoint(x: 0, y: size),
        end: CGPoint(x: size, y: 0),
        options: []
    )
    context.restoreGState()
    
    // Draw keyboard icon using SF Symbols
    let iconSize = size * 0.45
    let iconConfig = NSImage.SymbolConfiguration(pointSize: iconSize, weight: .semibold)
    
    if let keyboardSymbol = NSImage(systemSymbolName: "keyboard.fill", accessibilityDescription: nil) {
        let symbolImage = keyboardSymbol.withSymbolConfiguration(iconConfig)!
        
        // Calculate center position
        let symbolSize = symbolImage.size
        let x = (size - symbolSize.width) / 2
        let y = (size - symbolSize.height) / 2
        
        // Draw with white color
        NSColor.white.setFill()
        let symbolRect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
        symbolImage.draw(in: symbolRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    
    image.unlockFocus()
    return image
}

func savePNG(image: NSImage, to path: String) {
    guard let tiffData = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiffData),
          let pngData = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG for \(path)")
        return
    }
    
    do {
        try pngData.write(to: URL(fileURLWithPath: path))
        print("Created: \(path)")
    } catch {
        print("Error writing \(path): \(error)")
    }
}

// Icon sizes for macOS (size x scale = actual pixels)
let iconSizes: [(size: Int, scale: Int, filename: String)] = [
    (16, 1, "icon_16x16.png"),
    (16, 2, "icon_16x16@2x.png"),
    (32, 1, "icon_32x32.png"),
    (32, 2, "icon_32x32@2x.png"),
    (128, 1, "icon_128x128.png"),
    (128, 2, "icon_128x128@2x.png"),
    (256, 1, "icon_256x256.png"),
    (256, 2, "icon_256x256@2x.png"),
    (512, 1, "icon_512x512.png"),
    (512, 2, "icon_512x512@2x.png")
]

let basePath = FileManager.default.currentDirectoryPath + "/Clicky/Assets.xcassets/AppIcon.appiconset/"

print("Generating Clicky app icons...")

for icon in iconSizes {
    let actualSize = CGFloat(icon.size * icon.scale)
    let image = createAppIcon(size: actualSize)
    savePNG(image: image, to: basePath + icon.filename)
}

print("Done!")
