import Foundation
import UIKit

// The four helpers below are adapted from SaveLoadJSON.swift in
// molab-itp/06-ImageEditDemoJSON:
// https://github.com/molab-itp/06-ImageEditDemoJSON/blob/main/ImageEditDemoJSON/Model/SaveLoadJSON.swift
// Changes: Data is written directly, forced unwraps were removed, and the functions are private because only LightArtworkStore should use them.
private func saveJSON<T: Encodable>(fileName: String, value: T) throws {
    let filePath = try documentPath(fileName: fileName)
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    let jsonData = try encoder.encode(value)
    try jsonData.write(to: filePath, options: .atomic)
}

private func loadJSON<T: Decodable>(_ type: T.Type, fileName: String) throws -> T {
    let filePath = try documentPath(fileName: fileName)

    guard FileManager.default.fileExists(atPath: filePath.path) else {
        throw LightArtworkFileError.missing
    }

    let jsonData = try Data(contentsOf: filePath)
    return try JSONDecoder().decode(type, from: jsonData)
}

private func remove(fileName: String) throws {
    let filePath = try documentPath(fileName: fileName)

    if FileManager.default.fileExists(atPath: filePath.path) {
        try FileManager.default.removeItem(at: filePath)
    }
}

private func documentPath(fileName: String, create: Bool = false) throws -> URL {
    // 【App Sandbox / Documents】
    // iOS App 运行在自己的 sandbox 中，不能使用 Mac Terminal 的 ~/Downloads 路径。
    // FileManager 会找到“这个 App 自己的”Documents 文件夹；重新打开 App 后，
    // 保存在这里的 artworks.json 和 PNG 文件仍然可以被读取。
    // Learn more: https://developer.apple.com/documentation/foundation/filemanager
    let directory = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: create
    )
    return directory.appendingPathComponent(fileName)
}

enum LightArtworkFileError: LocalizedError {
    case missing
    case pngCreationFailed

    var errorDescription: String? {
        switch self {
        case .missing:
            "The saved artwork file could not be found."
        case .pngCreationFailed:
            "The artwork could not be converted to PNG data."
        }
    }
}

enum LightArtworkStore {
    private static let saveFileName = "artworks.json"

    // 【绘图与保存分工 Separate Rendering from Storage】
    // LightArtworkRenderer 只负责把模型画成 UIImage；这个 Store 只负责读写文件。
    // 分开后，修改绘图效果不会影响 JSON 保存代码，修改存储方式也不会影响绘图代码。

    // Adapted from ModelJSON.swift in the reference repository:
    // https://github.com/molab-itp/06-ImageEditDemoJSON/blob/main/ImageEditDemoJSON/Model/ModelJSON.swift
    // A missing JSON file means the player has not saved artwork yet.
    static func loadLibrary() -> LightArtworkLibrary {
        (try? loadJSON(LightArtworkLibrary.self, fileName: saveFileName)) ?? LightArtworkLibrary()
    }

    static func save(artwork: LightArtwork, image: UIImage) throws -> LightArtworkLibrary {
        // UIImage 是画面结果；pngData() 把它转换成可以写入 Documents 的 PNG 数据。
        guard let imageData = image.pngData() else {
            throw LightArtworkFileError.pngCreationFailed
        }

        let imageURL = try documentPath(fileName: artwork.imageFileName, create: true)
        try imageData.write(to: imageURL, options: .atomic)

        var library = loadLibrary()
        if library.findIndex(artwork.id) == nil {
            library.addItem(artwork)
        }

        do {
            try saveJSON(fileName: saveFileName, value: library)
        } catch {
            // This cleanup is not in the tutorial. It prevents an unlisted PNG
            // from being left behind when saving artworks.json fails.
            try? remove(fileName: artwork.imageFileName)
            throw error
        }

        return library
    }

    static func image(for artwork: LightArtwork) -> UIImage? {
        guard let imageURL = try? documentPath(fileName: artwork.imageFileName) else {
            return nil
        }
        return UIImage(contentsOfFile: imageURL.path)
    }

    static func delete(artwork: LightArtwork) throws -> LightArtworkLibrary {
        var library = loadLibrary()

        // Adapted from Document.deleteItem(id:) in the reference repository.
        library.deleteItem(id: artwork.id)
        try saveJSON(fileName: saveFileName, value: library)
        // The reference helper treats removal as best-effort. Once the JSON
        // record is gone, a missing PNG should not make the UI restore the row.
        try? remove(fileName: artwork.imageFileName)
        return library
    }
}
