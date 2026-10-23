import SwiftUI
import UIKit

struct LightCreatorGameView: View {
    private let maximumLightCount = 5

    @State private var artwork = LightArtwork()
    @State private var previewImage: UIImage?
    @State private var savedArtworks: [LightArtwork] = []
    @State private var statusMessage: String?
    @State private var isCurrentArtworkSaved = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LightCreatorInstructions(
                    placedCount: artwork.points.count,
                    maximumCount: maximumLightCount
                )

                LightArtworkCanvas(
                    image: previewImage,
                    acceptsInput: artwork.points.count < maximumLightCount,
                    onTap: addLight
                )

                LightCreatorControls(
                    canSave: artwork.points.count == maximumLightCount && !isCurrentArtworkSaved,
                    hasSavedArtwork: !savedArtworks.isEmpty,
                    savedArtworks: $savedArtworks,
                    onRandomize: randomizeArtwork,
                    onReset: resetArtwork,
                    onSave: saveArtwork
                )

                if let statusMessage {
                    Text(statusMessage)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
        .navigationTitle("Light Creator")
        .onAppear {
            savedArtworks = LightArtworkStore.loadLibrary().items.reversed()
            renderPreview()
        }
    }

    private func addLight(at normalizedPoint: CGPoint) {
        guard artwork.points.count < maximumLightCount else {
            return
        }

        // 【生成数据与绘图分开】
        // 玩家点击时才建立 LightPoint，并在这里随机产生半径。
        // Renderer 之后只读取这个点，不会再次随机，所以预览和保存的图片一致。
        artwork.points.append(
            LightPoint(
                normalizedX: normalizedPoint.x,
                normalizedY: normalizedPoint.y,
                normalizedRadius: Double.random(in: 0.08...0.22)
            )
        )
        statusMessage = nil
        isCurrentArtworkSaved = false
        renderPreview()
    }

    private func randomizeArtwork() {
        resetArtwork()

        // 随机作品的数据在这里一次生成完毕，而不是在绘图函数中重复生成。
        for _ in 0..<maximumLightCount {
            let radius = Double.random(in: 0.08...0.22)
            artwork.points.append(
                LightPoint(
                    normalizedX: Double.random(in: radius...(1 - radius)),
                    normalizedY: Double.random(in: radius...(1 - radius)),
                    normalizedRadius: radius
                )
            )
        }

        renderPreview()
    }

    private func resetArtwork() {
        artwork = LightArtwork()
        isCurrentArtworkSaved = false
        statusMessage = nil
        renderPreview()
    }

    private func saveArtwork() {
        guard artwork.points.count == maximumLightCount,
              let previewImage else {
            return
        }

        do {
            let library = try LightArtworkStore.save(
                artwork: artwork,
                image: previewImage
            )
            savedArtworks = library.items.reversed()
            isCurrentArtworkSaved = true
            statusMessage = "Saved \(artwork.imageFileName) and updated artworks.json."
        } catch {
            statusMessage = "Could not save the artwork: \(error.localizedDescription)"
        }
    }

    private func renderPreview() {
        previewImage = LightArtworkRenderer.render(artwork)
    }
}

private struct LightCreatorInstructions: View {
    let placedCount: Int
    let maximumCount: Int

    var body: some View {
        VStack(spacing: 8) {
            Text("Tap the canvas to place five lights")
                .font(.headline)

            Text("Lights placed: \(placedCount) of \(maximumCount)")
                .foregroundStyle(.secondary)
        }
    }
}

private struct LightArtworkCanvas: View {
    let image: UIImage?
    let acceptsInput: Bool
    let onTap: (CGPoint) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color(red: 0.02, green: 0.05, blue: 0.18)

                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.white.opacity(0.25), lineWidth: 1)
            }
            .contentShape(Rectangle())
            // Gesture location is not part of the JSON tutorial. It is needed
            // to turn the player's canvas tap into normalized x/y coordinates.
            // Learn more: https://developer.apple.com/documentation/swiftui/draggesture
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        guard acceptsInput,
                              geometry.size.width > 0,
                              geometry.size.height > 0 else {
                            return
                        }

                        // 【归一化坐标】
                        // 用点击位置除以当前画布宽高，把屏幕坐标转换成 0...1 的比例。
                        // 因此无论画布显示多大，都能映射到相同的 1024 x 1024 输出图片。
                        let normalizedPoint = CGPoint(
                            x: min(max(value.location.x / geometry.size.width, 0), 1),
                            y: min(max(value.location.y / geometry.size.height, 0), 1)
                        )
                        onTap(normalizedPoint)
                    }
            )
            .accessibilityLabel("Light artwork canvas")
            .accessibilityHint("Tap to place a light")
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct LightCreatorControls: View {
    let canSave: Bool
    let hasSavedArtwork: Bool
    @Binding var savedArtworks: [LightArtwork]
    let onRandomize: () -> Void
    let onReset: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            ViewThatFits {
                HStack {
                    LightCreatorActionButtons(
                        canSave: canSave,
                        onRandomize: onRandomize,
                        onReset: onReset,
                        onSave: onSave
                    )
                }

                VStack {
                    LightCreatorActionButtons(
                        canSave: canSave,
                        onRandomize: onRandomize,
                        onReset: onReset,
                        onSave: onSave
                    )
                }
            }

            NavigationLink("Saved Artwork") {
                SavedArtworkGalleryView(artworks: $savedArtworks)
            }
            .buttonStyle(.bordered)
            .disabled(!hasSavedArtwork)
        }
    }
}

private struct LightCreatorActionButtons: View {
    let canSave: Bool
    let onRandomize: () -> Void
    let onReset: () -> Void
    let onSave: () -> Void

    var body: some View {
        Button("Randomize", action: onRandomize)
            .buttonStyle(.bordered)

        Button("Clear", action: onReset)
            .buttonStyle(.bordered)

        Button("Save Image", action: onSave)
            .buttonStyle(.borderedProminent)
            .disabled(!canSave)
    }
}

private struct SavedArtworkGalleryView: View {
    @Binding var artworks: [LightArtwork]

    var body: some View {
        List(artworks) { artwork in
            NavigationLink {
                SavedArtworkDetailView(artwork: artwork) {
                    delete(artwork)
                }
            } label: {
                SavedArtworkRow(artwork: artwork)
            }
        }
        .navigationTitle("Saved Artwork")
        .overlay {
            if artworks.isEmpty {
                ContentUnavailableView(
                    "No Saved Artwork",
                    systemImage: "photo",
                    description: Text("Create and save an image to see it here.")
                )
            }
        }
    }

    private func delete(_ artwork: LightArtwork) {
        do {
            artworks = try LightArtworkStore.delete(artwork: artwork).items.reversed()
        } catch {
            // Keep the row visible if either the JSON index or PNG cannot be
            // removed, so the interface does not claim deletion succeeded.
        }
    }
}

private struct SavedArtworkRow: View {
    let artwork: LightArtwork
    @State private var image: UIImage?

    var body: some View {
        HStack(spacing: 12) {
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.secondary.opacity(0.15)
                }
            }
            .frame(width: 72, height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading) {
                Text("Five-Light Artwork")
                Text(artwork.createdAt, format: .dateTime.month().day().year().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        // The reference app uses AsyncImage for web URLs. These images are
        // local PNG files, so this task loads them from the Documents directory.
        .task(id: artwork.id) {
            image = LightArtworkStore.image(for: artwork)
        }
    }
}

private struct SavedArtworkDetailView: View {
    let artwork: LightArtwork
    let onDelete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var image: UIImage?

    var body: some View {
        VStack(spacing: 20) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ContentUnavailableView("Image Missing", systemImage: "photo.badge.exclamationmark")
            }

            Text(artwork.createdAt, format: .dateTime.month().day().year().hour().minute())
                .foregroundStyle(.secondary)

            Button("Delete", role: .destructive) {
                onDelete()
                dismiss()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .navigationTitle("Artwork")
        // Adapted from ItemDetail.swift in the reference repository. The web
        // image loader is replaced with a Documents-directory PNG loader.
        .task(id: artwork.id) {
            image = LightArtworkStore.image(for: artwork)
        }
    }
}

#Preview {
    NavigationStack {
        LightCreatorGameView()
    }
}
