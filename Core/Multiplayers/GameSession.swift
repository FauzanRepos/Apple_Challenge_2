//
//  GameSession.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity

// MARK: - Game Session
class GameSession: ObservableObject {
    
    // MARK: - Properties
    let gameCode: String
    let hostPlayer: NetworkPlayer
    let maxPlayers: Int
    let createdAt: Date
    
    @Published var players: [NetworkPlayer] = []
    @Published var sessionState: SessionStateType = .notConnected
    @Published var currentLevel: Int = 1
    @Published var gameStarted: Bool = false
    @Published var gamePaused: Bool = false
    
    // MARK: - Game State
    private var playerPositions: [String: CGPoint] = [:]
    private var playerVelocities: [String: CGVector] = [:]
    private var lastUpdateTimestamps: [String: TimeInterval] = [:]
    private var completedCheckpoints: Set<String> = []
    private var activePowerUpInstances: [ActivePowerUpInstance] = []
    
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
        guard players.count < maxPlayers else { return false }
        guard !players.contains(where: { $0.id == player.id }) else { return false }
        
        players.append(player)
        
        // Assign player type based on order
        if players.count == 1 {
            player.playerType = .mapMover
        } else {
            player.playerType = .regular
        }
        
        print("👤 Player added: \(player.displayName) (\(players.count)/\(maxPlayers))")
        return true
    }
    
    func removePlayer(with id: String) {
        players.removeAll { $0.id == id }
        playerPositions.removeValue(forKey: id)
        playerVelocities.removeValue(forKey: id)
        lastUpdateTimestamps.removeValue(forKey: id)
        
        print("👤 Player removed: \(id) (\(players.count)/\(maxPlayers))")
    }
    
    func getPlayer(with id: String) -> NetworkPlayer? {
        return players.first { $0.id == id }
    }
    
    func areAllPlayersReady() -> Bool {
        return !players.isEmpty && players.allSatisfy { $0.isReady }
    }
    
    // MARK: - Game State Management
    func startGame() {
        guard areAllPlayersReady() && players.count >= 2 else { return }
        
        gameStarted = true
        sessionState = .gameInProgress
        currentLevel = 1
        
        // Reset game state
        completedCheckpoints.removeAll()
        activePowerUpInstances.removeAll()
        
        print("🚀 Game started with \(players.count) players")
    }
    
    func pauseGame() {
        gamePaused = true
    }
    
    func resumeGame() {
        gamePaused = false
    }
    
    func endGame(reason: GameEndReasonType) {
        gameStarted = false
        gamePaused = false
        sessionState = .gameEnded
        
        print("🏁 Game ended: \(reason)")
    }
    
    func advanceToNextLevel() {
        currentLevel += 1
        completedCheckpoints.removeAll()
        
        // Reset player positions
        playerPositions.removeAll()
        playerVelocities.removeAll()
        
        print("📈 Advanced to level \(currentLevel)")
    }
    
    // MARK: - Position Synchronization
    func updatePlayerPosition(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Check if this update is newer than the last one
            if let lastTimestamp = self.lastUpdateTimestamps[playerId],
               timestamp <= lastTimestamp {
                return // Ignore older updates
            }
            
            self.playerPositions[playerId] = position
            self.playerVelocities[playerId] = velocity
            self.lastUpdateTimestamps[playerId] = timestamp
            
            // Update the player object
            if let player = self.getPlayer(with: playerId) {
                DispatchQueue.main.async {
                    player.updatePosition(position, velocity: velocity, timestamp: Date(timeIntervalSince1970: timestamp))
                }
            }
        }
    }
    
    func getPlayerPosition(playerId: String) -> CGPoint? {
        return playerPositions[playerId]
    }
    
    func getPlayerVelocity(playerId: String) -> CGVector? {
        return playerVelocities[playerId]
    }
    
    // MARK: - Checkpoint Management
    func completeCheckpoint(_ checkpointId: String, by playerId: String) {
        guard !completedCheckpoints.contains(checkpointId) else { return }
        
        completedCheckpoints.insert(checkpointId)
        
        if let player = getPlayer(with: playerId) {
            player.addScore(Constants.checkpointScore)
        }
        
        print("🏁 Checkpoint \(checkpointId) completed by \(playerId)")
    }
    
    func isCheckpointCompleted(_ checkpointId: String) -> Bool {
        return completedCheckpoints.contains(checkpointId)
    }
    
    // MARK: - Power-Up Management
    func activatePowerUp(_ type: PowerUpTypeEnum, for playerId: String, duration: TimeInterval = 5.0) {
        let powerUp = ActivePowerUpInstance(
            id: UUID().uuidString,
            type: type,
            playerId: playerId,
            activatedAt: Date(),
            duration: duration
        )
        
        activePowerUpInstances.append(powerUp)
        
        print("⚡ Power-up \(type) activated for \(playerId)")
    }
    
    func updateActivePowerUps() {
        let now = Date()
        activePowerUpInstances.removeAll { powerUp in
            now.timeIntervalSince(powerUp.activatedAt) >= powerUp.duration
        }
    }
    
    func getActivePowerUps(for playerId: String) -> [ActivePowerUpInstance] {
        return activePowerUpInstances.filter { $0.playerId == playerId }
    }
    
    // MARK: - Session State
    var canJoinGame: Bool {
        return players.count < maxPlayers && !gameStarted
    }
    
    var connectionSummary: String {
        let readyCount = players.filter { $0.isReady }.count
        return "\(players.count)/\(maxPlayers) players • \(readyCount) ready"
    }
    
    // MARK: - Cleanup
    func cleanup() {
        players.removeAll()
        playerPositions.removeAll()
        playerVelocities.removeAll()
        lastUpdateTimestamps.removeAll()
        completedCheckpoints.removeAll()
        activePowerUpInstances.removeAll()
        
        print("🧹 Game session cleaned up")
    }
}

// MARK: - Supporting Types
enum SessionStateType: String, CaseIterable {
    case notConnected = "notConnected"
    case connecting = "connecting"
    case connected = "connected"
    case hosting = "hosting"
    case gameInProgress = "gameInProgress"
    case gameEnded = "gameEnded"
    case error = "error"
}

enum GameEndReasonType: String, CaseIterable {
    case gameCompleted = "gameCompleted"
    case allPlayersEliminated = "allPlayersEliminated"
    case hostDisconnected = "hostDisconnected"
    case networkError = "networkError"
    case gameAborted = "gameAborted"
}

enum PowerUpTypeEnum: String, CaseIterable {
    case oil = "oil"
    case grass = "grass"
    case shield = "shield"
    case magnet = "magnet"
    case invulnerability = "invulnerability"
    
    var displayName: String {
        switch self {
        case .oil: return "Speed Boost"
        case .grass: return "Slow Motion"
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        case .invulnerability: return "Invulnerability"
        }
    }
}

struct ActivePowerUpInstance: Identifiable {
    let id: String
    let type: PowerUpTypeEnum
    let playerId: String
    let activatedAt: Date
    let duration: TimeInterval
    
    var remainingTime: TimeInterval {
        let elapsed = Date().timeIntervalSince(activatedAt)
        return max(0, duration - elapsed)
    }
    
    var isExpired: Bool {
        return remainingTime <= 0
    }
}
