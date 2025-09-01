//
//  GameView.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 31.08.2025.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum RouletteColor: String, CaseIterable {
    case red, black, green
}

struct GameView: View {
    @State private var username = ""
    @State private var balance = 0
    @State private var bet = 0
    @State private var chosenNumber: Int? = nil
    @State private var chosenColor: RouletteColor? = nil
    @State private var resultMessage = ""
    @State private var spinAnimation = false

    let numbers = Array(0...36)
    let redNumbers: Set<Int> = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]
    let blackNumbers: Set<Int> = [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                VStack {
                    Text(username)
                        .font(.title)
                        .bold()
                    Text("Balance: $\(balance)")
                        .font(.title2)
                        .foregroundColor(.orange)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.black.opacity(0.2)))

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                    ForEach(numbers, id: \.self) { num in
                        Button("\(num)") {
                            chosenNumber = num
                            chosenColor = nil
                        }
                        .frame(width: 40, height: 40)
                        .background(redNumbers.contains(num) ? Color.red : blackNumbers.contains(num) ? Color.black : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(chosenNumber == num ? Color.yellow : Color.clear, lineWidth: 3)
                        )
                    }
                }
                .padding()

                HStack(spacing: 20) {
                    ForEach(RouletteColor.allCases, id: \.self) { color in
                        Button(color.rawValue.capitalized) {
                            chosenColor = color
                            chosenNumber = nil
                        }
                        .frame(width: 80, height: 40)
                        .background(color == .red ? Color.red : color == .black ? Color.black : Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(chosenColor == color ? Color.yellow : Color.clear, lineWidth: 3)
                        )
                    }
                }

                HStack {
                    
                    let safeBalance = max(balance, 1) // если баланс 0, Stepper не крашит
                        Stepper(value: $bet, in: 1...safeBalance, step: max(1, safeBalance / 10)) {
                            Text("Bet: $\(bet)")
                        }
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)

                    Button(action: {
                            if bet <= 0 {
                                resultMessage = "Ставка должна быть больше 0!"
                                return
                            }
                            
                            withAnimation(.easeInOut(duration: 0.5)) {
                                spinAnimation.toggle()
                            }
                            spinRoulette()
                        }) {
                            Text("Spin")
                                .bold()
                                .frame(width: 100, height: 50)
                                .background(bet > 0 ? Color.blue : Color.gray)
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(radius: 5)
                                .rotationEffect(.degrees(spinAnimation ? 360 : 0))
                                .animation(.easeInOut(duration: 0.5), value: spinAnimation)
                        }
                        .disabled(bet <= 0)
                    }
                .padding()

                if !resultMessage.isEmpty {
                    Text(resultMessage)
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.3))
                        .cornerRadius(10)
                        .transition(.scale)
                        .animation(.spring(), value: resultMessage)
                }
            }
            .padding()
        }
        .onAppear {
            fetchUserData()
        }
    }

    // MARK: - Firestore
    func fetchUserData() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)

        userRef.getDocument { snapshot, error in
            if let data = snapshot?.data() {
                username = data["username"] as? String ?? "Unknown"
                balance = data["balance"] as? Int ?? 0
                checkAndRefillBalance()
            } else if let error = error {
                print("Error fetching user:", error.localizedDescription)
            }
        }
    }

    func spinRoulette() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        let userRef = db.collection("users").document(uid)
        
        let winningNumber = Int.random(in: 0...36)
        var change = 0
        var win = false
        
        if let number = chosenNumber {
            if number == winningNumber {
                change = bet * 35
                win = true
                resultMessage = "You won! Winning number: \(winningNumber)"
            } else {
                change = -bet
                resultMessage = "You lost! Winning number: \(winningNumber)"
            }
        } else if let color = chosenColor {
            let winningColor: RouletteColor
            if winningNumber == 0 {
                winningColor = .green
            } else if redNumbers.contains(winningNumber) {
                winningColor = .red
            } else {
                winningColor = .black
            }
            
            if color == winningColor {
                change = bet * 2
                win = true
                resultMessage = "You won on color! Winning number: \(winningNumber)"
            } else {
                change = -bet
                resultMessage = "You lost! Winning number: \(winningNumber)"
            }
        }

        balance += change
        bet = 0
        chosenNumber = nil
        chosenColor = nil
        
        userRef.updateData([
            "balance": balance,
            "winCount": FieldValue.increment(Int64(win ? 1 : 0)),
            "totalCount": FieldValue.increment(Int64(1))
        ]) { error in
            if let error = error {
                print("Error updating user data:", error.localizedDescription)
            } else {
                checkAndRefillBalance()
            }
        }
    }


    func checkAndRefillBalance() {
        if balance <= 0 {
            balance = 100
            resultMessage = "You got $100 to continue!"

            guard let uid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            let userRef = db.collection("users").document(uid)

            userRef.updateData([
                "balance": balance
            ]) { error in
                if let error = error {
                    print("Error refilling balance:", error.localizedDescription)
                }
            }
        }
    }
}

