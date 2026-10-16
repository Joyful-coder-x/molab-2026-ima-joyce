import Foundation

// Adapted from ItemModel.swift in molab-itp/06-ImageEditDemoJSON:
// https://github.com/molab-itp/06-ImageEditDemoJSON/blob/main/ImageEditDemoJSON/Model/ItemModel.swift
// The tutorial's Identifiable/Codable item becomes one saved light point.
struct LightPoint: Identifiable, Codable, Equatable {
    let id: UUID

    // 【归一化坐标 Normalized Coordinates】
    // 不直接保存 1024 x 1024 图片里的像素位置，而是保存 0...1 的位置比例。
    // 例如 normalizedX = 0.5 代表图片水平方向的正中央。
    // 这样同一份作品可以在不同大小的 iPhone、iPad 和导出图片上保持相同布局。
    let normalizedX: Double
    let normalizedY: Double
    let normalizedRadius: Double

    init(
        id: UUID = UUID(),
        normalizedX: Double,
        normalizedY: Double,
        normalizedRadius: Double
    ) {
        self.id = id
        self.normalizedX = normalizedX
        self.normalizedY = normalizedY
        self.normalizedRadius = normalizedRadius
    }
}

// Adapted from ItemModel.swift. The image recipe and PNG filename replace the tutorial's URL, label, asset name, and SF Symbol name.
struct LightArtwork: Identifiable, Codable, Equatable {
    let id: UUID
    let createdAt: Date
    let imageFileName: String

    // 【保存模型，再重建图片 Save the Model, Recreate the Image】
    // JSON 不保存 UIImage 本身，而是保存每一个光点的位置和半径，也就是“绘图配方”。
    // 读取 JSON 后，LightArtworkRenderer 可以用这些数据重新画出相同的作品。
    var points: [LightPoint]

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        imageFileName: String? = nil,
        points: [LightPoint] = []
    ) {
        self.id = id
        self.createdAt = createdAt
        self.imageFileName = imageFileName ?? "light-art-\(id.uuidString).png"
        self.points = points
    }
}

// Adapted from Model.swift in the reference repository:
// https://github.com/molab-itp/06-ImageEditDemoJSON/blob/main/ImageEditDemoJSON/Model/Model.swift
// `items` now contains artwork recipes instead of editable image records.
struct LightArtworkLibrary: Codable, Equatable {
    var items: [LightArtwork] = []

    mutating func addItem(_ item: LightArtwork) {
        items.append(item)
    }

    mutating func deleteItem(id: UUID) {
        if let index = findIndex(id) {
            items.remove(at: index)
        }
    }

    func findIndex(_ id: UUID) -> Int? {
        items.firstIndex { item in
            item.id == id
        }
    }
}
