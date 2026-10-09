//
//  CatchStatusView.swift
//  ima-week04-HW
//
//  Created by Joyce Li on 9/29/26.
//

import SwiftUI

struct CatchStatusView: View {
    let balls: [Ball]
    let results: [GameResult]

    private var ballResults: [GameResult] {
        results.filter { $0.gameID == "ball" }
    }

    var body: some View {
        List {
            Section("Current Round") {
                ForEach(Array(balls.enumerated()), id: \.element.id) { index, ball in
                    HStack {
                        Circle()
                            .fill(ball.color)
                            .frame(width: 24, height: 24)

                        Text("Ball \(index + 1)")

                        Spacer()

                        VStack(alignment: .trailing) {
                            Text("Level: \(ball.level)")
                            Text("Catches: \(ball.catchCount)")
                        }
                    }
                }
            }

            Section("Saved Ball Rounds") {
                if ballResults.isEmpty {
                    Text("No completed rounds yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(ballResults) { result in
                        HStack {
                            Text(result.playedAt, format: .dateTime.month().day().hour().minute())

                            Spacer()

                            Text("Score: \(result.score)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Ball Status")
    }
}

