import CoreMotion
import SwiftUI

// Gravity-controlled ball adapted from Suryadevsingh's SwiftUI
// CoreMotion tutorial:
// https://suryadevsingh24032000.medium.com/creating-an-interactive-gravity-ball-animation-in-swiftui-with-coremotion-f918cfe1eb09
// Extended into a timed ball-and-hole game with scoring.

struct PaintGameView: View {
    @State private var motionManager = CMMotionManager()
    @State private var ballPosition = CGPoint(x: 0, y: 0)
    @State private var holePosition = CGPoint(x: 0, y: 0)
    @State private var score = 0
    @State private var isFalling = false
    // Adapted from BallGameView for separate one-minute Fall rounds.
    @State private var startTime = Date()
    @State private var gameState = false
    @State private var hasPlayedRound = false
    @State private var timer: Timer?
    @State private var fallTimer: Timer?
    @State private var timeRemaining = 60
    @State private var results = GameResultStore.load()

    private let circleRadius: CGFloat = 150
    private let ballRadius: CGFloat = 25
    private let holeRadius: CGFloat = 38
    private let roundDuration: TimeInterval = 60

    var body: some View {
        VStack(spacing: 24) {
            Text("Score: \(score)")
            Text("Time: \(formattedTimeRemaining)")

            if gameState {
                Text("Tilt the phone and move the ball into the hole")
                    .foregroundStyle(.secondary)
            } else if hasPlayedRound {
                VStack {
                    Text("Game Over!")
                    Text("Final score: \(score)")
                }
                .padding()
                .background(Color(red: 0.8, green: 0.65, blue: 0.95))
            }

            if !gameState {
                Button(hasPlayedRound ? "Play Again" : "Start") {
                    startRound()
                }
                .buttonStyle(.borderedProminent)
            }

            NavigationLink("Fall Status & Results") {
                FallStatusView(score: score, results: results)
            }
            .buttonStyle(.borderedProminent)

            // Circular board and moving ball adapted from the gravity-ball tutorial.
            // Added a randomly positioned hole as the scoring target.
            ZStack {
                Circle()
                    .stroke(Color.gray, lineWidth: 2)

                Circle()
                    .fill(Color.black)
                    .frame(width: holeRadius * 2, height: holeRadius * 2)
                    .offset(x: holePosition.x, y: holePosition.y)

                Circle()
                    .fill(Color.blue)
                    .frame(width: ballRadius * 2, height: ballRadius * 2)
                    .scaleEffect(isFalling ? 0 : 1)
                    .opacity(isFalling ? 0 : 1)
                    .offset(x: ballPosition.x, y: ballPosition.y)
            }
            .frame(width: circleRadius * 2, height: circleRadius * 2)
            .opacity(gameState ? 1 : 0.45)
        }
        .padding()
        .navigationTitle("Fall")
        // Starts phone-tilt tracking while this view is open.
        .onAppear {
            startMotionUpdates()
        }
        .onDisappear {
            stopUpdates()
        }
    }

    private var formattedTimeRemaining: String {
        String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    // Adapted from BallGameView; resets Fall-specific state.
    private func startRound() {
        score = 0
        ballPosition = CGPoint(x: 0, y: 0)
        isFalling = false
        spawnHole()
        timeRemaining = Int(roundDuration)
        startTime = Date()
        gameState = true
        startTimer()
    }

    private func startMotionUpdates() {
        // Adapted from the gravity-ball tutorial.
        // Reads CoreMotion gravity updates to control the ball.
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { motion, _ in
                if let gravity = motion?.gravity {
                    updateBallPosition(
                        gravityX: gravity.x,
                        gravityY: gravity.y
                    )
                }
            }
        }
    }

    private func updateBallPosition(gravityX: Double, gravityY: Double) {
        // Adapted from the gravity-ball tutorial.
        // Converts gravity into movement and restricts the ball to the board.
        // Uses hypot() instead of the tutorial's distanceBetween() helper.
        if !gameState || isFalling {
            return
        }

        let x = CGFloat(gravityX) * 30
        let y = CGFloat(gravityY) * 30
        let newX = ballPosition.x + x
        let newY = ballPosition.y - y
        let maximumOffset = circleRadius - ballRadius
        let distanceFromCenter = hypot(newX, newY)

        if distanceFromCenter <= maximumOffset {
            ballPosition = CGPoint(x: newX, y: newY)
        } else {
            let angle = atan2(newY, newX)
            let boundedX = maximumOffset * cos(angle)
            let boundedY = maximumOffset * sin(angle)
            ballPosition = CGPoint(x: boundedX, y: boundedY)
        }

        checkForFall()
    }

    private func checkForFall() {
        // Scores when the ball fits fully inside the hole.
        let xDistance = ballPosition.x - holePosition.x
        let yDistance = ballPosition.y - holePosition.y
        let distance = hypot(xDistance, yDistance)
        let perfectOverlapDistance = holeRadius - ballRadius

        if distance > perfectOverlapDistance {
            return
        }

        isFalling = true

        // Animates the fall before resetting the ball and hole.
        withAnimation(.easeIn(duration: 0.25)) {
            ballPosition = holePosition
        }

        fallTimer?.invalidate()
        fallTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            if gameState {
                score += 1
                ballPosition = CGPoint(x: 0, y: 0)
                spawnHole()

                withAnimation(.easeOut(duration: 0.25)) {
                    isFalling = false
                }
            } else {
                isFalling = false
            }
        }
    }

    private func spawnHole() {
        // Places each new hole randomly inside the board.
        let maximumOffset = circleRadius - holeRadius
        let angle = CGFloat.random(in: 0...(2 * .pi))
        let distance = sqrt(CGFloat.random(in: 0...1)) * maximumOffset

        holePosition = CGPoint(
            x: cos(angle) * distance,
            y: sin(angle) * distance
        )
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            let elapsed = Date().timeIntervalSince(startTime)
            timeRemaining = max(0, Int(ceil(roundDuration - elapsed)))

            if elapsed >= roundDuration {
                finishRound()
            }
        }
    }

    private func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        fallTimer?.invalidate()
    }

    // Adapted from BallGameView; saves under "fall" to separate results.
    private func finishRound() {
        if !gameState {
            return
        }

        timer?.invalidate()
        fallTimer?.invalidate()
        gameState = false
        hasPlayedRound = true
        isFalling = false
        timeRemaining = 0
        results.insert(
            GameResult(
                gameID: "fall",
                score: score,
                duration: roundDuration
            ),
            at: 0
        )
        GameResultStore.save(results)
    }
}

#Preview {
    NavigationStack {
        PaintGameView()
    }
}
