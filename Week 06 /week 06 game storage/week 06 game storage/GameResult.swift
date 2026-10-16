import Foundation

struct GameResult: Codable, Identifiable {
    let id: UUID
    let gameID: String
    let score: Int
    let playedAt: Date
    let duration: TimeInterval

    init(
        id: UUID = UUID(),
        gameID: String,
        score: Int,
        playedAt: Date = Date(),
        duration: TimeInterval
    ) {
        self.id = id
        self.gameID = gameID
        self.score = score
        self.playedAt = playedAt
        self.duration = duration
    }
}

enum GameResultStore {
    private static let storageKey = "savedGameResults"

    static func load() -> [GameResult] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }

        return (try? JSONDecoder().decode([GameResult].self, from: data)) ?? []
    }

    static func save(_ results: [GameResult]) {
        guard let data = try? JSONEncoder().encode(results) else {
            return
        }

        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
