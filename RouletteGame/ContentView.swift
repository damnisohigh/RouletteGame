//
//  ContentView.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import Firebase
import FirebaseAuth
import FirebaseFirestore

struct ContentView: View {
    @State private var isSignedIn = false
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if isSignedIn {
                TabBarView()
            } else {
                VStack {
                    ProgressView("Signing In...")
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                }
                .onAppear {
                    AuthService.shared.signInAnonymously { result in
                        switch result {
                        case .success(_):
                            DispatchQueue.main.async {
                                isSignedIn = true
                            }
                        case .failure(let error):
                            DispatchQueue.main.async {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                }
            }
        }
    }
}
