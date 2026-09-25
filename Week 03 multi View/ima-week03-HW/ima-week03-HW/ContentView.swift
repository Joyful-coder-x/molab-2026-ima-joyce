import SwiftUI
// 3 random moving ball that "level" up when clicked 

struct Ball: Identifiable {
    // Identifiable gives each ball its own identity.
    let id = UUID()

    let color: Color
    var x: CGFloat
    var y: CGFloat
    var level: Int
    var catchCount: Int
}

struct ContentView: View {
    @State private var score = 0
    
    // It needs @State because their positions, levels, and counts change.
    @State private var balls: [Ball] = [
        // Remember the commas between array items.
        Ball(color: .red, x: -100, y: 0, level: 1, catchCount: 0),
        Ball(color: .blue, x: 0, y: 0, level: 1, catchCount: 0),
        Ball(color: .yellow, x: 100, y: 0, level: 1, catchCount: 0)
    ]
    
    private let catchesPerLevel = 3
    
    
    // "some View" means it returns SwiftUI display content.
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("Score: \(score)")
                
                NavigationLink("Ball Status") {
                    StatusView(balls: balls)
                }
                
                // ZStack gives all the balls the same center. A VStack would put each ball in a different row.
                ZStack {
                    // ForEach creates one Circle view for each index. SwiftUI 的 ForEach 是描述屏幕内容：告诉 SwiftUI“对每个 i，显示一套边框和球”。id: \.self 让 SwiftUI识别哪一套内容属于哪个 index，以便更新。
                    ForEach(balls.indices, id: \.self) { i in
                        Rectangle()
                            .stroke(balls[i].color.opacity(0.5), lineWidth: 2)
                            .frame(
                                width: 2 * CGFloat(100 + 50 * (balls[i].level - 1)) + 80,
                                height: 2 * CGFloat(100 + 50 * (balls[i].level - 1)) + 80
                            )
                        
                        
                        Circle()
                            .fill(balls[i].color)
                        
                        // fill comes before offset because fill
                        // is a modifier for a Shape.
                            .frame(width: 80, height: 80)
                        
                            .offset(x: balls[i].x, y: balls[i].y)
                        
                        // Tapping changes the score and THIS ball's
                        // catch count. It does not move the ball.
                            .onTapGesture {
                                score += 1
                                balls[i].catchCount += 1
                                
                                if balls[i].catchCount % catchesPerLevel == 0 {
                                    balls[i].level += 1
                                }
                            }
                        
                        // Each Circle gets its own task.
                            .task {
                                // Keep picking destinations while this ball's view remains on screen.
                                while !Task.isCancelled {
                                    let level = balls[i].level
                                    
                                    // Animation duration is measured in seconds.
                                    let duration = max(
                                        0.25,
                                        1.0 - 0.15 * Double(level - 1)
                                    )
                                    
                                    // CGFloat is used for screen distances.
                                    let range = CGFloat(
                                        100 + 50 * (level - 1)
                                    )
                                    
                                    withAnimation(.linear(duration: duration)) {
                                        balls[i].x = CGFloat.random(in: -range...range)
                                        balls[i].y = CGFloat.random(in: -range...range)
                                    }
                                    
                                    try? await Task.sleep(for: .seconds(duration))
                                }
                            }
                    }
                }
            }
        }
    }
}
    
    
    struct StatusView: View {
        // 接收游戏当前的球数组，用来显示数据。
        let balls: [Ball]
        
        var body: some View {
            List {
                ForEach(balls.indices, id: \.self) { i in
                    HStack {
                        Circle()
                            .fill(balls[i].color)
                            .frame(width: 24, height: 24)
                        
                        Text("Ball \(i + 1)")
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Level: \(balls[i].level)")
                            Text("Catches: \(balls[i].catchCount)")
                        }
                    }
                }
            }
            .navigationTitle("Ball Status")
        }
    }
        
        

#Preview {
    ContentView()
}
