//
//  NetworkMessage.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Network Message Types
enum NetworkMessage: Codable {
    // Connection Messages
    case playerJoined(player: NetworkPlayer)
    case playerLeft(playerId: String)
    case playerReady(playerId: String, isReady: Bool)
    
    // Game State Messages
    case gameStart(players: [NetworkPlayer])
    case gamePaused
    case gameResumed
    case gameEnded(reason: GameEndReason)
    
    // Gameplay Messages
    case playerMovement(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval)
    case mapScrolled(offset: CGPoint, triggeredBy: String)
    case checkpointReached(checkpointId: String, playerId: String)
    case powerUpCollected(powerUpId: String, type: PowerUpType, playerId: String)
    case powerUpActivated(type: PowerUpType, playerId: String, duration: TimeInterval)
    case playerDied(playerId: String)
    case playerRespawned(playerId: String, position: CGPoint)
    case levelCompleted
    case levelAdvanced(newLevel: Int)
    
    // Synchronization Messages
    case syncRequest(playerId: String)
    case syncResponse(gameState: GameSyncData)
    case heartbeat(playerId: String, timestamp: TimeInterval)
    
    // Chat Messages (Future feature)
    case chatMessage(playerId: String, message: String)
    
    // Error Messages
    case error(code: NetworkErrorCode, message: String)
}

// MARK: - Network Error Codes
enum NetworkErrorCode: String, Codable {
    case connectionLost = "CONNECTION_LOST"
    case gameSessionFull = "GAME_SESSION_FULL"
    case invalidGameCode = "INVALID_GAME_CODE"
    case playerNotFound = "PLAYER_NOT_FOUND"
    case gameNotStarted = "GAME_NOT_STARTED"
    case gameAlreadyStarted = "GAME_ALREADY_STARTED"
    case hostOnly = "HOST_ONLY_ACTION"
    case syncError = "SYNC_ERROR"
    case unknown = "UNKNOWN_ERROR"
}

// MARK: - Game Sync Data
struct GameSyncData: Codable {
    let timestamp: TimeInterval
    let currentLevel: Int
    let playerStates: [PlayerSyncState]
    let completedCheckpoints: [String]
    let activePowerUps: [PowerUpSyncData]
    let mapOffset: CGPoint
    let gameSettings: GameSyncSettings
    
    init(
        currentLevel: Int,
        playerStates: [PlayerSyncState],
        completedCheckpoints: [String] = [],
        activePowerUps: [PowerUpSyncData] = [],
        mapOffset: CGPoint = .zero,
        gameSettings: GameSyncSettings = GameSyncSettings()
    ) {
        self.timestamp = Date().timeIntervalSince1970
        self.currentLevel = currentLevel
        self.playerStates = playerStates
        self.completedCheckpoints = completedCheckpoints
        self.activePowerUps = activePowerUps
        self.mapOffset = mapOffset
        self.gameSettings = gameSettings
    }
}

// MARK: - Player Sync State
struct PlayerSyncState: Codable {
    let playerId: String
    let position: CGPoint
    let velocity: CGVector
    let lives: Int
    let score: Int
    let isReady: Bool
    let playerType: PlayerType
    let lastCheckpointId: String?
    let timestamp: TimeInterval
    
    init(player: NetworkPlayer, position: CGPoint, velocity: CGVector, lastCheckpointId: String? = nil) {
        self.playerId = player.id
        self.position = position
        self.velocity = velocity
        self.lives = player.lives
        self.score = player.score
        self.isReady = player.isReady
        self.playerType = player.playerType
        self.lastCheckpointId = lastCheckpointId
        self.timestamp = Date().timeIntervalSince1970
    }
}

// MARK: - Power-Up Sync Data
struct PowerUpSyncData: Codable {
    let id: String
    let type: PowerUpType
    let playerId: String
    let activatedAt: TimeInterval
    let duration: TimeInterval
    let remainingTime: TimeInterval
    
    init(id: String, type: PowerUpType, playerId: String, activatedAt: Date, duration: TimeInterval) {
        self.id = id
        self.type = type
        self.playerId = playerId
        self.activatedAt = activatedAt.timeIntervalSince1970
        self.duration = duration
        self.remainingTime = max(0, duration - Date().timeIntervalSince(activatedAt))
    }
}

// MARK: - Game Sync Settings
struct GameSyncSettings: Codable {
    let cellSize: Float
    let mapMoverCount: Int
    let maxLives: Int
    let checkpointScore: Int
    let respawnDelay: TimeInterval
    
    init(
        cellSize: Float = 64,
        mapMoverCount: Int = 1,
        maxLives: Int = 3,
        checkpointScore: Int = 10,
        respawnDelay: TimeInterval = 2.0
    ) {
        self.cellSize = cellSize
        self.mapMoverCount = mapMoverCount
        self.maxLives = maxLives
        self.checkpointScore = checkpointScore
        self.respawnDelay = respawnDelay
    }
}

// MARK: - Message Priority
extension NetworkMessage {
    var priority: NetworkMessagePriority {
        switch self {
        case .playerMovement, .heartbeat:
            return .low
            
        case .mapScrolled, .powerUpActivated, .syncResponse:
            return .normal
            
        case .playerDied, .checkpointReached, .gameStart, .gameEnded:
            return .high
            
        case .error, .gameJoined, .playerLeft:
            return .critical
        }
    }
    
    var requiresReliableDelivery: Bool {
        switch self {
        case .playerMovement, .heartbeat, .mapScrolled:
            return false // These can be lost without major issues
            
        default:
            return true // Most messages should be delivered reliably
        }
    }
}

enum NetworkMessagePriority: Int, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: NetworkMessagePriority, rhs: NetworkMessagePriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Message Validation
extension NetworkMessage {
    func validate() -> NetworkValidationResult {
        switch self {
        case .playerJoined(let player):
            return validatePlayer(player)
            
        case .playerMovement(let playerId, let position, let velocity, let timestamp):
            return validatePlayerMovement(playerId: playerId, position: position, velocity: velocity, timestamp: timestamp)
            
        case .checkpointReached(let checkpointId, let playerId):
            return validateCheckpoint(checkpointId: checkpointId, playerId: playerId)
            
        case .powerUpCollected(let powerUpId, let type, let playerId):
            return validatePowerUp(powerUpId: powerUpId, type: type, playerId: playerId)
            
        case .gameStart(let players):
            return validateGameStart(players: players)
            
        default:
            return .valid
        }
    }
    
    private func validatePlayer(_ player: NetworkPlayer) -> NetworkValidationResult {
        guard !player.id.isEmpty && !player.name.isEmpty else {
            return .invalid(reason: "Player ID and name cannot be empty")
        }
        
        guard player.name.count <= 20 else {
            return .invalid(reason: "Player name too long")
        }
        
        return .valid
    }
    
    private func validatePlayerMovement(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval) -> NetworkValidationResult {
        guard !playerId.isEmpty else {
            return .invalid(reason: "Player ID cannot be empty")
        }
        
        // Check for reasonable position values
        let maxCoordinate: CGFloat = 10000
        guard abs(position.x) <= maxCoordinate && abs(position.y) <= maxCoordinate else {
            return .invalid(reason: "Position coordinates out of bounds")
        }
        
        // Check for reasonable velocity values
        let maxVelocity: CGFloat = 1000
        guard abs(velocity.dx) <= maxVelocity && abs(velocity.dy) <= maxVelocity else {
            return .invalid(reason: "Velocity values out of bounds")
        }
        
        // Check timestamp is recent (within last 5 seconds)
        let now = Date().timeIntervalSince1970
        guard abs(now - timestamp) <= 5.0 else {
            return .invalid(reason: "Timestamp too old or in future")
        }
        
        return .valid
    }
    
    private func validateCheckpoint(checkpointId: String, playerId: String) -> NetworkValidationResult {
        guard !checkpointId.isEmpty && !playerId.isEmpty else {
            return .invalid(reason: "Checkpoint ID and Player ID cannot be empty")
        }
        
        return .valid
    }
    
    private func validatePowerUp(powerUpId: String, type: PowerUpType, playerId: String) -> NetworkValidationResult {
        guard !powerUpId.isEmpty && !playerId.isEmpty else {
            return .invalid(reason: "Power-up ID and Player ID cannot be empty")
        }
        
        return .valid
    }
    
    private func validateGameStart(players: [NetworkPlayer]) -> NetworkValidationResult {
        guard players.count >= 2 else {
            return .invalid(reason: "Need at least 2 players to start game")
        }
        
        guard players.count <= Constants.maxPlayersPerRoom else {
            return .invalid(reason: "Too many players")
        }
        
        // Check all players are ready
        guard players.allSatisfy({ $0.isReady }) else {
            return .invalid(reason: "Not all players are ready")
        }
        
        return .valid
    }
}

enum NetworkValidationResult {
    case valid
    case invalid(reason: String)
    
    var isValid: Bool {
        switch self {
        case .valid:
            return true
        case .invalid:
            return false
        }
    }
    
    var errorMessage: String? {
        switch self {
        case .valid:
            return nil
        case .invalid(let reason):
            return reason
        }
    }
}

// MARK: - Message Serialization Extensions
extension NetworkMessage {
    func toData() throws -> Data {
        return try JSONEncoder().encode(self)
    }
    
    static func fromData(_ data: Data) throws -> NetworkMessage {
        return try JSONDecoder().decode(NetworkMessage.self, from: data)
    }
    
    func toJSON() throws -> String {
        let data = try toData()
        guard let jsonString = String(data: data, encoding: .utf8) else {
            throw NetworkError.serializationFailed
        }
        return jsonString
    }
    
    static func fromJSON(_ jsonString: String) throws -> NetworkMessage {
        guard let data = jsonString.data(using: .utf8) else {
            throw NetworkError.deserializationFailed
        }
        return try fromData(data)
    }
}

// MARK: - Network Error
enum NetworkError: Error {
    case serializationFailed
    case deserializationFailed
    case invalidMessage
    case validationFailed(String)
    
    var localizedDescription: String {
        switch self {
        case .serializationFailed:
            return "Failed to serialize network message"
        case .deserializationFailed:
            return "Failed to deserialize network message"
        case .invalidMessage:
            return "Invalid network message format"
        case .validationFailed(let reason):
            return "Message validation failed: \(reason)"
        }
    }
}

// MARK: - Message Factory
struct NetworkMessageFactory {
    static func createPlayerJoinedMessage(player: NetworkPlayer) -> NetworkMessage {
        return .playerJoined(player: player)
    }
    
    static func createPlayerMovementMessage(playerId: String, position: CGPoint, velocity: CGVector) -> NetworkMessage {
        return .playerMovement(
            playerId: playerId,
            position: position,
            velocity: velocity,
            timestamp: Date().timeIntervalSince1970
        )
    }
    
    static func createCheckpointReachedMessage(checkpointId: String, playerId: String) -> NetworkMessage {
        return .checkpointReached(checkpointId: checkpointId, playerId: playerId)
    }
    
    static func createPowerUpCollectedMessage(powerUpId: String, type: PowerUpType, playerId: String) -> NetworkMessage {
        return .powerUpCollected(powerUpId: powerUpId, type: type, playerId: playerId)
    }
    
    static func createGameStartMessage(players: [NetworkPlayer]) -> NetworkMessage {
        return .gameStart(players: players)
    }
    
    static func createSyncRequestMessage(playerId: String) -> NetworkMessage {
        return .syncRequest(playerId: playerId)
    }
    
    static func createSyncResponseMessage(gameState: GameSyncData) -> NetworkMessage {
        return .syncResponse(gameState: gameState)
    }
    
    static func createErrorMessage(code: NetworkErrorCode, message: String) -> NetworkMessage {
        return .error(code: code, message: message)
    }
    
    static func createHeartbeatMessage(playerId: String) -> NetworkMessage {
        return .heartbeat(playerId: playerId, timestamp: Date().timeIntervalSince1970)
    }
}

// MARK: - Debug Extensions
extension NetworkMessage {
    var debugDescription: String {
        switch self {
        case .playerJoined(let player):
            return "PlayerJoined(\(player.name))"
        case .playerLeft(let playerId):
            return "PlayerLeft(\(playerId))"
        case .playerMovement(let playerId, let position, _, let timestamp):
            return "PlayerMovement(\(playerId), \(position), \(timestamp))"
        case .checkpointReached(let checkpointId, let playerId):
            return "CheckpointReached(\(checkpointId), \(playerId))"
        case .gameStart(let players):
            return "GameStart(\(players.count) players)"
        case .gamePaused:
            return "GamePaused"
        case .gameResumed:
            return "GameResumed"
        case .gameEnded(let reason):
            return "GameEnded(\(reason))"
        case .error(let code, let message):
            return "Error(\(code): \(message))"
        default:
            return String(describing: self)
        }
    }
}
