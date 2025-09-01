//
//  SettingsView.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import FirebaseAuth
import StoreKit
import FirebaseFirestore

struct SettingsView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var showLogin = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 15) {
                    Button(action: logOut) {
                        HStack {
                            Image(systemName: "arrow.right.square")
                            Text("Log Out")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }

                    Button(action: deleteAccount) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Account")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                }
                .padding(.horizontal)

                Divider()
                    .padding(.vertical, 10)

                VStack(spacing: 15) {
                    Button(action: rateApp) {
                        HStack {
                            Image(systemName: "star.fill")
                            Text("Rate App")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.yellow)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }

                    Button(action: shareApp) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Share App")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 4)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationTitle("Settings")
            .fullScreenCover(isPresented: $showLogin) {
                LoginView()
            }
        }
    }

    func logOut() {
        do {
            try Auth.auth().signOut()
            showLogin = true
        } catch {
            print("Error signing out:", error.localizedDescription)
        }
    }

    func deleteAccount() {
        guard let user = Auth.auth().currentUser else { return }
        let db = Firestore.firestore()
        db.collection("users").document(user.uid).delete { _ in
            user.delete { error in
                if let error = error {
                    print("Error deleting account:", error.localizedDescription)
                } else {
                    showLogin = true
                }
            }
        }
    }

    func rateApp() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    func shareApp() {
        let url = URL(string: "https://example.com")!
        let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
