//
//  GameView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI
import MultipeerConnectivity

struct GameViewWrapper: UIViewControllerRepresentable {

    // Multiplayer configuration
    let gameMode: GameMode
    let players: [NetworkPlayer]
    let isHost: Bool
    let gameCode: String?
    let playerType: PlayerType

    // Initialize for single player
    init() {
        self.gameMode = .singlePlayer
        self.players = []
        self.isHost = false
        self.gameCode = nil
        self.playerType = .mapMover
    }

    // Initialize for multiplayer
    init(gameMode: GameMode, players: [NetworkPlayer], isHost: Bool, gameCode: String?, playerType: PlayerType = .mapMover) {
        self.gameMode = gameMode
        self.players = players
        self.isHost = isHost
        self.gameCode = gameCode
        self.playerType = playerType
    }

    func makeUIViewController(context: Context) -> GameViewController {
        let gameController = GameViewController()

        // Configure the game controller for multiplayer if needed
        gameController.setupGame(
            mode: gameMode,
            players: players,
            isHost: isHost,
            gameCode: gameCode,
            playerType: playerType
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

    var displayName: String {
        switch self {
        case .singlePlayer: return "Single Player"
        case .multiplayerHost: return "Multiplayer Host"
        case .multiplayerClient: return "Multiplayer Client"
        }
    }
}

// MARK: - Convenience Initializers
extension GameViewWrapper {

    // Create single player game
    static func singlePlayer() -> GameViewWrapper {
        return GameViewWrapper()
    }

    // Create multiplayer host game
    static func multiplayerHost(gameCode: String, players: [NetworkPlayer]) -> GameViewWrapper {
        return GameViewWrapper(
            gameMode: .multiplayerHost,
            players: players,
            isHost: true,
            gameCode: gameCode,
            playerType: .mapMover
        )
    }

    // Create multiplayer client game
    static func multiplayerClient(gameCode: String, players: [NetworkPlayer], playerType: PlayerType) -> GameViewWrapper {
        return GameViewWrapper(
            gameMode: .multiplayerClient,
            players: players,
            isHost: false,
            gameCode: gameCode,
            playerType: playerType
        )
    }

    // Create from MultipeerManager state
    static func fromMultipeerState() -> GameViewWrapper {
        let multipeerManager = MultipeerManager.shared
        let gameMode: GameMode = multipeerManager.isHost ? .multiplayerHost : .multiplayerClient

        return GameViewWrapper(
            gameMode: gameMode,
            players: multipeerManager.connectedPlayers,
            isHost: multipeerManager.isHost,
            gameCode: multipeerManager.gameCode.isEmpty ? nil : multipeerManager.gameCode,
            playerType: multipeerManager.getLocalPlayer().playerType
        )
    }
}

// MARK: - SwiftUI Preview
#Preview {
    GameViewWrapper()
        .ignoresSafeArea()
}
