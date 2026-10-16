import SwiftUI

// MARK: - Home / Navigation
// 保留 NavigationStack + NavigationLink：当前菜单进入游戏的层级已经足够清楚。
// Router 是可选的集中跳转模型，不是共享数据或文件保存的必要条件。
@MainActor
struct HomeView: View {
    @Environment(RoundOptions.self) private var options

    var body: some View {
        List {
            Section("Games") {
                NavigationLink("Catch the Balls") { CatchGameView() }
                NavigationLink("Fall") { FallGameView() }
            }
            Section("Settings") {
                NavigationLink("Round & Sound Settings") {
                    SettingsView(options: options)
                }
                Text("Next round: \(options.duration) seconds")
            }
            Section("History") {
                NavigationLink("All Results") { ResultsView(gameID: nil) }
                Text("Open results or leave a game to finish the round. Backgrounding also ends it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Game Room")
    }
}

@MainActor
struct SettingsView: View {
    // @Bindable 不创建对象，只为传入的 @Observable 对象提供 $property。
    // WHY: 表单需要编辑 model 的属性；只显示属性时普通 let 就够了。
    @Bindable var options: RoundOptions
    @AppStorage("learning.soundEnabled") private var soundEnabled = true

    var body: some View {
        Form {
            Section("Round Duration — Session Only") {
                DurationPicker(seconds: $options.duration)
                Text("Changes apply to the next round. Resets after app restart.")
                    .font(.footnote)
            }
            Section("Sound — Saved Preference") {
                Toggle("Catch Sound", isOn: $soundEnabled)
                Text("This preference remains after restarting the app.")
                    .font(.footnote)
            }
        }
        .navigationTitle("Settings")
    }
}

struct DurationPicker: View {
    // @Binding 不拥有原始值；它连接父级提供的读写位置。
    // WHY: reusable control 不需要知道值来自 @State、@Bindable 还是其他 Binding。
    // OLD let seconds: Int 只能读，不能把修改写回父级。
    @Binding var seconds: Int

    var body: some View {
        Picker("Duration", selection: $seconds) {
            Text("30 seconds").tag(30)
            Text("60 seconds").tag(60)
            Text("120 seconds").tag(120)
        }
    }
}

