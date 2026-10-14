import AppKit

/// "Выходной слой" Варианта А: рендерит доску один раз и передаёт
/// результат macOS как обычную картинку рабочего стола. Именно этот
/// файл заменяется на live-NSWindow-оверлей в Варианте Б — всё, что
/// выше по пайплайну (Board, BoardRenderer, LayoutEngine), не меняется.
enum WallpaperExporter {
    static func export(board: Board, assetsFolder: URL) {
        let renderer = BoardRenderer()

        for screen in NSScreen.screens {
            let pixelSize = CGSize(width: screen.frame.width * screen.backingScaleFactor,
                                    height: screen.frame.height * screen.backingScaleFactor)
            guard let image = renderer.renderToImage(board: board, assetsFolder: assetsFolder,
                                                      pixelSize: pixelSize) else { continue }
            guard let tiffData = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiffData),
                  let pngData = bitmap.representation(using: .png, properties: [:]) else { continue }

            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("board_wallpaper_\(screen.hash).png")
            try? pngData.write(to: outputURL)

            do {
                try NSWorkspace.shared.setDesktopImageURL(
                    outputURL, for: screen,
                    options: [.imageScaling: NSImageScaling.scaleProportionallyUpOrDown.rawValue]
                )
            } catch {
                print("Не удалось установить обои для экрана \(screen): \(error)")
            }
        }
    }
}
