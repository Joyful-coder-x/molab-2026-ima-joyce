import SwiftUI

// MARK: - Models / Struct vs Class
// struct 表示一条记录，复制后是独立值；class 表示有共同身份的共享对象。
// Codable 负责转换，不决定保存位置；Identifiable 负责给 ForEach 稳定身份。
struct GameResult: Codable, Identifiable {
    let id: UUID
    let gameID: String
    let score: Int
    let playedAt: Date
    let duration: TimeInterval

    init(id: UUID = UUID(), gameID: String, score: Int,
         playedAt: Date = Date(), duration: TimeInterval) {
        self.id = id
        self.gameID = gameID
        self.score = score
        self.playedAt = playedAt
        self.duration = duration
    }
}

struct Ball: Identifiable {
    let id = UUID()
    let color: Color
    var x: CGFloat
    var y: CGFloat
    var level = 1
    var catchCount = 0
}

