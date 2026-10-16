// GameRoomLearning.swift
// SwiftUI Learning Edition — Joyce's Catch + Fall
// Requirements: iOS 17+, Xcode 15+; iPhone / iPad app target.
// Run: 在新的 iOS App project 中删除默认 App 和 ContentView，加入本文件。
// 本文件已有唯一的 @main；不要同时加入原来的八个 Swift 文件。
// Motion: 真机 target 的 Info 中添加 Privacy - Motion Usage Description。
// Simulator: Fall 可关闭 Use Tilt，用拖动小球体验；无须额外图片或音频资源。
// Reading order: App → Models → Settings → Catch → Fall → Results.
// Topics/keywords 用英文；解释主要用中文。MARK 只分区，不创建额外文件。

import SwiftUI
import Observation
import CoreMotion
import AudioToolbox

// MARK: - App / Ownership
// OLD: 两个 game 各自 load 一份 results。
// NEW: App 用 @State 保留同一个 @Observable history，通过 environment 交给后代。
// WHY USE THIS VERSION: 多个页面需要共同修改同一份数据时，避免不同副本互相覆盖。
// 小型、独立页面仍可继续用本地 @State；不必把所有状态都放进共享 class。
@main
@MainActor
struct GameRoomLearningApp: App {
    @State private var history = GameHistory()
    @State private var options = RoundOptions()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
            .environment(history)
            .environment(options)
        }
    }
}

