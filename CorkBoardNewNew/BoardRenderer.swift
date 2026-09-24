import AppKit
import CoreGraphics

/// Рисует всю доску (фон + все элементы) в произвольный CGContext.
/// Используется одинаково и PNG-экспортёром, и (позже) live-оверлеем —
/// это ключевой класс, который делает переход А → Б дешёвым.
final class BoardRenderer {
    private var imageCache: [String: NSImage] = [:]

    func render(board: Board, assetsFolder: URL, into context: CGContext) {
        drawBackground(board: board, in: context)

        let sortedItems = board.items.sorted { $0.zIndex < $1.zIndex }
        for item in sortedItems {
            guard let image = loadImage(named: item.imageFileName, in: assetsFolder) else { continue }
            let renderer = FrameRendererFactory.renderer(for: item.frameStyle)

            context.saveGState()
            context.translateBy(x: item.position.x, y: item.position.y)
            context.rotate(by: CGFloat(item.rotation * .pi / 180))
            context.scaleBy(x: CGFloat(item.scale), y: CGFloat(item.scale))
            renderer.draw(item: item, image: image, in: context)
            context.restoreGState()

            drawPin(style: item.pinStyle, frameSize: renderer.frameSize(for: image),
                    item: item, in: context)
        }
    }

    /// Рендерит доску в битмап точного размера в пикселях — используем
    /// нативное разрешение конкретного экрана при экспорте обоев.
    func renderToImage(board: Board, assetsFolder: URL, pixelSize: CGSize) -> NSImage? {
        guard pixelSize.width > 0, pixelSize.height > 0,
              let context = CGContext(
                data: nil, width: Int(pixelSize.width), height: Int(pixelSize.height),
                bitsPerComponent: 8, bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
              ) else { return nil }

        let scaleX = pixelSize.width / board.canvasSize.width
        let scaleY = pixelSize.height / board.canvasSize.height
        context.scaleBy(x: scaleX, y: scaleY)

        render(board: board, assetsFolder: assetsFolder, into: context)

        guard let cgImage = context.makeImage() else { return nil }
        return NSImage(cgImage: cgImage, size: pixelSize)
    }

    private func drawBackground(board: Board, in context: CGContext) {
        let rect = CGRect(origin: .zero, size: board.canvasSize)

        // Ищем текстуру по имени (board.backgroundTexture) в Asset Catalog
        // приложения. Если не найдена — фолбэк на плоскую заливку, чтобы
        // холст не оставался пустым/чёрным на этапе разработки.
        if let texture = NSImage(named: board.backgroundTexture) {
            drawTextureCovering(texture, rect: rect, in: context)
        } else {
            context.setFillColor(NSColor(calibratedRed: 0.80, green: 0.62, blue: 0.42, alpha: 1).cgColor)
            context.fill(rect)
        }
    }

    /// Рисует текстуру с покрытием всего rect (аналог CSS `background-size: cover`):
    /// пропорции сохраняются, лишнее по краям обрезается. Подходит для одной
    /// большой фотографии пробковой доски, а не для мелкого повторяющегося тайла.
    private func drawTextureCovering(_ image: NSImage, rect: CGRect, in context: CGContext) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let imageAspect = imageSize.width / imageSize.height
        let rectAspect = rect.width / rect.height

        var drawSize = rect.size
        if imageAspect > rectAspect {
            drawSize.height = rect.height
            drawSize.width = rect.height * imageAspect
        } else {
            drawSize.width = rect.width
            drawSize.height = rect.width / imageAspect
        }

        let drawRect = CGRect(x: rect.midX - drawSize.width / 2,
                               y: rect.midY - drawSize.height / 2,
                               width: drawSize.width, height: drawSize.height)

        context.saveGState()
        context.clip(to: rect)
        context.draw(cgImage, in: drawRect)
        context.restoreGState()
    }

    private func drawPin(style: PinStyle, frameSize: CGSize, item: BoardItem, in context: CGContext) {
        guard style != .none else { return }
        // TODO: нарисовать маленькую кнопку/скрепку/скотч в верхней части
        // рамки, в повёрнутых координатах элемента. Для v1 — простые
        // векторные фигуры (круг для кнопки, прямоугольник для скотча).
    }

    private func loadImage(named name: String, in folder: URL) -> NSImage? {
        if let cached = imageCache[name] { return cached }
        let url = folder.appendingPathComponent(name)
        guard let image = NSImage(contentsOf: url) else { return nil }
        imageCache[name] = image
        return image
    }
}
