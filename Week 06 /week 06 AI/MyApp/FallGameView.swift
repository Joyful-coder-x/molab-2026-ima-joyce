import SwiftUI
import Observation
import CoreMotion

#if os(iOS)
// MARK: - Fall / Observable Service vs State Value
// Fall 起点来自原作业注明的 CoreMotion gravity-ball tutorial：
// https://suryadevsingh24032000.medium.com/creating-an-interactive-gravity-ball-animation-in-swiftui-with-coremotion-f918cfe1eb09
// 本版重写输入服务与回合任务。
// MotionInput 单独成 class 但仍在同一个文件：CMMotionManager 需要管理启停和回调。
// View 保留输入对象身份，回调只更新输入值，游戏规则仍在 View。
@MainActor
@Observable
final class MotionInput {
    var x = 0.0
    var y = 0.0
    private let manager = CMMotionManager()
    var available: Bool { manager.isDeviceMotionAvailable }

    func start() {
        stop()
        guard available else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            // callback 不是 async function；先取 Double，再交回 MainActor。
            guard let gravity = motion?.gravity else { return }
            let x = gravity.x
            let y = gravity.y
            Task { @MainActor [weak self] in
                self?.x = x
                self?.y = y
            }
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        x = 0
        y = 0
    }
}

@MainActor
struct FallGameView: View {
    @Environment(GameHistory.self) private var history
    @Environment(RoundOptions.self) private var options
    @Environment(\.scenePhase) private var scenePhase
    @State private var input = MotionInput()
    @State private var useTilt = false
    @State private var ball = CGPoint.zero
    @State private var hole = CGPoint.zero
    @State private var score = 0
    @State private var isFalling = false
    @State private var phase = RoundPhase.ready
    @State private var roundID = 0
    @State private var startTime = Date()
    @State private var fallStarted: Date?
    @State private var lastTick = Date()
    @State private var duration: TimeInterval = 60
    @State private var remaining = 60
    private let radius: CGFloat = 145
    private let ballRadius: CGFloat = 25
    private let holeRadius: CGFloat = 38

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Text("Score: \(score)").font(.title2)
                Text("Time: \(clockText(remaining))").monospacedDigit()
                Toggle("Use Tilt", isOn: $useTilt)
                    .disabled(!input.available || phase == .playing)
                Text(input.available ? "Tilt mode or drag the ball." : "No motion sensor: drag the ball.")
                    .font(.footnote)
                if phase != .playing {
                    Text(phase == .ready ? "Ready?" : "Round finished — Score: \(score)")
                    Button(phase == .ready ? "Start" : "Play Again") { startRound() }
                        .buttonStyle(.borderedProminent)
                }
                NavigationLink("Fall Status & Results") { FallStatusView(score: score) }
                    .buttonStyle(.bordered)
                ZStack {
                    Circle().stroke(.gray, lineWidth: 2)
                    Circle().fill(.black)
                        .frame(width: holeRadius * 2, height: holeRadius * 2)
                        .offset(x: hole.x, y: hole.y)
                    Circle().fill(.blue)
                        .frame(width: ballRadius * 2, height: ballRadius * 2)
                        .scaleEffect(isFalling ? 0 : 1)
                        .opacity(isFalling ? 0 : 1)
                        .offset(x: ball.x, y: ball.y)
                }
                .frame(width: radius * 2, height: radius * 2)
                .contentShape(Circle())
                .gesture(DragGesture(minimumDistance: 0).onChanged { value in
                    guard phase == .playing, !useTilt, !isFalling else { return }
                    guard Date().timeIntervalSince(startTime) < duration else {
                        finishRound()
                        return
                    }
                    ball = bounded(CGPoint(x: value.location.x - radius,
                                           y: value.location.y - radius))
                    checkForFall()
                })
                .opacity(phase == .playing ? 1 : 0.45)
            }.padding()
        }
        .navigationTitle("Fall")
        .task(id: roundID) { await runRound() }
        .onDisappear { finishRound(); input.stop() }
        .onChange(of: scenePhase) { _, value in
            if value != .active { finishRound(); input.stop() }
        }
    }

    private func startRound() {
        input.stop()
        score = 0
        ball = .zero
        isFalling = false
        fallStarted = nil
        spawnHole()
        duration = TimeInterval(options.duration)
        remaining = options.duration
        startTime = Date()
        lastTick = startTime
        phase = .playing
        if useTilt { input.start() }
        roundID += 1
    }

    // OLD: Timer? + fallTimer? 需要分别 invalidate。
    // NEW: 一个 .task(id:) 循环统一处理剩余时间、移动和落洞后的等待。
    // WHY: 工作跟随 View 生命周期时，task 的自动取消和 async 顺序更容易表达。
    // Timer 仍适合已有 callback 型 API；两者都不保证精确按间隔执行。
    // 因此倒计时基于 Date 的差值；不通过循环次数计算已过去多少秒。
    private func runRound() async {
        while !Task.isCancelled && phase == .playing {
            let now = Date()
            let elapsed = now.timeIntervalSince(startTime)
            remaining = max(0, Int(ceil(duration - elapsed)))
            if elapsed >= duration { finishRound(); return }
            let delta = min(0.05, max(0, now.timeIntervalSince(lastTick)))
            lastTick = now
            if isFalling {
                if let began = fallStarted, now.timeIntervalSince(began) >= 0.25 {
                    score += 1
                    ball = .zero
                    spawnHole()
                    withAnimation(.easeOut(duration: 0.25)) { isFalling = false }
                    fallStarted = nil
                }
            } else if useTilt {
                // delta time 让速度随实际间隔变化，降低帧率改变时的速度差异。
                ball = bounded(CGPoint(x: ball.x + CGFloat(input.x * 900 * delta),
                                       y: ball.y - CGFloat(input.y * 900 * delta)))
                checkForFall()
            }
            do { try await Task.sleep(for: .milliseconds(16)) }
            catch { return }
        }
    }

    private func bounded(_ point: CGPoint) -> CGPoint {
        let distance = hypot(point.x, point.y)
        let limit = radius - ballRadius
        guard distance > limit else { return point }
        return CGPoint(x: point.x / distance * limit, y: point.y / distance * limit)
    }

    private func checkForFall() {
        guard !isFalling,
              hypot(ball.x - hole.x, ball.y - hole.y) <= holeRadius - ballRadius else { return }
        fallStarted = Date()
        withAnimation(.easeIn(duration: 0.25)) {
            ball = hole
            isFalling = true
        }
    }

    private func spawnHole() {
        // 避开中心：避免 reset 后小球一出现就在洞内。
        let distance = CGFloat.random(in: 60...(radius - holeRadius))
        let angle = CGFloat.random(in: 0...(2 * .pi))
        hole = CGPoint(x: cos(angle) * distance, y: sin(angle) * distance)
    }

    private func finishRound() {
        guard phase == .playing else { return }
        phase = .finished
        remaining = 0
        isFalling = false
        fallStarted = nil
        input.stop()
        history.add(gameID: "fall", score: score,
                    duration: min(duration, max(0, Date().timeIntervalSince(startTime))))
    }
}


private func clockText(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
#else
@MainActor
struct FallGameView: View {
    var body: some View {
        Text("Fall requires an iPhone or iPad motion sensor.")
            .navigationTitle("Fall")
    }
}
#endif
