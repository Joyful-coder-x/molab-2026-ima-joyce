//
//  week_07_photo_editApp.swift
//  week 07 photo edit
//
//  Created by Joyce Li on 10/22/26.
//

import SwiftUI

@main
struct week_07_photo_editApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                HomeView()
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            HomeView()
        }
    }
}
