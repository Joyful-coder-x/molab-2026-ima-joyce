import Observation

// MARK: - Observable Settings / Bindable vs Binding
@MainActor
@Observable
final class RoundOptions {
    var duration = 60
    // 此处故意是运行期设置：关掉 app 后恢复 60，便于与 @AppStorage 作比较。
}

enum RoundPhase: Equatable {
    case ready, playing, finished
    // OLD: gameState + hasPlayedRound 两个 Bool。
    // NEW: 一个 enum 表达三个互斥阶段，避免 true/false 组合含义不明确。
}

