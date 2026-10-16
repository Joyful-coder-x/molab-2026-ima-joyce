import SwiftUI

// MARK: - Read-only Input vs Shared Environment
@MainActor
struct CatchStatusView: View {
    // let 继续用于传入的只读数据，不为了练习而全部换成 Binding。
    // 父 View 重算可传入新值；let 不是“UI 永远不更新”的意思。
    let balls: [Ball]

    var body: some View {
        List {
            Section("Last Round") {
                ForEach(Array(balls.enumerated()), id: \.element.id) { index, ball in
                    HStack {
                        Circle().fill(ball.color).frame(width: 20, height: 20)
                        Text("Ball \(index + 1)")
                        Spacer()
                        Text("Level \(ball.level) · Catches \(ball.catchCount)")
                    }
                }
            }
            HistorySections(gameID: "ball")
        }.navigationTitle("Catch Status")
    }
}

@MainActor
struct FallStatusView: View {
    let score: Int
    var body: some View {
        List {
            Section("Last Round") { Text("Holes reached: \(score)") }
            HistorySections(gameID: "fall")
        }.navigationTitle("Fall Status")
    }
}

@MainActor
struct ResultsView: View {
    let gameID: String?
    var body: some View {
        List { HistorySections(gameID: gameID) }
            .navigationTitle("Saved Results")
    }
}

@MainActor
struct HistorySections: View {
    @Environment(GameHistory.self) private var history
    let gameID: String?

    private var filtered: [GameResult] {
        guard let gameID else { return history.results }
        return history.results.filter { $0.gameID == gameID }
    }

    var body: some View {
        Section("Saved Rounds") {
            if filtered.isEmpty { Text("No completed rounds yet.") }
            ForEach(filtered) { result in
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(result.gameID == "ball" ? "Catch" : "Fall") · Score: \(result.score)")
                    Text(result.playedAt, format: .dateTime.month().day().hour().minute())
                        .font(.caption).foregroundStyle(.secondary)
                    Text("Played: \(Int(result.duration)) seconds")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        if let message = history.errorMessage {
            Section("Storage Message") {
                Text(message).foregroundStyle(.red)
                Button("Retry Save") { history.retrySave() }
                Text("If loading failed, saving stays blocked to protect the existing data.")
                    .font(.caption)
            }
        }
    }
    // WHY explicit parameter vs Environment:
    // gameID 是这个组件的明确配置；history 是很多页面共同依赖的服务。
    // 也可显式传 history；小型层级依赖更直观，Environment 则减少逐层转交。
}

private func clockText(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}

// MARK: - Preview / Environment Injection
#Preview {
    NavigationStack { HomeView() }
        .environment(GameHistory())
        .environment(RoundOptions())
}
