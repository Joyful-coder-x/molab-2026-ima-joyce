import UIKit

enum LightArtworkRenderer {
    static let imageDimension: CGFloat = 1024

    // 封装绘图：传入 artwork，返回 UIImage，供预览和保存重复调用。
    static func render(_ artwork: LightArtwork) -> UIImage {

        // 新增 Format：控制输出像素比例与透明度；W3Schools 来源未找到。
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1     // 1024 points 输出为 1024 pixels。
        format.opaque = true // 不需要透明背景。

        let size = CGSize(width: imageDimension, height: imageDimension)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            let graphicsContext = context.cgContext

            // 明确绘图区域；可沿用 renderer.format.bounds；W3Schools 来源未找到。
            let box = CGRect(origin: .zero, size: size)

            UIColor(red: 0.02, green: 0.05, blue: 0.18, alpha: 1).setFill()
            context.fill(box)

            let colors = [
                UIColor.white.cgColor,
                UIColor.systemYellow.withAlphaComponent(0.95).cgColor,
                UIColor.systemBlue.withAlphaComponent(0.55).cgColor,
                UIColor.systemBlue.withAlphaComponent(0).cgColor
            ]
            let locations: [CGFloat] = [0, 0.15, 0.50, 1]

            // 用 guard let 替代 !：创建失败则退出绘图，避免强制解包崩溃。
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: locations
            ) else {
                return
            }

            // 改为读取已生成的点，避免预览和保存时重新随机；设计依据是保持图案一致。
            for point in artwork.points {

                // 归一化：比例 × 尺寸还原坐标，适配不同画布；用户提供参考（内容未核对）：
                // https://www.youtube.com/watch?v=93bfh3GK79s
                let center = CGPoint(
                    x: point.normalizedX * imageDimension,
                    y: point.normalizedY * imageDimension
                )
                let radius = point.normalizedRadius * imageDimension

                graphicsContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }
}
