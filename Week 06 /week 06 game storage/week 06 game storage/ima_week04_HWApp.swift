//
//  week_06_game_storageApp.swift
//  week 06 game storage
//
//  Created by Joyce Li on 10/15/26.
//  build of from week 05


// Start a fresh round:
// score = 0
// each ball: level = 1, catchCount = 0, reset x/y
// startTime = Date()
// gameState = true


import SwiftUI

@main
struct week_06_game_storageApp: App {
    var body: some Scene {
        WindowGroup {
            // HomeView is the shared menu for all three games. The previous
            // ContentView reference had no matching type in this project.
            NavigationStack {
                HomeView()
            }
        }
    }
}
