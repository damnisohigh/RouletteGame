//
//  MatchService.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 01.09.2025.
//
import Foundation
import FirebaseFirestore
import FirebaseAuth

struct Match: Identifiable {
    var id: String
    var player1: String
    var player2: String?
    var isBot: Bool
    var timeLeft: Int
    var player1Score: Int
    var player2Score: Int
    var lastSpin: (number: Int, color: String)?
}

class MatchService: ObservableObject {
    static let shared = MatchService()
    private let db = Firestore.firestore()
    
    @Published var currentMatch: Match?
    
    private init() {}
    
    func findOrCreateMatch(completion: @escaping (Match) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let matchesRef = db.collection("matches")
        
        // шукаємо відкритий матч
        matchesRef
            .whereField("player2", isEqualTo: NSNull())
            .limit(to: 1)
            .getDocuments { snapshot, _ in
                if let doc = snapshot?.documents.first {
                    // приєднуємось
                    doc.reference.updateData(["player2": uid]) { _ in
                        listenMatch(doc.documentID)
                        fetchMatch(doc.documentID, completion: completion)
                    }
                } else {
                    // створюємо новий матч
                    let ref = matchesRef.document()
                    let data: [String: Any] = [
                        "player1": uid,
                        "player2": NSNull(),
                        "isBot": false,
                        "timeLeft": 60,
                        "player1Score": 0,
                        "player2Score": 0,
                        "createdAt": Timestamp(date: Date())
                    ]
                    ref.setData(data)
                    listenMatch(ref.documentID)
                    fetchMatch(ref.documentID, completion: completion)
                }
            }
        
        func fetchMatch(_ id: String, completion: @escaping (Match) -> Void) {
            matchesRef.document(id).getDocument { [self] snap, _ in
                if let data = snap?.data() {
                    let match = parseMatch(id: snap!.documentID, data: data)
                    completion(match)
                }
            }
        }
        
        func listenMatch(_ id: String) {
            matchesRef.document(id).addSnapshotListener { [self] snap, _ in
                if let data = snap?.data() {
                    self.currentMatch = parseMatch(id: id, data: data)
                }
            }
        }
    }
    
    private func parseMatch(id: String, data: [String: Any]) -> Match {
        let spinData = data["lastSpin"] as? [String: Any]
        return Match(
            id: id,
            player1: data["player1"] as? String ?? "",
            player2: data["player2"] as? String,
            isBot: data["isBot"] as? Bool ?? false,
            timeLeft: data["timeLeft"] as? Int ?? 60,
            player1Score: data["player1Score"] as? Int ?? 0,
            player2Score: data["player2Score"] as? Int ?? 0,
            lastSpin: spinData != nil ? (
                spinData!["number"] as? Int ?? 0,
                spinData!["color"] as? String ?? "green"
            ) : nil
        )
    }
    
    func updateSpin(matchId: String, number: Int, color: String) {
        db.collection("matches").document(matchId).updateData([
            "lastSpin": ["number": number, "color": color]
        ])
    }
    
    func updateScores(matchId: String, player1Score: Int, player2Score: Int) {
        db.collection("matches").document(matchId).updateData([
            "player1Score": player1Score,
            "player2Score": player2Score
        ])
    }
}

