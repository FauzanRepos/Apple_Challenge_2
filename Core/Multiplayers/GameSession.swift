//
//  GameSession.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

class GameSession: ObservableObject {
    
    // MARK: - Properties
    let gameCode: String
    let hostPlayer: NetworkPlayer
    let maxPlayers: Int
    let createdAt: Date
    
    @Published var players: [NetworkPlayer] = []
    @Published var sessionState: SessionState = .notConnected
    @Published var currentLevel: Int = 1
    @Published var gameStarted: Bool = false
    @Published var gamePaused: Bool = false
    
    // MARK: - Game State
    private var playerPositions: [String: CGPoint] = [:]
    private var playerVelocities: [String: CGVector] = [:]
    private var lastUpdateTimestamps: [String: TimeInterval] = [:]
    private var completedCheckpoints: Set<String> = []
    private var activePowerUps: [ActivePowerUp] = []
    
    // MARK: - Synchronization
    private let syncQueue = DispatchQueue(label: "gameSession.sync", qos: .userInitiated)
    private var lastSyncTime: TimeInterval = 0
    private let syncInterval: TimeInterval = 1.0 / 30.0 // 30 FPS sync rate
    
    // MARK: - Initialization
    init(gameCode: String, hostPlayer: NetworkPlayer, maxPlayers: Int) {
        self.gameCode = gameCode
        self.hostPlayer = hostPlayer
        self.maxPlayers = maxPlayers
        self.createdAt = Date()
        
        // Add host as first player
        self.players = [hostPlayer]
        
        print("🎮 Game session created: \(gameCode)")
    }
    
    // MARK: - Player Management
    func addPlayer(_ player: NetworkPlayer) -> Bool {
        guard players.count < maxPlayers else {
            print("❌ Cannot add player: session is full")
            return false
        }
        
        guard !players.contains(where: { $0.id == player.id }) else {
            print("❌ Player already in session: \(player.id)")
            return false
        }
        
        players.append(player)
        playerPositions[player.id] = CGPoint.zero
        playerVelocities[player.id] = CGVector.zero
        lastUpdateTimestamps[player.id] = Date().timeIntervalSince1970
        
        print("✅ Player added to session: \(player.name) (\(players.count)/\(maxPlayers))")
        return true
    }
    
    func removePlayer(_ playerId: String) {
        players.removeAll { $0.id == playerId }
        playerPositions.removeValue(forKey: playerId)
        playerVelocities.removeValue(forKey: playerId)
        lastUpdateTimestamps.removeValue(forKey: playerId)
        
        print("❌ Player removed from session: \(playerId)")
        
        // If host left, handle session cleanup
        if playerId == hostPlayer.id {
            handleHostLeft()
        }
    }
    
    func updatePlayerReadyState(_ playerId: String, isReady: Bool) {
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].isReady = isReady
            print("✅ Player \(playerId) ready state: \(isReady)")
        }
    }
    
    func areAllPlayersReady() -> Bool {
        return players.count >= 2 && players.allSatisfy { $0.isReady }
    }
    
    // MARK: - Game State Management
    func startGame() -> Bool {
        guard areAllPlayersReady() else {
            print("❌ Cannot start game: not all players are ready")
            return false
        }
        
        gameStarted = true
        sessionState = .gameInProgress
        assignPlayerTypes()
        
        print("🚀 Game session started with \(players.count) players")
        return true
    }
    
    func pauseGame() {
        gamePaused = true
        print("⏸️ Game session paused")
    }
    
    func resumeGame() {
        gamePaused = false
        print("▶️ Game session resumed")
    }
    
    func endGame(reason: GameEndReason) {
        gameStarted = false
        gamePaused = false
        sessionState = .gameEnded
        
        print("🏁 Game session ended: \(reason)")
        
        // Clean up game state
        cleanupGameState()
    }
    
    private func assignPlayerTypes() {
        let totalPlayers = players.count
        let mapMoverCount = max(1, totalPlayers / 3)
        
        // Shuffle players for random assignment
        var shuffledPlayers = players.shuffled()
        
        for (index, player) in shuffledPlayers.enumerated() {
            let playerType: PlayerType = index < mapMoverCount ? .mapMover : .regular
            
            if let originalIndex = players.firstIndex(where: { $0.id == player.id }) {
                players[originalIndex].playerType = playerType
            }
        }
        
        print("🎯 Player types assigned: \(mapMoverCount) map movers, \(totalPlayers - mapMoverCount) regular")
    }
    
    // MARK: - Position Synchronization
    func updatePlayerPosition(_ playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if this update is newer than what we have
            if let lastTimestamp = self.lastUpdateTimestamps[playerId],
               timestamp <= lastTimestamp {
                return // Ignore older updates
            }
            
            self.playerPositions[playerId] = position
            self.playerVelocities[playerId] = velocity
            self.lastUpdateTimestamps[playerId] = timestamp
        }
    }
    
    func getPlayerPosition(_ playerId: String) -> CGPoint? {
        return syncQueue.sync {
            return playerPositions[playerId]
        }
    }
    
    func getAllPlayerPositions() -> [String: CGPoint] {
        return syncQueue.sync {
            return playerPositions
        }
    }
    
    func predictPlayerPosition(_ playerId: String, at futureTime: TimeInterval) -> CGPoint? {
        return syncQueue.sync {
            guard let currentPosition = playerPositions[playerId],
                  let velocity = playerVelocities[playerId],
                  let lastTimestamp = lastUpdateTimestamps[playerId] else {
                return nil
            }
            
            let deltaTime = futureTime - lastTimestamp
            let predictedX = currentPosition.x + velocity.dx * deltaTime
            let predictedY = currentPosition.y + velocity.dy * deltaTime
            
            return CGPoint(x: predictedX, y: predictedY)
        }
    }
    
    // MARK: - Game Events
    func handleCheckpointReached(_ checkpointId: String, by playerId: String) {
        completedCheckpoints.insert(checkpointId)
        
        // Update player score
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].score += Constants.checkpointScore
        }
        
        print("🏁 Checkpoint \(checkpointId) reached by \(playerId)")
    }
    
    func handlePlayerDeath(_ playerId: String) {
        // Decrease player lives
        if let index = players.firstIndex(where: { $0.id == playerId }) {
            players[index].lives -= 1
            
            if players[index].lives <= 0 {
                handlePlayerEliminated(playerId)
            }
        }
        
        print("💀 Player \(playerId) died")
    }
    
    private func handlePlayerEliminated(_ playerId: String) {
        // In cooperative mode, respawn all players when one is eliminated
        for index in players.indices {
            players[index].lives = 3 // Reset lives for cooperative play
        }
        
        print("🔄 All players respawned due to elimination")
    }
    
    func activatePowerUp(_ powerUp: PowerUp, for playerId: String) {
        let activePowerUp = ActivePowerUp(
            type: powerUp.type,
            playerId: playerId,
            activatedAt: Date(),
            duration: powerUp.duration
        )
        
        activePowerUps.append(activePowerUp)
        
        print("⚡ Power-up \(powerUp.type) activated for \(playerId)")
    }
    
    func updateActivePowerUps() {
        let now = Date()
        activePowerUps.removeAll { powerUp in
            let elapsed = now.timeIntervalSince(powerUp.activatedAt)
            return elapsed >= powerUp.duration
        }
    }
    
    func getActivePowerUps(for playerId: String) -> [ActivePowerUp] {
        return activePowerUps.filter { $0.playerId == playerId }
    }
    
    // MARK: - Level Management
    func advanceToNextLevel() {
        currentLevel += 1
        completedCheckpoints.removeAll()
        activePowerUps.removeAll()
        
        // Reset player positions
        playerPositions.removeAll()
        playerVelocities.removeAll()
        
        print("📈 Advanced to level \(currentLevel)")
    }
    
    // MARK: - Session Info
    func getSessionInfo() -> SessionInfo {
        return SessionInfo(
            gameCode: gameCode,
            hostName: hostPlayer.name,
            playerCount: players.count,
            maxPlayers: maxPlayers,
            currentLevel: currentLevel,
            isGameStarted: gameStarted,
            createdAt: createdAt
        )
    }
    
    func isExpired() -> Bool {
        let expirationTime: TimeInterval = 30 * 60 // 30 minutes
        return Date().timeIntervalSince(createdAt) > expirationTime
    }
    
    func getPlayersInfo() -> [PlayerInfo] {
        return players.map { player in
            PlayerInfo(
                id: player.id,
                name: player.name,
                isHost: player.isHost,
                isReady: player.isReady,
                playerType: player.playerType,
                lives: player.lives,
                score: player.score,
                position: playerPositions[player.id] ?? CGPoint.zero
            )
        }
    }
    
    // MARK: - Private Methods
    private func handleHostLeft() {
        // If host leaves, end the game session
        sessionState = .hostDisconnected
        endGame(reason: .connectionLost)
    }
    
    private func cleanupGameState() {
        playerPositions.removeAll()
        playerVelocities.removeAll()
        lastUpdateTimestamps.removeAll()
        completedCheckpoints.removeAll()
        activePowerUps.removeAll()
    }
    
    // MARK: - Debug Info
    func getDebugInfo() -> String {
        return """
        Session: \(gameCode)
        Players: \(players.count)/\(maxPlayers)
        State: \(sessionState)
        Level: \(currentLevel)
        Started: \(gameStarted)
        Paused: \(gamePaused)
        Checkpoints: \(completedCheckpoints.count)
        Active Power-ups: \(activePowerUps.count)
        """
    }
}

// MARK: - Supporting Data Types
struct ActivePowerUp {
    let type: PowerUpType
    let playerId: String
    let activatedAt: Date
    let duration: TimeInterval
    
    var isExpired: Bool {
        Date().timeIntervalSince(activatedAt) >= duration
    }
}

struct SessionInfo {
    let gameCode: String
    let hostName: String
    let playerCount: Int
    let maxPlayers: Int
    let currentLevel: Int
    let isGameStarted: Bool
    let createdAt: Date
}

struct PlayerInfo {
    let id: String
    let name: String
    let isHost: Bool
    let isReady: Bool
    let playerType: PlayerType
    let lives: Int
    let score: Int
    let position: CGPoint
}

// MARK: - Session State Enum
enum SessionState {
    case notConnected
    case searching
    case connecting
    case connected
    case hosting
    case gameInProgress
    case gameEnded
    case hostDisconnected
    
    var description: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .searching: return "Searching for Game"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .hosting: return "Hosting Game"
        case .gameInProgress: return "Game in Progress"
        case .gameEnded: return "Game Ended"
        case .hostDisconnected: return "Host Disconnected"
        }
    }
}
