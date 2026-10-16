import SwiftUI
import AudioToolbox

// MARK: - Catch / Local State + Shared Model
@MainActor
struct CatchGameView: View {
    @Environment(GameHistory.self) private var history
    @Environment(RoundOptions.self) private var options
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("learning.soundEnabled") private var soundEnabled = true

    // View 仍拥有游戏局部状态；共享 history 不等于共享每个球的位置。
    @State private var score = 0
    @State private var balls = [
        Ball(color: .red, x: -100, y: 0),
        Ball(color: .blue, x: 0, y: 0),
        Ball(color: .yellow, x: 100, y: 0)
    ]
    @State private var phase = RoundPhase.ready
    @State private var startTime = Date()
    @State private var duration: TimeInterval = 60
    @State private var remaining = 60
    @State private var roundID = 0
    @State private var aimPoint = CGPoint.zero
    private let width: CGFloat = 320
    private let height: CGFloat = 400

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Score: \(score)").font(.title2)
                Text("Time: \(clockText(remaining))").monospacedDigit()
                if phase == .playing {
                    Text("Catch the balls!")
                } else {
                    Text(phase == .ready ? "Ready?" : "Round finished — Score: \(score)")
                    Button(phase == .ready ? "Start" : "Play Again") { startRound() }
                        .buttonStyle(.borderedProminent)
                }
                NavigationLink("Ball Status & Results") {
                    CatchStatusView(balls: balls)
                }
                .buttonStyle(.bordered)

                ZStack {
                    Rectangle().fill(.gray)
                        .frame(width: 16, height: 90)
                        .rotationEffect(gunAngle, anchor: .bottom)
                        .offset(y: 130)
                        .allowsHitTesting(false)
                    Circle().fill(.gray).frame(width: 40, height: 40)
                        .offset(y: 175).allowsHitTesting(false)
                    ForEach(balls.indices, id: \.self) { i in
                        Circle().fill(balls[i].color)
                            .frame(width: 64, height: 64)
                            .offset(x: balls[i].x, y: balls[i].y)
                            .onTapGesture { catchBall(at: i) }
                            .task(id: roundID) { await moveBall(at: i) }
                    }
                    Circle().stroke(.black, lineWidth: 2).frame(width: 36, height: 36)
                        .offset(x: aimPoint.x, y: aimPoint.y).allowsHitTesting(false)
                    Rectangle().fill(.black).frame(width: 2, height: 46)
                        .offset(x: aimPoint.x, y: aimPoint.y).allowsHitTesting(false)
                    Rectangle().fill(.black).frame(width: 46, height: 2)
                        .offset(x: aimPoint.x, y: aimPoint.y).allowsHitTesting(false)
                }
                .frame(width: width, height: height)
                .background(Color.gray.opacity(0.08))
                .clipped()
                .simultaneousGesture(DragGesture(minimumDistance: 0).onChanged { value in
                    aimPoint = CGPoint(x: value.location.x - width / 2,
                                       y: value.location.y - height / 2)
                })
                .opacity(phase == .playing ? 1 : 0.45)
                // Comparison: 原版显示不断扩大的 range 框；这里限制移动到可点击的 board 内。
                // level 仍控制速度和范围，但范围达到边缘后不再扩大。
            }
            .padding()
        }
        .navigationTitle("Catch")
        .task(id: roundID) { await runCountdown() }
        .onDisappear { finishRound() }
        .onChange(of: scenePhase) { _, value in
            if value != .active { finishRound() }
        }
    }

    private var gunAngle: Angle {
        .radians(Double(atan2(aimPoint.y - 175, aimPoint.x)) + .pi / 2)
    }

    private func startRound() {
        score = 0
        for i in balls.indices {
            balls[i].x = CGFloat(i - 1) * 100
            balls[i].y = 0
            balls[i].level = 1
            balls[i].catchCount = 0
        }
        aimPoint = .zero
        duration = TimeInterval(options.duration)
        remaining = options.duration
        startTime = Date()
        phase = .playing
        roundID += 1
        // 每局开始读取 options 的值；局中改设置不会突然改变当前局时长。
    }

    private func catchBall(at index: Int) {
        guard phase == .playing else { return }
        guard Date().timeIntervalSince(startTime) < duration else {
            finishRound()
            return
        }
        score += 1
        balls[index].catchCount += 1
        if soundEnabled { AudioServicesPlaySystemSound(1104) }
        if balls[index].catchCount % 3 == 0 { balls[index].level += 1 }
    }

    private func moveBall(at index: Int) async {
        while !Task.isCancelled && phase == .playing {
            let level = balls[index].level
            let speed = max(0.25, 1.2 - 0.15 * Double(level - 1))
            let range = CGFloat(100 + 50 * (level - 1))
            let xLimit = min(range, width / 2 - 32)
            let yLimit = min(range, height / 2 - 32)
            withAnimation(.linear(duration: speed)) {
                balls[index].x = CGFloat.random(in: -xLimit...xLimit)
                balls[index].y = CGFloat.random(in: -yLimit...yLimit)
            }
            do { try await Task.sleep(for: .seconds(speed)) }
            catch { return }
        }
    }

    private func runCountdown() async {
        while !Task.isCancelled && phase == .playing {
            let elapsed = Date().timeIntervalSince(startTime)
            remaining = max(0, Int(ceil(duration - elapsed)))
            if elapsed >= duration { finishRound(); return }
            do { try await Task.sleep(for: .milliseconds(100)) }
            catch { return }
        }
    }

    private func finishRound() {
        guard phase == .playing else { return }
        phase = .finished
        remaining = 0
        history.add(gameID: "ball", score: score,
                    duration: min(duration, max(0, Date().timeIntervalSince(startTime))))
        // guard 防止 timeout、onDisappear、scenePhase 重复存同一局。
        // 提前离开记录实际时长；此版本选择结束，不是 pause/resume。
    }
}


private func clockText(_ seconds: Int) -> String {
    String(format: "%d:%02d", seconds / 60, seconds % 60)
}
