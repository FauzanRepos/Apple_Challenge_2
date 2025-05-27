//
//  GameViewWrapper.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct GameViewWrapper: UIViewControllerRepresentable {
    
    // Multiplayer configuration
    let gameMode: GameMode
    let players: [NetworkPlayer]
    let isHost: Bool
    let gameCode: String?
    
    // Initialize for single player
    init() {
        self.gameMode = .singlePlayer
        self.players = []
        self.isHost = false
        self.gameCode = nil
    }
    
    // Initialize for multiplayer
    init(gameMode: GameMode, players: [NetworkPlayer], isHost: Bool, gameCode: String?) {
        self.gameMode = gameMode
        self.players = players
        self.isHost = isHost
        self.gameCode = gameCode
    }
    
    func makeUIViewController(context: Context) -> GameViewController {
        let gameController = GameViewController()
        
        // Configure the game controller for multiplayer if needed
        gameController.setupGame(
            mode: gameMode,
            players: players,
            isHost: isHost,
            gameCode: gameCode
        )
        
        return gameController
    }

    func updateUIViewController(_ uiViewController: GameViewController, context: Context) {
        // Update multiplayer state if needed
        uiViewController.updateMultiplayerState(
            players: players,
            isHost: isHost
        )
    }
}

// MARK: - Game Mode Enum
enum GameMode {
    case singlePlayer
    case multiplayerHost
    case multiplayerClient
}

// MARK: - SwiftUI Preview
#Preview {
    GameViewWrapper()
        .ignoresSafeArea()
}
