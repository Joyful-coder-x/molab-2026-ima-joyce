import Foundation
import Observation

// MARK: - Observable / JSON File Storage
// @MainActor: 把 UI 相关的共享状态限定在 MainActor，方便明确修改发生的位置。
// @Observable: 让 SwiftUI 追踪 body 实际读取的属性；它本身不会写硬盘。
// private(set): 外部可以读 results，但新增记录要经过 add()，集中保存规则。
@MainActor
@Observable
final class GameHistory {
    private(set) var results: [GameResult] = []
    private(set) var errorMessage: String?
    private var writesAllowed = true

    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory,
                                in: .userDomainMask)[0]
            .appendingPathComponent("gameHistory.json")
    }

    init() {
        load()
    }

    func add(gameID: String, score: Int, duration: TimeInterval) {
        results.insert(GameResult(gameID: gameID, score: score,
                                  duration: duration), at: 0)
        save()
    }

    func retrySave() {
        save()
    }

    private func load() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                results = try JSONDecoder().decode([GameResult].self, from: data)
            } else if let oldData = UserDefaults.standard.data(forKey: "savedGameResults") {
                // Migration: 同一个 app 中可导入旧版 UserDefaults history。
                // 新建 project 使用不同 sandbox，不会自动读到旧 app 的记录。
                results = try JSONDecoder().decode([GameResult].self, from: oldData)
                save()
                // 保留旧 key 作为备份，不在教学版本中自动删除。
            }
        } catch {
            writesAllowed = false
            errorMessage = "History could not load. Existing data is protected. \(error.localizedDescription)"
        }
    }

    private func save() {
        guard writesAllowed else { return }
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(results)
            try data.write(to: fileURL, options: .atomic)
            errorMessage = nil
        } catch {
            errorMessage = "History is in memory but could not save. \(error.localizedDescription)"
        }
    }
    // WHY USE THIS VERSION: 文件适合一组记录、独立导出和检查；UserDefaults 适合小型设置。
    // atomic 降低写到一半留下残缺文件的风险；不等于能解决所有数据丢失情况。
    // Tradeoff: 文件需要自己处理路径、错误、格式变化；比原来代码多。
    // 本例记录量小，直接在 MainActor 写文件。大量数据时应改为异步存储设计。
}

