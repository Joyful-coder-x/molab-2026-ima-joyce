import SwiftUI
import PhotosUI
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

// 【老师 Instafilter】参考选图、滑块、处理和分享结构；本文件为改写。
// https://github.com/molab-itp/07-Instafilter/blob/main/project13/Instafilter/ContentView.swift
// 【WWDC22】参考 PhotosPicker 与 Transferable 的选图、加载流程。
// https://developer.apple.com/videos/play/wwdc2022/10023/
struct PhotoEditorGameView: View {
    @State private var selectedItem: PhotosPickerItem?
    @State private var originalImage: UIImage?
    @State private var processedImage: UIImage?
    @State private var colorStyle = "Original"
    @State private var gridColumns = 40.0
    @State private var pixelated = true

    private let context = CIContext()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 【老师】保留 PhotosPicker；这里让导入按钮始终可见。
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Import Photo", systemImage: "photo")
                }
                .buttonStyle(.borderedProminent)

                if let processedImage {
                    Image(uiImage: processedImage)
                        .resizable()
                        .scaledToFit()
                } else {
                    Text("Import a photo to begin")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 240)
                }

                VStack(spacing: 16) {
                    Picker("Color Style", selection: $colorStyle) {
                        Text("Original").tag("Original")
                        Text("Sepia").tag("Sepia")
                        Text("B&W").tag("Black & White")
                    }
                    .pickerStyle(.segmented)

                    Toggle("Pixel Art", isOn: $pixelated)

                    VStack(alignment: .leading) {
                        Text("Grid: \(Int(gridColumns)) columns")
                        // 【老师】Slider + onChange；改为控制网格列数。
                        Slider(value: $gridColumns, in: 8...128, step: 1)
                        Text("Fewer columns = bigger blocks. More columns = more detail.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .disabled(!pixelated)

                    if let processedImage {
                        // 【老师】分享当前处理结果。
                        ShareLink(
                            item: Image(uiImage: processedImage),
                            preview: SharePreview("Pixel Art", image: Image(uiImage: processedImage))
                        ) {
                            Label("Share Image", systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .disabled(originalImage == nil)
            }
            .padding()
        }
        .navigationTitle("Photo Editor")
        .onChange(of: selectedItem) { loadImage() }
        .onChange(of: colorStyle) { applyProcessing() }
        .onChange(of: gridColumns) { applyProcessing() }
        .onChange(of: pixelated) { applyProcessing() }
    }

    // 【老师 + WWDC22】选择器返回项目，再异步读取 Data，转为 UIImage。
    private func loadImage() {
        guard let selectedItem else { return }
        Task { @MainActor in
            guard let data = try? await selectedItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                return
            }
            originalImage = PhotoPixelRenderer.prepare(image)
            applyProcessing()
        }
    }

    // 【老师结构，自己的流程】原照片 → 颜色风格 → 中心取色像素化。
    private func applyProcessing() {
        guard let originalImage else { return }
        var styledImage = originalImage

        if colorStyle != "Original" {
            let filter: CIFilter
            if colorStyle == "Sepia" {
                // 【老师已有】Sepia；先用固定强度，减少一个滑块。
                let sepia = CIFilter.sepiaTone()
                sepia.intensity = 0.85
                filter = sepia
            } else {
                // 【Outside: Apple】Mono 黑白滤镜；按老师的滤镜结构接入。
                // https://developer.apple.com/documentation/coreimage/cifilter-swift.class/photoeffectmono()
                filter = CIFilter.photoEffectMono()
            }
            filter.setValue(CIImage(image: originalImage), forKey: kCIInputImageKey)
            guard let output = filter.outputImage,
                  let result = context.createCGImage(output, from: output.extent) else {
                return
            }
            styledImage = UIImage(cgImage: result)
        }

        if pixelated {
            guard let result = PhotoPixelRenderer.pixelate(styledImage, columns: Int(gridColumns)) else {
                return
            }
            processedImage = result
        } else {
            processedImage = styledImage
        }
    }
}

#Preview {
    NavigationStack {
        PhotoEditorGameView()
    }
}
