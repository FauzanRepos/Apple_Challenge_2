//
//  GameManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreMotion
import Combine

class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // MARK: - Published Properties
    @Published var currentGameState: GameState = GameState()
    @Published var isGamePaused: Bool = false
    @Published var currentLevel: Int = 1
    @Published var gameMode: GameMode = .singlePlayer
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    
    // MARK: - Managers
    private let levelManager = LevelManager.shared
    private let audioManager = AudioManager.shared
    private let storageManager = StorageManager.shared
    
    private init() {
        setupBindings()
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Listen to multiplayer events
        MultipeerManager.shared.$sessionState
            .sink { [weak self] sessionState in
                self?.handleSessionStateChange(sessionState)
            }
            .store(in: &cancellables)
        
        // Listen to level completion
        NotificationCenter.default.publisher(for: .levelCompleted)
            .sink { [weak self] _ in
                self?.handleLevelCompleted()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Lifecycle
    func startNewGame(mode: GameMode) {
        print("🎮 Starting new game in mode: \(mode)")
        
        gameMode = mode
        currentLevel = 1
        currentGameState = GameState()
        
        // Load the first level
        levelManager.loadLevel(currentLevel)
        
        // Start audio
        audioManager.playBackgroundMusic()
        
        // Configure for multiplayer if needed
        if mode != .singlePlayer {
            setupMultiplayerGame()
        }
        
        isGamePaused = false
    }
    
    func pauseGame() {
        guard !isGamePaused else { return }
        
        print("⏸️ Game paused")
        isGamePaused = true
        gameTimer?.invalidate()
        audioManager.pauseBackgroundMusic()
        
        // Notify multiplayer peers if in multiplayer mode
        if gameMode != .singlePlayer {
            MultipeerManager.shared.sendGamePaused()
        }
    }
    
    func resumeGame() {
        guard isGamePaused else { return }
        
        print("▶️ Game resumed")
        isGamePaused = false
        audioManager.resumeBackgroundMusic()
        
        // Notify multiplayer peers if in multiplayer mode
        if gameMode != .singlePlayer {
            MultipeerManager.shared.sendGameResumed()
        }
    }
    
    func endGame(reason: GameEndReason) {
        print("🏁 Game ended: \(reason)")
        
        gameTimer?.invalidate()
        audioManager.stopBackgroundMusic()
        
        // Save high score if needed
        if currentGameState.score > storageManager.getHighScore() {
            storageManager.saveHighScore(currentGameState.score)
        }
        
        // Handle multiplayer cleanup
        if gameMode != .singlePlayer {
            MultipeerManager.shared.sendGameEnded(reason: reason)
        }
        
        // Reset state
        currentGameState = GameState()
        isGamePaused = false
    }
    
    // MARK: - Level Management
    func advanceToNextLevel() {
        currentLevel += 1
        print("📈 Advancing to level \(currentLevel)")
        
        // Check if level exists
        if levelManager.levelExists(currentLevel) {
            levelManager.loadLevel(currentLevel)
            currentGameState.resetForNewLevel()
        } else {
            // Game completed!
            endGame(reason: .gameCompleted)
        }
    }
    
    private func handleLevelCompleted() {
        print("🎉 Level \(currentLevel) completed!")
        audioManager.playLevelCompleteSound()
        
        // Update game state
        currentGameState.levelsCompleted += 1
        
        // Advance to next level after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.advanceToNextLevel()
        }
    }
    
    // MARK: - Player Management
    func addPlayer(_ player: NetworkPlayer) {
        currentGameState.players.append(player)
        print("👤 Player added: \(player.name)")
    }
    
    func removePlayer(_ player: NetworkPlayer) {
        currentGameState.players.removeAll { $0.id == player.id }
        print("👤 Player removed: \(player.name)")
    }
    
    func updatePlayerScore(_ playerId: String, score: Int) {
        if let index = currentGameState.players.firstIndex(where: { $0.id == playerId }) {
            currentGameState.players[index].score = score
        }
    }
    
    func updatePlayerLives(_ playerId: String, lives: Int) {
        if let index = currentGameState.players.firstIndex(where: { $0.id == playerId }) {
            currentGameState.players[index].lives = lives
        }
    }
    
    // MARK: - Multiplayer Support
    private func setupMultiplayerGame() {
        print("🌐 Setting up multiplayer game")
        
        // Configure multiplayer-specific settings
        currentGameState.isMultiplayer = true
        
        // Listen for multiplayer events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerJoined(_:)),
            name: .playerJoined,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePlayerLeft(_:)),
            name: .playerLeft,
            object: nil
        )
    }
    
    @objc private func handlePlayerJoined(_ notification: Notification) {
        guard let player = notification.object as? NetworkPlayer else { return }
        addPlayer(player)
    }
    
    @objc private func handlePlayerLeft(_ notification: Notification) {
        guard let player = notification.object as? NetworkPlayer else { return }
        removePlayer(player)
    }
    
    private func handleSessionStateChange(_ state: SessionState) {
        switch state {
        case .notConnected:
            if gameMode != .singlePlayer {
                // Lost connection during multiplayer game
                pauseGame()
            }
        case .connecting:
            break
        case .connected:
            if isGamePaused && gameMode != .singlePlayer {
                resumeGame()
            }
        }
    }
    
    // MARK: - Game Events
    func handleCheckpointReached(_ checkpointId: String, by playerId: String) {
        print("🏁 Checkpoint \(checkpointId) reached by player \(playerId)")
        
        // Update game state
        currentGameState.lastCheckpointId = checkpointId
        
        // Notify other players in multiplayer
        if gameMode != .singlePlayer {
            MultipeerManager.shared.sendCheckpointReached(checkpointId, playerId: playerId)
        }
        
        // Play checkpoint sound
        audioManager.playCheckpointSound()
    }
    
    func handlePlayerDeath(_ playerId: String) {
        print("💀 Player \(playerId) died")
        
        // Update player lives
        if let playerIndex = currentGameState.players.firstIndex(where: { $0.id == playerId }) {
            currentGameState.players[playerIndex].lives -= 1
            
            if currentGameState.players[playerIndex].lives <= 0 {
                // Player is out of lives
                handlePlayerEliminated(playerId)
            } else {
                // Respawn player at last checkpoint
                respawnPlayer(playerId)
            }
        }
        
        // Notify other players in multiplayer
        if gameMode != .singlePlayer {
            MultipeerManager.shared.sendPlayerDied(playerId)
        }
    }
    
    private func handlePlayerEliminated(_ playerId: String) {
        print("❌ Player \(playerId) eliminated")
        
        // In cooperative mode, if any player is eliminated, restart from checkpoint
        if gameMode == .multiplayerHost || gameMode == .multiplayerClient {
            respawnAllPlayersAtCheckpoint()
        }
    }
    
    private func respawnPlayer(_ playerId: String) {
        print("🔄 Respawning player \(playerId)")
        
        // Reset player to last checkpoint
        NotificationCenter.default.post(
            name: .respawnPlayer,
            object: playerId
        )
    }
    
    private func respawnAllPlayersAtCheckpoint() {
        print("🔄 Respawning all players at checkpoint")
        
        // Reset all players to last checkpoint
        for player in currentGameState.players {
            player.lives = 3 // Reset lives for cooperative play
        }
        
        NotificationCenter.default.post(name: .respawnAllPlayers, object: nil)
    }
}

// MARK: - Game End Reasons
enum GameEndReason {
    case playerQuit
    case gameCompleted
    case allPlayersEliminated
    case connectionLost
}

// MARK: - Notification Names
extension Notification.Name {
    static let levelCompleted = Notification.Name("levelCompleted")
    static let playerJoined = Notification.Name("playerJoined")
    static let playerLeft = Notification.Name("playerLeft")
    static let respawnPlayer = Notification.Name("respawnPlayer")
    static let respawnAllPlayers = Notification.Name("respawnAllPlayers")
}
