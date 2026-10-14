import AppKit
import CoreGraphics

/// Рисует рамку + фото одного BoardItem в переданный контекст.
/// И офлайн-экспортёр PNG (Вариант А), и будущее live-окно оверлея
/// (Вариант Б) рисуют через один и тот же протокол — визуальная
/// логика не дублируется.
protocol ItemFrameRenderer {
    /// Рисует элемент по центру координат (0,0) в масштабе 1x.
    /// Трансляцию/поворот/масштаб применяет вызывающий код.
    func draw(item: BoardItem, image: NSImage, in context: CGContext)
    /// "Родной" (немасштабированный) размер рамки — нужен для layout/hit-testing.
    func frameSize(for image: NSImage) -> CGSize
}

struct PolaroidRenderer: ItemFrameRenderer {
    let borderWidth: CGFloat = 14
    let bottomBorder: CGFloat = 48

    func frameSize(for image: NSImage) -> CGSize {
        let photoSize = fittedPhotoSize(for: image)
        return CGSize(width: photoSize.width + borderWidth * 2,
                       height: photoSize.height + borderWidth + bottomBorder)
    }

    func draw(item: BoardItem, image: NSImage, in context: CGContext) {
        let photoSize = fittedPhotoSize(for: image)
        let frame = frameSize(for: image)
        let cardRect = CGRect(x: -frame.width / 2, y: -frame.height / 2,
                               width: frame.width, height: frame.height)

        context.saveGState()
        context.setShadow(offset: CGSize(width: 0, height: -4), blur: 10,
                           color: NSColor.black.withAlphaComponent(0.35).cgColor)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(cardRect)
        context.restoreGState()

        let photoRect = CGRect(x: cardRect.minX + borderWidth,
                                y: cardRect.maxY - borderWidth - photoSize.height,
                                width: photoSize.width, height: photoSize.height)
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.saveGState()
            context.clip(to: photoRect)
            context.draw(cg, in: photoRect)
            context.restoreGState()
        }

        if let caption = item.caption {
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont(name: "Bradley Hand", size: 16) ?? NSFont.systemFont(ofSize: 16),
                .foregroundColor: NSColor.darkGray
            ]
            let string = NSAttributedString(string: caption, attributes: attrs)
            let textSize = string.size()
            let textRect = CGRect(x: cardRect.midX - textSize.width / 2,
                                   y: cardRect.minY + (bottomBorder - textSize.height) / 2,
                                   width: textSize.width, height: textSize.height)
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(cgContext: context, flipped: false)
            string.draw(in: textRect)
            NSGraphicsContext.restoreGraphicsState()
        }
    }

    private func fittedPhotoSize(for image: NSImage) -> CGSize {
        let maxSide: CGFloat = 200
        let ratio = image.size.width / image.size.height
        return ratio >= 1
            ? CGSize(width: maxSide, height: maxSide / ratio)
            : CGSize(width: maxSide * ratio, height: maxSide)
    }
}

/// Заглушка на первую итерацию — прямоугольная белая карточка.
/// TODO: зубчатый (perforated) край через CGPath, как у настоящей марки.
struct StampRenderer: ItemFrameRenderer {
    func frameSize(for image: NSImage) -> CGSize {
        CGSize(width: 140, height: 170)
    }

    func draw(item: BoardItem, image: NSImage, in context: CGContext) {
        let frame = frameSize(for: image)
        let rect = CGRect(x: -frame.width / 2, y: -frame.height / 2,
                           width: frame.width, height: frame.height)
        context.setFillColor(NSColor.white.cgColor)
        context.fill(rect)
        // TODO: рамка с зубчиками + инсет для фото/иллюстрации.
    }
}

/// Стикер: картинка с белой обводкой по силуэту, без фона-карточки.
struct StickerRenderer: ItemFrameRenderer {
    func frameSize(for image: NSImage) -> CGSize {
        CGSize(width: 120, height: 120)
    }

    func draw(item: BoardItem, image: NSImage, in context: CGContext) {
        let frame = frameSize(for: image)
        let rect = CGRect(x: -frame.width / 2, y: -frame.height / 2,
                           width: frame.width, height: frame.height)
        if let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) {
            context.saveGState()
            context.setShadow(offset: .zero, blur: 6, color: NSColor.white.cgColor)
            context.draw(cg, in: rect)
            context.restoreGState()
        }
    }
}

enum FrameRendererFactory {
    static func renderer(for style: FrameStyle) -> ItemFrameRenderer {
        switch style {
        case .polaroid: return PolaroidRenderer()
        case .stamp: return StampRenderer()
        case .sticker: return StickerRenderer()
        case .plainCard: return PolaroidRenderer() // временно переиспользуем
        }
    }
}
