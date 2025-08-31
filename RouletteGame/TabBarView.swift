//
//  TabBarView.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI

import SwiftUI

struct TabBarView: View {
    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Image(systemName: "gamecontroller.fill")
                    Text("Game")
                }
            
            RateView()
                .tabItem {
                    Image(systemName: "list.star")
                    Text("Rating")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gearshape.fill")
                    Text("Settings")
                }
        }
    }
}
#Preview {
    TabBarView()
}
