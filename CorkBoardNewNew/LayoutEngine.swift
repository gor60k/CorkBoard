import CoreGraphics

/// Предлагает непересекающиеся позиции/повороты для набора элементов,
/// чтобы не расставлять всё руками. Пригодится в обоих вариантах:
/// в А — для первичной "авто-раскладки" при импорте фото,
/// в Б — когда новый элемент добавляется в live-режиме и нужно
/// найти для него свободное место на текущей доске.
struct LayoutEngine {
    var canvasSize: CGSize
    var margin: CGFloat = 24

    func suggestPositions(for itemSizes: [CGSize], existing: [BoardItem] = []) -> [CGPoint] {
        var placed: [CGRect] = existing.map {
            CGRect(x: $0.position.x - 60, y: $0.position.y - 60, width: 120, height: 120)
        }
        var results: [CGPoint] = []

        for size in itemSizes {
            var candidate = randomPoint()
            var attempts = 0
            while overlaps(candidate, size: size, placed: placed) && attempts < 200 {
                candidate = randomPoint()
                attempts += 1
            }
            placed.append(CGRect(x: candidate.x - size.width / 2, y: candidate.y - size.height / 2,
                                  width: size.width, height: size.height))
            results.append(candidate)
        }
        return results
    }

    private func randomPoint() -> CGPoint {
        CGPoint(x: CGFloat.random(in: margin...max(margin + 1, canvasSize.width - margin)),
                y: CGFloat.random(in: margin...max(margin + 1, canvasSize.height - margin)))
    }

    private func overlaps(_ point: CGPoint, size: CGSize, placed: [CGRect]) -> Bool {
        let rect = CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2,
                           width: size.width, height: size.height).insetBy(dx: -10, dy: -10)
        return placed.contains { $0.intersects(rect) }
    }
}
