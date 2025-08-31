//
//  LoginVie.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct LoginView: View {
    @State private var isLoggedIn = false
    @State private var username = ""
    
    var body: some View {
        Group {
            if isLoggedIn {
                TabBarView()
            } else {
                VStack(spacing: 20) {
                    Text("Roulette Game")
                        .font(.largeTitle)
                        .bold()
                    
                    TextField("Enter username", text: $username)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    Button("Play Anonymously") {
                        anonymousLogin()
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding()
            }
        }
        .onAppear {
            checkAuthState()
        }
    }
    
    func checkAuthState() {
        if Auth.auth().currentUser != nil {
            isLoggedIn = true
        }
    }
    
    func anonymousLogin() {
        Auth.auth().signInAnonymously { result, error in
            if let user = result?.user {
                let db = Firestore.firestore()
                let userRef = db.collection("users").document(user.uid)
                
                userRef.setData([
                    "username": username.isEmpty ? "Player" : username,
                    "balance": 2000,
                    "winCount": 0,
                    "totalCount": 0
                ]) { error in
                    if let error = error {
                        print("Error creating user:", error.localizedDescription)
                    } else {
                        isLoggedIn = true
                    }
                }
            } else if let error = error {
                print("Login error:", error.localizedDescription)
            }
        }
    }
}

