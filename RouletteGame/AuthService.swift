//
//  AuthService.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import FirebaseAuth
import FirebaseFirestore

class AuthService {
    static let shared = AuthService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    func signInAnonymously(completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signInAnonymously { [weak self] result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else { return }
            let userRef = self?.db.collection("users").document(user.uid)
            
            userRef?.getDocument { snapshot, error in
                if let snapshot = snapshot, snapshot.exists {
                    completion(.success(user))
                } else {
                    userRef?.setData([
                        "username": "Player\(Int.random(in: 1000...9999))",
                        "balance": 2000,
                        "winRate": 0.0,
                        "gamesPlayed": 0,
                        "gamesWon": 0
                    ]) { error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(user))
                        }
                    }
                }
            }
        }
    }
}

