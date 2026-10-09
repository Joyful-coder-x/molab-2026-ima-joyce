
import SwiftUI

struct HomeView: View {
    var body: some View {
        VStack(spacing: 30) {
            VStack(spacing: 10) {
                Text("Game Room")

                Text("Choose a game to play")
                    .foregroundStyle(.secondary)
            }
            .padding()

            List {
                Section("Available Games") {
                    NavigationLink("Catch the Balls") {
                        BallGameView()
                    }

                    Text("Catch moving balls before time runs out")
                        .foregroundStyle(.secondary)
                }

                Section {
                    NavigationLink("Fall") {
                        PaintGameView()
                    }

                    Text("Tilt the ball into the randomly placed hole")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Games")
        }
    }
}


// Display the game in Xcode Preview.
#Preview {
    BallGameView()
}
