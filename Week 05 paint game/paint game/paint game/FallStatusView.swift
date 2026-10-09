//
//  FallStatusView.swift
//  paint game
//
//  Created by Joyce Li on 10/9/26.
//
import SwiftUI

// Adapted from StatusView to show only Fall results.
struct FallStatusView: View {
    let score: Int
    let results: [GameResult]

    private var fallResults: [GameResult] {
        // Keeps Ball and Fall histories separate.
        results.filter { $0.gameID == "fall" }
    }

    var body: some View {
        List {
            Section("Current Round") {
                HStack {
                    Text("Holes reached")

                    Spacer()

                    Text("\(score)")
                }
            }

            Section("Saved Fall Rounds") {
                if fallResults.isEmpty {
                    Text("No completed rounds yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(fallResults) { result in
                        HStack {
                            Text(result.playedAt, format: .dateTime.month().day().hour().minute())

                            Spacer()

                            Text("Score: \(result.score)")
                        }
                    }
                }
            }
        }
        .navigationTitle("Fall Status")
    }
}
