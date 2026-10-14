import SwiftUI
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @State private var board = Board(canvasSize: CGSize(width: 1920, height: 1200))
    @State private var assetsFolder: URL = {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("CorkBoardAssets")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    private let renderer = BoardRenderer()

    var body: some View {
        HSplitView {
            sidebar
            canvasPreview
        }
        .frame(minWidth: 900, minHeight: 600)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cork Board").font(.title2.bold())

            Button("Добавить фото…") { addPhoto() }

            List {
                ForEach($board.items) { $item in
                    HStack {
                        Text(item.imageFileName).lineLimit(1)
                        Spacer()
                        Picker("", selection: $item.frameStyle) {
                            ForEach(FrameStyle.allCases, id: \.self) { style in
                                Text(style.rawValue).tag(style)
                            }
                        }
                        .frame(width: 100)
                        .labelsHidden()
                    }
                }
            }

            Spacer()
            Button("Экспортировать как обои") {
                WallpaperExporter.export(board: board, assetsFolder: assetsFolder)
            }
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
        .frame(width: 280)
    }

    private var canvasPreview: some View {
        GeometryReader { geo in
            if let image = renderer.renderToImage(
                board: board, assetsFolder: assetsFolder,
                pixelSize: CGSize(width: max(geo.size.width, 1) * 2, height: max(geo.size.height, 1) * 2)
            ) {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Color.gray.opacity(0.2)
            }
        }
    }

    private func addPhoto() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.image]
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }

        let layout = LayoutEngine(canvasSize: board.canvasSize)
        let sizes = panel.urls.map { _ in CGSize(width: 220, height: 260) }
        let positions = layout.suggestPositions(for: sizes, existing: board.items)

        for (index, url) in panel.urls.enumerated() {
            let destName = UUID().uuidString + "_" + url.lastPathComponent
            let destURL = assetsFolder.appendingPathComponent(destName)
            try? FileManager.default.copyItem(at: url, to: destURL)

            let item = BoardItem(
                imageFileName: destName,
                position: positions[index],
                rotation: Double.random(in: -10...10),
                frameStyle: .polaroid,
                pinStyle: .redPushpin,
                zIndex: board.items.count
            )
            board.items.append(item)
        }
    }
}
