import Foundation
import CoreGraphics

/// Стиль "крепления" элемента к доске.
enum PinStyle: String, Codable, CaseIterable {
    case redPushpin
    case binderClip
    case tape
    case none
}

/// Визуальная рамка элемента.
enum FrameStyle: String, Codable, CaseIterable {
    case polaroid
    case stamp
    case sticker
    case plainCard
}

/// Один элемент на доске (фото, стикер и т.п.).
/// Codable — чтобы доску можно было сохранить/загрузить и переиспользовать
/// как для рендера в PNG (Вариант А), так и для live-оверлея (Вариант Б).
struct BoardItem: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    /// Имя файла картинки внутри папки ассетов доски.
    var imageFileName: String
    /// Центр элемента в координатах доски (не пикселях экрана).
    var position: CGPoint
    /// Угол поворота в градусах (обычно -12...12 для "живого" вида).
    var rotation: Double
    /// Масштаб относительно базового размера элемента.
    var scale: Double = 1.0
    var frameStyle: FrameStyle = .polaroid
    var pinStyle: PinStyle = .redPushpin
    /// Подпись под полароидом, например.
    var caption: String? = nil
    /// Порядок отрисовки — выше значение, выше слой.
    var zIndex: Int = 0
}

/// Вся доска целиком: фон + элементы. Это то, что сохраняется на диск,
/// поэтому и офлайн-экспортёр, и будущий live-оверлей работают с одной
/// и той же моделью, не дублируя логику.
struct Board: Codable, Equatable {
    var id: UUID = UUID()
    var name: String = "My Board"
    /// Размер холста в points, в котором авторится композиция.
    var canvasSize: CGSize
    var backgroundTexture: String = "cork_default"
    var items: [BoardItem] = []
}
