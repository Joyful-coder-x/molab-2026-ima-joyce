//
//  BallGameView.swift
//  ima-week04-HW
//
//  Created by Joyce Li on 9/29/26.
//

import AudioToolbox
import SwiftUI

// Keep the original click-to-catch gameplay.
// Add a decorative crosshair that follows the player's pointing position.
// A gun at the bottom center rotates toward the crosshair.
// The decoration does not affect scoring or detect hits.

struct BallGameView: View {
    @State private var score = 0
    @State private var balls: [Ball] = [
        Ball(color: .red, x: -100, y: 0, level: 1, catchCount: 0),
        Ball(color: .blue, x: 0, y: 0, level: 1, catchCount: 0),
        Ball(color: .yellow, x: 100, y: 0, level: 1, catchCount: 0)
    ]
    @State private var startTime = Date()
    @State private var gameState = false
    @State private var hasPlayedRound = false
    @State private var roundID = 0
    @State private var timeRemaining = 60
    @State private var results = GameResultStore.load()
    @State private var aimPoint = CGPoint(x: 0, y: 0)

    // Game rules and fixed dimensions.
    private let catchesPerLevel = 3
    private let roundDuration: TimeInterval = 60
    private let startingXPositions: [CGFloat] = [-100, 0, 100]
    private let gameWidth: CGFloat = 340
    private let gameHeight: CGFloat = 440

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Score: \(score)")
                Text("Time: \(formattedTimeRemaining)")

                // NEW: Round messages and Start / Play Again controls.
                if gameState {
                    Text("Catch the balls!")
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

                NavigationLink("Ball Status & Results") {
                    StatusView(balls: balls, results: results)
                }

                // Layer the gun, balls, and crosshair.
                ZStack {
                    // NEW: Decorative gun and base.
                    Rectangle()
                        .fill(Color.gray)
                        .frame(width: 16, height: 110)
                        // Rotate around the gun's bottom pivot.
                        .rotationEffect(gunAngle, anchor: .bottom)
                        .offset(y: 145)
                        // Decoration lets touches pass through.
                        .allowsHitTesting(false)

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 45, height: 45)
                        .offset(y: 200)
                        .allowsHitTesting(false)

                    ForEach(balls.indices, id: \.self) { i in
                        Rectangle()
                            .stroke(balls[i].color.opacity(0.5), lineWidth: 2)
                            .frame(
                                width: 2 * CGFloat(100 + 50 * (balls[i].level - 1)) + 70,
                                height: 2 * CGFloat(100 + 50 * (balls[i].level - 1)) + 70
                            )

                        Circle()
                            .fill(balls[i].color)
                            .frame(width: 70, height: 70)
                            .offset(x: balls[i].x, y: balls[i].y)
                            .onTapGesture {
                                catchBall(at: i)
                            }
                            // Restart this ball's movement each round.
                            .task(id: roundID) {
                                await moveBall(at: i)
                            }
                    }

                    // NEW: Decorative crosshair.
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .offset(x: aimPoint.x, y: aimPoint.y)
                        .allowsHitTesting(false)

                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 2, height: 50)
                        .offset(x: aimPoint.x, y: aimPoint.y)
                        .allowsHitTesting(false)

                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 50, height: 2)
                        .offset(x: aimPoint.x, y: aimPoint.y)
                        .allowsHitTesting(false)
                }
                .frame(width: gameWidth, height: gameHeight)
                // NEW: Touch tracking moves the crosshair without replacing ball taps.
                .simultaneousGesture(
                    // Track presses immediately, not mouse hovering.
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            // Convert top-left coordinates to center offsets.
                            aimPoint = CGPoint(
                                x: value.location.x - gameWidth / 2,
                                y: value.location.y - gameHeight / 2
                            )
                        }
                )
                .opacity(gameState ? 1 : 0.45)
            }
            .padding()
            // Run one countdown task per round.
            .task(id: roundID) {
                await runTimer()
            }
        }
    }

    // Format seconds as minutes:seconds.
    private var formattedTimeRemaining: String {
        String(format: "%d:%02d", timeRemaining / 60, timeRemaining % 60)
    }

    // NEW: Calculate the gun's rotation toward the crosshair.
    private var gunAngle: Angle {
        let gunPoint = CGPoint(x: 0, y: 200)
        let xDistance = aimPoint.x - gunPoint.x
        let yDistance = aimPoint.y - gunPoint.y
        // Calculate direction and adjust for the upward-facing rectangle.
        return .radians(Double(atan2(yDistance, xDistance)) + .pi / 2)
    }

    // NEW: Reset the game and start another round.
    private func startRound() {
        score = 0

        // Reset each ball's position and progress.
        for i in balls.indices {
            balls[i].level = 1
            balls[i].catchCount = 0
            balls[i].x = startingXPositions[i]
            balls[i].y = 0
        }

        aimPoint = CGPoint(x: 0, y: 0)
        timeRemaining = Int(roundDuration)
        startTime = Date()
        gameState = true
        // Changing roundID cancels and restarts the round's tasks.
        roundID += 1
    }

    private func catchBall(at index: Int) {
        // Reject catches when the round is inactive or expired.
        guard gameState,
              Date().timeIntervalSince(startTime) < roundDuration else {
            return
        }

        score += 1
        balls[index].catchCount += 1
        AudioServicesPlaySystemSound(1104)

        if balls[index].catchCount % catchesPerLevel == 0 {
            balls[index].level += 1
        }
    }

    private func moveBall(at index: Int) async {
        while !Task.isCancelled && gameState {
            let level = balls[index].level
            let duration = max(0.25, 1.2 - 0.15 * Double(level - 1))
            let range = CGFloat(100 + 50 * (level - 1))

            withAnimation(.linear(duration: duration)) {
                balls[index].x = CGFloat.random(in: -range...range)
                balls[index].y = CGFloat.random(in: -range...range)
            }

            do {
                try await Task.sleep(for: .seconds(duration))
            } catch {
                // Exit when cancellation interrupts sleep.
                return
            }
        }
    }

    // NEW: One-minute countdown and automatic timeout.
    private func runTimer() async {
        guard gameState else {
            return
        }

        while !Task.isCancelled && gameState {
            // Measure elapsed real time instead of counting loop repetitions.
            let elapsed = Date().timeIntervalSince(startTime)
            // Round seconds upward and prevent negative remaining time.
            timeRemaining = max(0, Int(ceil(roundDuration - elapsed)))

            if elapsed >= roundDuration {
                finishRound()
                return
            }

            do {
                try await Task.sleep(for: .milliseconds(100))
            } catch {
                // Exit when cancellation interrupts sleep.
                return
            }
        }
    }

    // NEW: End the round and save its result.
    private func finishRound() {
        guard gameState else {
            return
        }

        gameState = false
        hasPlayedRound = true
        timeRemaining = 0
        results.insert(
            GameResult(
                gameID: "ball",
                score: score,
                duration: roundDuration
            ),
            at: 0
        )
        GameResultStore.save(results)
    }
}

// Display the game in Xcode Preview.
#Preview {
    BallGameView()
}
