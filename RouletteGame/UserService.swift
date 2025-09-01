//
//  UserService.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 01.09.2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class UserService {
    static let shared = UserService()
    private let db = Firestore.firestore()
    
    func fetchBalance(completion: @escaping (Int) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).getDocument { snap, _ in
            if let data = snap?.data(),
               let balance = data["balance"] as? Int {
                completion(balance)
            } else {
                completion(0)
            }
        }
    }
    
    func updateBalance(amount: Int) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        db.collection("users").document(uid).updateData([
            "balance": amount
        ])
    }
}
