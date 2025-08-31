//
//  RouletteGameApp.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import Firebase

@main
struct RouletteGameApp: App {
    
    init() {
            FirebaseApp.configure()
        }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
