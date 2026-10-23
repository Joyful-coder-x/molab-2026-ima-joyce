import SwiftUI
import UIKit

// 接着尝试自己的像素功能：算网格、取中心颜色、用 Week02 的 renderer 画色块。
// 新问题：不会读取照片颜色；下面集中标明需要查资料的取色部分。
enum PhotoPixelRenderer {
    static func prepare(_ image: UIImage) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { drawing in
            let box = CGRect(origin: .zero, size: image.size)
            UIColor.white.setFill()
            drawing.fill(box)

            // 【Outside: Apple】查 UIImage.draw：把导入的照片画到画布上，按照片方向显示。
            // https://developer.apple.com/documentation/uikit/uiimage/draw(in:)
            image.draw(in: box)
        }
    }

    static func pixelate(_ image: UIImage, columns: Int) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let width = cgImage.width
        let height = cgImage.height

        // 【Outside: Apple】取色前，先把照片画入固定的 RGBA 位图。
        // 每像素 4 个字节，每行 width * 4；这样才知道颜色数据的位置。
        // https://developer.apple.com/documentation/coregraphics/cgcontext
        let bytesPerRow = width * 4
        let bitmapInfo = CGBitmapInfo.byteOrder32Big.rawValue
            | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let bitmap = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo
        ) else { return nil }

        bitmap.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // 【Outside: Apple】取得位图内存，按 UInt8（0–255）读取颜色。
        // https://developer.apple.com/documentation/coregraphics/cgcontext/data
        // https://developer.apple.com/documentation/swift/unsaferawpointer/assumingmemorybound(to:)
        guard let data = bitmap.data else { return nil }
        let pixels = data.assumingMemoryBound(to: UInt8.self)

        // 【自己的逻辑】slider 决定列数；按照片比例算行数。
        let columnCount = min(width, max(1, columns))
        let rowCount = min(height, max(1, Int(
            (Double(columnCount) * Double(height) / Double(width)).rounded()
        )))

        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { drawing in
            for row in 0..<rowCount {
                let top = row * height / rowCount
                let bottom = (row + 1) * height / rowCount

                for column in 0..<columnCount {
                    let left = column * width / columnCount
                    let right = (column + 1) * width / columnCount
                    let centerX = (left + right) / 2
                    let centerY = (top + bottom) / 2

                    // 【取色资料的应用】中心坐标 → 字节位置；依次读取 R、G、B。
                    let index = centerY * bytesPerRow + centerX * 4
                    let red = CGFloat(pixels[index]) / 255
                    let green = CGFloat(pixels[index + 1]) / 255
                    let blue = CGFloat(pixels[index + 2]) / 255

                    UIColor(red: red, green: green, blue: blue, alpha: 1).setFill()
                    drawing.fill(CGRect(
                        x: left, y: top,
                        width: right - left, height: bottom - top
                    ))
                }
            }
        }
    }
}
#Preview {
    let sourceImage = UIGraphicsImageRenderer(size: CGSize(width: 300, height: 200)).image { context in
        UIColor.systemPink.setFill()
        context.fill(CGRect(x: 0, y: 0, width: 150, height: 100))

        UIColor.systemBlue.setFill()
        context.fill(CGRect(x: 150, y: 0, width: 150, height: 100))

        UIColor.systemYellow.setFill()
        context.fill(CGRect(x: 0, y: 100, width: 150, height: 100))

        UIColor.systemGreen.setFill()
        context.fill(CGRect(x: 150, y: 100, width: 150, height: 100))
    }
    let pixelatedImage = PhotoPixelRenderer.pixelate(sourceImage, columns: 12) ?? sourceImage

    VStack(spacing: 20) {
        Image(uiImage: sourceImage)
            .resizable()
            .scaledToFit()

        Image(uiImage: pixelatedImage)
            .resizable()
            .scaledToFit()
    }
    .padding()
}

