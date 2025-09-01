//
//  OneVsOne.swift
//  RouletteGame
//
//  Created by DAMNISOHIGH on 01.09.2025.
//


import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Online1v1View: View {
    @State private var balance = 0
    @State private var bet = 100
    @State private var chosenNumber: Int? = nil
    @State private var chosenColor: RouletteColor? = nil
    
    @State private var playerScore = 0
    @State private var opponentScore = 0
    @State private var playerBets: [Bet] = []
    @State private var opponentBets: [Bet] = []
    
    @State private var timeRemaining = 60
    @State private var roundEnded = false
    @State private var resultMessage = ""
    @State private var showOverlay = false
    
    @State private var matchId: String?
    @State private var opponentConnected = false
    
    private let numbers = Array(0...36)
    private let redNumbers: Set<Int> = [1,3,5,7,9,12,14,16,18,19,21,23,25,27,30,32,34,36]
    private let blackNumbers: Set<Int> = [2,4,6,8,10,11,13,15,17,20,22,24,26,28,29,31,33,35]
    
    private let db = Firestore.firestore()
    private let uid = Auth.auth().currentUser?.uid ?? UUID().uuidString
    
    struct Bet: Identifiable {
        let id = UUID()
        var number: Int?
        var color: RouletteColor?
        var amount: Int
        var gain: Int = 0
    }
    
    var body: some View {
        ZStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Balance: $\(balance)").font(.title2).foregroundColor(.yellow)
                    Text("Time: \(timeRemaining)s").font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 10) {
                        ForEach(numbers, id: \.self) { num in
                            Button("\(num)") {
                                chosenNumber = num
                                chosenColor = nil
                            }
                            .frame(width: 40, height: 40)
                            .background(redNumbers.contains(num) ? Color.red :
                                        blackNumbers.contains(num) ? Color.black : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                            .overlay(RoundedRectangle(cornerRadius: 20)
                                        .stroke(chosenNumber == num ? Color.yellow : Color.clear, lineWidth: 3))
                        }
                    }
                    
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
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                        .stroke(chosenColor == color ? Color.yellow : Color.clear, lineWidth: 3))
                        }
                    }
                    
                    let step = max(1, balance / 10)
                    Stepper("Bet: $\(bet)", value: $bet, in: 1...max(balance,1), step: step)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                    
                    Button("Place Bet") {
                        placePlayerBet()
                    }
                    .frame(width: 150, height: 50)
                    .background(bet > 0 && !roundEnded && opponentConnected ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(25)
                    .disabled(bet <= 0 || roundEnded || !opponentConnected)
                    
  
                    VStack(spacing: 5) {
                        ScrollView {
                            VStack(spacing: 5) {
                                ForEach(playerBets) { b in
                                    Text("Your bet: \(b.amount)$ на \(b.number != nil ? "\(b.number!)" : (b.color?.rawValue ?? "нічого")) | Виграш: \(b.gain)")
                                        .foregroundColor(.white)
                                }
                                ForEach(opponentBets) { b in
                                    Text("Opponent bet: \(b.amount)$ на \(b.number != nil ? "\(b.number!)" : (b.color?.rawValue ?? "нічого")) | Виграш: \(b.gain)")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .frame(height: 150)
                    }
                }
                .padding()
            }
            
            if showOverlay {
                VStack {
                    Spacer()
                    Text(resultMessage)
                        .font(.headline)
                        .foregroundColor(.yellow)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(12)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showOverlay = false }
                            }
                        }
                    Spacer()
                }
                .zIndex(1)
            }
        }
        .onAppear {
            fetchBalance()
            createOrJoinMatch()
        }
    }
    
    func fetchBalance() {
        let userRef = db.collection("users").document(uid)
        userRef.getDocument { snapshot, _ in
            if let data = snapshot?.data(), let bal = data["balance"] as? Int {
                balance = bal
            } else {
                balance = 2000
            }
        }
    }
    
    func updateBalance() {
        db.collection("users").document(uid).updateData(["balance": balance])
    }

    func createOrJoinMatch() {
        let matchesRef = db.collection("matches")
        
        matchesRef.whereField("player2", isEqualTo: NSNull()).limit(to: 1).getDocuments { snapshot, error in
            if let doc = snapshot?.documents.first {
                matchId = doc.documentID
                doc.reference.updateData(["player2": uid])
                opponentConnected = true
                startRoundTimer()
                listenForOpponentBets()
            } else {
                let data: [String: Any] = ["player1": uid, "player2": NSNull()]
                let docRef = matchesRef.addDocument(data: data)
                matchId = docRef.documentID
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    if !opponentConnected {
                        opponentConnected = true
                        scheduleBotBets()
                        startRoundTimer()
                    }
                }
            }
        }
    }

    func placePlayerBet() {
        guard chosenNumber != nil || chosenColor != nil else {
            resultMessage = "Виберіть число або колір!"
            withAnimation { showOverlay = true }
            return
        }
        let b = Bet(number: chosenNumber, color: chosenColor, amount: bet)
        playerBets.append(b)
        chosenNumber = nil
        chosenColor = nil
        bet = max(1, balance / 10)
        sendBetToFirestore(b)
        performSpin(playerBet: b)
    }
    
    func sendBetToFirestore(_ bet: Bet) {
        guard let matchId = matchId else { return }
        let matchRef = db.collection("matches").document(matchId)
        
        let betData: [String: Any] = [
            "number": bet.number as Any,
            "color": bet.color?.rawValue as Any,
            "amount": bet.amount
        ]
        
        matchRef.setData(["bets": [uid: betData]], merge: true)
    }
    

    func listenForOpponentBets() {
        guard let matchId = matchId else { return }
        
        db.collection("matches").document(matchId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(), error == nil else { return }
                
                if let betsData = data["bets"] as? [String: [String: Any]] {
                    for (playerId, betData) in betsData where playerId != uid {
                        let number = betData["number"] as? Int
                        let color = (betData["color"] as? String).flatMap { RouletteColor(rawValue: $0) }
                        let amount = betData["amount"] as? Int ?? 0
                        let b = Bet(number: number, color: color, amount: amount)
                        
                        if !opponentBets.contains(where: { $0.id == b.id }) {
                            opponentBets.append(b)
                            performSpin(botBet: b)
                        }
                    }
                }
            }
    }
    

    func scheduleBotBets() {
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { timer in
            guard !roundEnded else { timer.invalidate(); return }
            let number: Int? = Bool.random() ? Int.random(in: 0...36) : nil
            let color: RouletteColor? = number == nil ? RouletteColor.allCases.randomElement() : nil
            let amount = Int.random(in: 50...500)
            let b = Bet(number: number, color: color, amount: amount)
            opponentBets.append(b)
            performSpin(botBet: b)
        }
    }
    

    func performSpin(playerBet: Bet? = nil, botBet: Bet? = nil) {
        let winningNumber = Int.random(in: 0...36)
        let winningColor: RouletteColor = winningNumber == 0 ? .green :
            (redNumbers.contains(winningNumber) ? .red : .black)
        
        if var b = playerBet {
            var gain = 0
            if let num = b.number, num == winningNumber { gain = b.amount * 35 }
            else if let col = b.color, col == winningColor { gain = b.amount * 2 }
            b.gain = gain
            playerScore += gain
            balance = max(balance + gain, 0)
            updateBalance()
            if let index = playerBets.firstIndex(where: { $0.id == b.id }) { playerBets[index] = b }
            resultMessage = "Ви отримали \(gain)$!"
            withAnimation { showOverlay = true }
        }
        
        if var b = botBet {
            var gain = 0
            if let num = b.number, num == winningNumber { gain = b.amount * 35 }
            else if let col = b.color, col == winningColor { gain = b.amount * 2 }
            b.gain = gain
            opponentScore += gain
            if let index = opponentBets.firstIndex(where: { $0.id == b.id }) { opponentBets[index] = b }
        }
    }
    
    // MARK: - Timer
    func startRoundTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
                endRound()
            }
        }
    }
    
    func endRound() {
        roundEnded = true
        if playerScore >= opponentScore {
            resultMessage = "🎉 Ви виграли раунд! Куш: \(playerScore + opponentScore)"
            balance += opponentScore
        } else {
            resultMessage = "😢 Ви програли раунд!"
        }
        updateBalance()
        withAnimation { showOverlay = true }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            startNewRound()
        }
    }
    
    func startNewRound() {
        playerBets.removeAll()
        opponentBets.removeAll()
        playerScore = 0
        opponentScore = 0
        chosenNumber = nil
        chosenColor = nil
        bet = max(1, balance / 10)
        timeRemaining = 60
        roundEnded = false
        resultMessage = ""
        
        createOrJoinMatch()
    }
}






