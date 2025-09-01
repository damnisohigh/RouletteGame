//
//  RateView.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import FirebaseFirestore

struct RateView: View {
    @State private var leaders: [Leader] = []

    struct Leader: Identifiable {
        var id: String
        var username: String
        var balance: Int
        var winRate: Double
    }

    var body: some View {
        NavigationView {
            List(leaders) { leader in
                HStack {
                    Text(leader.username)
                        .bold()
                    Spacer()
                    Text("$\(leader.balance)")
                    Text(String(format: "WinRate: %.0f%%", leader.winRate * 100))
                        .foregroundColor(.gray)
                        .font(.subheadline)
                }
                .padding(.vertical, 5)
            }
            .navigationTitle("Leaderboard")
            .onAppear {
                fetchLeaders()
            }
        }
    }

    func fetchLeaders() {
        let db = Firestore.firestore()
        db.collection("users")
            .order(by: "balance", descending: true)
            .limit(to: 20)
            .getDocuments { snapshot, error in
                if let snapshot = snapshot {
                    self.leaders = snapshot.documents.compactMap { doc in
                        let data = doc.data()
                        let username = data["username"] as? String ?? "Unknown"
                        let balance = data["balance"] as? Int ?? 0
                        let winCount = data["winCount"] as? Int ?? 0
                        let totalCount = data["totalCount"] as? Int ?? 0
                        let winRate = totalCount > 0 ? Double(winCount) / Double(totalCount) : 0
                        return Leader(id: doc.documentID, username: username, balance: balance, winRate: winRate)
                    }
                } else if let error = error {
                    print("Error fetching leaders:", error.localizedDescription)
                }
            }
    }
}
