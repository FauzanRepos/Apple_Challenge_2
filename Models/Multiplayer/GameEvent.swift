//
//  GameEvent.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Game Event Model
struct GameEvent: Codable, Identifiable {
    
    let id: String
    let type: GameEventType
    let timestamp: Date
    let playerId: String?
    let sessionId: String
    let data: GameEventData
    let priority: EventPriority
    let requiresAcknowledgment: Bool
    let expiresAt: Date?
    
    // Network Properties
    var isProcessed: Bool = false
    let networkId: String
    let sourceDeviceId: String
    
    // MARK: - Initialization
    init(
        type: GameEventType,
        playerId: String? = nil,
        sessionId: String,
        data: GameEventData = .empty,
        priority: EventPriority = .normal,
        requiresAcknowledgment: Bool = false,
        expiresIn: TimeInterval? = nil
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
        self.playerId = playerId
        self.sessionId = sessionId
        self.data = data
        self.priority = priority
        self.requiresAcknowledgment = requiresAcknowledgment
        self.networkId = "\(type.rawValue)_\(Int(timestamp.timeIntervalSince1970))"
        self.sourceDeviceId = UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
        
        if let expiry = expiresIn {
            self.expiresAt = Date().addingTimeInterval(expiry)
        } else {
            self.expiresAt = nil
        }
    }
    
    // MARK: - Event Properties
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date() > expiresAt
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    var isRecentEvent: Bool {
        return age < 5.0 // Less than 5 seconds old
    }
    
    var displayMessage: String {
        return type.getDisplayMessage(data: data, playerId: playerId)
    }
    
    var shouldBroadcast: Bool {
        return type.shouldBroadcast
    }
    
    var requiresGameStateUpdate: Bool {
        return type.requiresGameStateUpdate
    }
    
    // MARK: - Event Processing
    mutating func markAsProcessed() {
        isProcessed = true
    }
    
    func validate() -> EventValidationResult {
        // Check expiration
        if isExpired {
            return EventValidationResult(isValid: false, error: "Event has expired")
        }
        
        // Validate player ID if required
        if type.requiresPlayerId && playerId == nil {
            return EventValidationResult(isValid: false, error: "Player ID is required for this event type")
        }
        
        // Validate data
        let dataValidation = type.validateData(data)
        if !dataValidation.isValid {
            return dataValidation
        }
        
        return EventValidationResult(isValid: true, error: nil)
    }
    
    // MARK: - Event Data Accessors
    func getPlayerMovement() -> (position: CGPoint, velocity: CGVector)? {
        if case .playerMovement(let position, let velocity) = data {
            return (position, velocity)
        }
        return nil
    }
    
    func getCheckpointId() -> String? {
        if case .checkpointReached(let checkpointId) = data {
            return checkpointId
        }
        return nil
    }
    
    func getPowerUpInfo() -> (id: String, type: PowerUpType)? {
        if case .powerUpCollected(let id, let type) = data {
            return (id, type)
        }
        return nil
    }
    
    func getScoreChange() -> Int? {
        if case .scoreUpdated(let score) = data {
            return score
        }
        return nil
    }
    
    func getMapOffset() -> CGPoint? {
        if case .mapScrolled(let offset) = data {
            return offset
        }
        return nil
    }
    
    func getLevelNumber() -> Int? {
        if case .levelAdvanced(let level) = data {
            return level
        }
        return nil
    }
    
    func getGameEndReason() -> GameEndReason? {
        if case .gameEnded(let reason) = data {
            return reason
        }
        return nil
    }
    
    func getChatMessage() -> String? {
        if case .chatMessage(let message) = data {
            return message
        }
        return nil
    }
    
    func getCustomData() -> [String: Any]? {
        if case .custom(let data) = data {
            return data
        }
        return nil
    }
}

// MARK: - Game Event Types
enum GameEventType: String, Codable, CaseIterable {
    // Connection Events
    case playerJoined = "playerJoined"
    case playerLeft = "playerLeft"
    case playerReady = "playerReady"
    case playerReconnected = "playerReconnected"
    
    // Game State Events
    case gameStarted = "gameStarted"
    case gamePaused = "gamePaused"
    case gameResumed = "gameResumed"
    case gameEnded = "gameEnded"
    case levelCompleted = "levelCompleted"
    case levelAdvanced = "levelAdvanced"
    
    // Player Movement Events
    case playerMovement = "playerMovement"
    case mapScrolled = "mapScrolled"
    case playerRespawned = "playerRespawned"
    
    // Game Interaction Events
    case checkpointReached = "checkpointReached"
    case powerUpCollected = "powerUpCollected"
    case playerDied = "playerDied"
    case vortexCollision = "vortexCollision"
    case wallCollision = "wallCollision"
    
    // Score and Progress Events
    case scoreUpdated = "scoreUpdated"
    case livesUpdated = "livesUpdated"
    case achievementUnlocked = "achievementUnlocked"
    
    // Communication Events
    case chatMessage = "chatMessage"
    case playerEmote = "playerEmote"
    case systemMessage = "systemMessage"
    
    // Network Events
    case connectionQualityChanged = "connectionQualityChanged"
    case syncIssue = "syncIssue"
    case heartbeat = "heartbeat"
    
    // Custom Events
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .playerJoined: return "Player Joined"
        case .playerLeft: return "Player Left"
        case .playerReady: return "Player Ready"
        case .playerReconnected: return "Player Reconnected"
        case .gameStarted: return "Game Started"
        case .gamePaused: return "Game Paused"
        case .gameResumed: return "Game Resumed"
        case .gameEnded: return "Game Ended"
        case .levelCompleted: return "Level Completed"
        case .levelAdvanced: return "Level Advanced"
        case .playerMovement: return "Player Movement"
        case .mapScrolled: return "Map Scrolled"
        case .playerRespawned: return "Player Respawned"
        case .checkpointReached: return "Checkpoint Reached"
        case .powerUpCollected: return "Power-up Collected"
        case .playerDied: return "Player Died"
        case .vortexCollision: return "Vortex Collision"
        case .wallCollision: return "Wall Collision"
        case .scoreUpdated: return "Score Updated"
        case .livesUpdated: return "Lives Updated"
        case .achievementUnlocked: return "Achievement Unlocked"
        case .chatMessage: return "Chat Message"
        case .playerEmote: return "Player Emote"
        case .systemMessage: return "System Message"
        case .connectionQualityChanged: return "Connection Quality Changed"
        case .syncIssue: return "Sync Issue"
        case .heartbeat: return "Heartbeat"
        case .custom: return "Custom Event"
        }
    }
    
    var shouldBroadcast: Bool {
        switch self {
        case .playerMovement, .heartbeat:
            return false // Too frequent, handle separately
        case .syncIssue, .connectionQualityChanged:
            return false // Internal network events
        default:
            return true
        }
    }
    
    var requiresPlayerId: Bool {
        switch self {
        case .systemMessage, .gameStarted, .gameEnded, .levelCompleted, .levelAdvanced:
            return false
        default:
            return true
        }
    }
    
    var requiresGameStateUpdate: Bool {
        switch self {
        case .checkpointReached, .powerUpCollected, .playerDied, .scoreUpdated, .livesUpdated, .levelAdvanced:
            return true
        default:
            return false
        }
    }
    
    var defaultPriority: EventPriority {
        switch self {
        case .playerDied, .gameEnded, .vortexCollision:
            return .critical
        case .checkpointReached, .powerUpCollected, .levelCompleted, .achievementUnlocked:
            return .high
        case .playerJoined, .playerLeft, .gameStarted, .scoreUpdated:
            return .normal
        case .playerMovement, .mapScrolled, .heartbeat:
            return .low
        default:
            return .normal
        }
    }
    
    func getDisplayMessage(data: GameEventData, playerId: String?) -> String {
        let playerName = playerId ?? "Someone"
        
        switch self {
        case .playerJoined:
            return "\(playerName) joined the game"
        case .playerLeft:
            return "\(playerName) left the game"
        case .playerReady:
            return "\(playerName) is ready"
        case .playerReconnected:
            return "\(playerName) reconnected"
        case .gameStarted:
            return "Game started!"
        case .gamePaused:
            return "Game paused"
        case .gameResumed:
            return "Game resumed"
        case .gameEnded:
            if case .gameEnded(let reason) = data {
                return "Game ended: \(reason.displayMessage)"
            }
            return "Game ended"
        case .levelCompleted:
            return "Level completed!"
        case .levelAdvanced:
            if case .levelAdvanced(let level) = data {
                return "Advanced to level \(level)"
            }
            return "Advanced to next level"
        case .checkpointReached:
            return "\(playerName) reached a checkpoint"
        case .powerUpCollected:
            if case .powerUpCollected(_, let type) = data {
                return "\(playerName) collected \(type.displayName)"
            }
            return "\(playerName) collected a power-up"
        case .playerDied:
            return "\(playerName) was eliminated"
        case .scoreUpdated:
            if case .scoreUpdated(let score) = data {
                return "Score: \(score)"
            }
            return "Score updated"
        case .achievementUnlocked:
            return "\(playerName) unlocked an achievement!"
        case .chatMessage:
            if case .chatMessage(let message) = data {
                return "\(playerName): \(message)"
            }
            return "\(playerName) sent a message"
        default:
            return displayName
        }
    }
    
    func validateData(_ data: GameEventData) -> EventValidationResult {
        switch self {
        case .playerMovement:
            if case .playerMovement(let position, let velocity) = data {
                if !position.isValid || velocity.dx.isNaN || velocity.dy.isNaN {
                    return EventValidationResult(isValid: false, error: "Invalid movement data")
                }
            } else {
                return EventValidationResult(isValid: false, error: "Missing movement data")
            }
            
        case .checkpointReached:
            if case .checkpointReached(let checkpointId) = data {
                if checkpointId.isEmpty {
                    return EventValidationResult(isValid: false, error: "Empty checkpoint ID")
                }
            } else {
                return EventValidationResult(isValid: false, error: "Missing checkpoint data")
            }
            
        case .chatMessage:
            if case .chatMessage(let message) = data {
                if message.isEmpty || message.count > 200 {
                    return EventValidationResult(isValid: false, error: "Invalid chat message")
                }
            } else {
                return EventValidationResult(isValid: false, error: "Missing chat message")
            }
            
        default:
            break // Most events don't need specific validation
        }
        
        return EventValidationResult(isValid: true, error: nil)
    }
}

// MARK: - Game Event Data
enum GameEventData: Codable {
    case empty
    case playerMovement(position: CGPoint, velocity: CGVector)
    case mapScrolled(offset: CGPoint)
    case checkpointReached(checkpointId: String)
    case powerUpCollected(id: String, type: PowerUpType)
    case playerDied(reason: String)
    case scoreUpdated(score: Int)
    case livesUpdated(lives: Int)
    case levelAdvanced(level: Int)
    case gameEnded(reason: GameEndReason)
    case chatMessage(message: String)
    case playerEmote(emote: String)
    case systemMessage(message: String)
    case achievementUnlocked(achievement: String)
    case connectionQuality(quality: NetworkQuality)
    case syncData(data: [String: Any])
    case custom(data: [String: Any])
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case type
        case position, velocity, offset, checkpointId, id, powerUpType
        case reason, score, lives, level, message, emote, achievement
        case quality, data
    }
    
    private enum DataType: String, Codable {
        case empty, playerMovement, mapScrolled, checkpointReached
        case powerUpCollected, playerDied, scoreUpdated, livesUpdated
        case levelAdvanced, gameEnded, chatMessage, playerEmote
        case systemMessage, achievementUnlocked, connectionQuality
        case syncData, custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DataType.self, forKey: .type)
        
        switch type {
        case .empty:
            self = .empty
        case .playerMovement:
            let position = try container.decode(CGPoint.self, forKey: .position)
            let velocity = try container.decode(CGVector.self, forKey: .velocity)
            self = .playerMovement(position: position, velocity: velocity)
        case .mapScrolled:
            let offset = try container.decode(CGPoint.self, forKey: .offset)
            self = .mapScrolled(offset: offset)
        case .checkpointReached:
            let checkpointId = try container.decode(String.self, forKey: .checkpointId)
            self = .checkpointReached(checkpointId: checkpointId)
        case .powerUpCollected:
            let id = try container.decode(String.self, forKey: .id)
            let powerUpType = try container.decode(PowerUpType.self, forKey: .powerUpType)
            self = .powerUpCollected(id: id, type: powerUpType)
        case .playerDied:
            let reason = try container.decode(String.self, forKey: .reason)
            self = .playerDied(reason: reason)
        case .scoreUpdated:
            let score = try container.decode(Int.self, forKey: .score)
            self = .scoreUpdated(score: score)
        case .livesUpdated:
            let lives = try container.decode(Int.self, forKey: .lives)
            self = .livesUpdated(lives: lives)
        case .levelAdvanced:
            let level = try container.decode(Int.self, forKey: .level)
            self = .levelAdvanced(level: level)
        case .gameEnded:
            let reason = try container.decode(GameEndReason.self, forKey: .reason)
            self = .gameEnded(reason: reason)
        case .chatMessage:
            let message = try container.decode(String.self, forKey: .message)
            self = .chatMessage(message: message)
        case .playerEmote:
            let emote = try container.decode(String.self, forKey: .emote)
            self = .playerEmote(emote: emote)
        case .systemMessage:
            let message = try container.decode(String.self, forKey: .message)
            self = .systemMessage(message: message)
        case .achievementUnlocked:
            let achievement = try container.decode(String.self, forKey: .achievement)
            self = .achievementUnlocked(achievement: achievement)
        case .connectionQuality:
            let quality = try container.decode(NetworkQuality.self, forKey: .quality)
            self = .connectionQuality(quality: quality)
        case .syncData, .custom:
            // Note: [String: Any] is not directly Codable, would need special handling
            self = .custom(data: [:])
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .empty:
            try container.encode(DataType.empty, forKey: .type)
        case .playerMovement(let position, let velocity):
            try container.encode(DataType.playerMovement, forKey: .type)
            try container.encode(position, forKey: .position)
            try container.encode(velocity, forKey: .velocity)
        case .mapScrolled(let offset):
            try container.encode(DataType.mapScrolled, forKey: .type)
            try container.encode(offset, forKey: .offset)
        case .checkpointReached(let checkpointId):
            try container.encode(DataType.checkpointReached, forKey: .type)
            try container.encode(checkpointId, forKey: .checkpointId)
        case .powerUpCollected(let id, let type):
            try container.encode(DataType.powerUpCollected, forKey: .type)
            try container.encode(id, forKey: .id)
            try container.encode(type, forKey: .powerUpType)
        case .playerDied(let reason):
            try container.encode(DataType.playerDied, forKey: .type)
            try container.encode(reason, forKey: .reason)
        case .scoreUpdated(let score):
            try container.encode(DataType.scoreUpdated, forKey: .type)
            try container.encode(score, forKey: .score)
        case .livesUpdated(let lives):
            try container.encode(DataType.livesUpdated, forKey: .type)
            try container.encode(lives, forKey: .lives)
        case .levelAdvanced(let level):
            try container.encode(DataType.levelAdvanced, forKey: .type)
            try container.encode(level, forKey: .level)
        case .gameEnded(let reason):
            try container.encode(DataType.gameEnded, forKey: .type)
            try container.encode(reason, forKey: .reason)
        case .chatMessage(let message):
            try container.encode(DataType.chatMessage, forKey: .type)
            try container.encode(message, forKey: .message)
        case .playerEmote(let emote):
            try container.encode(DataType.playerEmote, forKey: .type)
            try container.encode(emote, forKey: .emote)
        case .systemMessage(let message):
            try container.encode(DataType.systemMessage, forKey: .type)
            try container.encode(message, forKey: .message)
        case .achievementUnlocked(let achievement):
            try container.encode(DataType.achievementUnlocked, forKey: .type)
            try container.encode(achievement, forKey: .achievement)
        case .connectionQuality(let quality):
            try container.encode(DataType.connectionQuality, forKey: .type)
            try container.encode(quality, forKey: .quality)
        case .syncData:
            try container.encode(DataType.syncData, forKey: .type)
        case .custom:
            try container.encode(DataType.custom, forKey: .type)
        }
    }
}

// MARK: - Event Priority
enum EventPriority: Int, Codable, CaseIterable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    var displayName: String {
        return String(describing: self).capitalized
    }
    
    static func < (lhs: EventPriority, rhs: EventPriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Event Validation Result
struct EventValidationResult {
    let isValid: Bool
    let error: String?
    
    static let valid = EventValidationResult(isValid: true, error: nil)
}

// MARK: - Game Event Factory
struct GameEventFactory {
    
    static func createPlayerJoinedEvent(playerId: String, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .playerJoined,
            playerId: playerId,
            sessionId: sessionId,
            priority: .normal,
            requiresAcknowledgment: true
        )
    }
    
    static func createPlayerMovementEvent(playerId: String, position: CGPoint, velocity: CGVector, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .playerMovement,
            playerId: playerId,
            sessionId: sessionId,
            data: .playerMovement(position: position, velocity: velocity),
            priority: .low,
            expiresIn: 1.0
        )
    }
    
    static func createCheckpointReachedEvent(playerId: String, checkpointId: String, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .checkpointReached,
            playerId: playerId,
            sessionId: sessionId,
            data: .checkpointReached(checkpointId: checkpointId),
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createPowerUpCollectedEvent(playerId: String, powerUpId: String, type: PowerUpType, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .powerUpCollected,
            playerId: playerId,
            sessionId: sessionId,
            data: .powerUpCollected(id: powerUpId, type: type),
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createPlayerDiedEvent(playerId: String, reason: String, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .playerDied,
            playerId: playerId,
            sessionId: sessionId,
            data: .playerDied(reason: reason),
            priority: .critical,
            requiresAcknowledgment: true
        )
    }
    
    static func createGameStartedEvent(sessionId: String) -> GameEvent {
        return GameEvent(
            type: .gameStarted,
            sessionId: sessionId,
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createGameEndedEvent(reason: GameEndReason, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .gameEnded,
            sessionId: sessionId,
            data: .gameEnded(reason: reason),
            priority: .critical,
            requiresAcknowledgment: true
        )
    }
    
    static func createChatMessageEvent(playerId: String, message: String, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .chatMessage,
            playerId: playerId,
            sessionId: sessionId,
            data: .chatMessage(message: message),
            priority: .normal,
            expiresIn: 300 // 5 minutes
        )
    }
    
    static func createScoreUpdatedEvent(playerId: String, score: Int, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .scoreUpdated,
            playerId: playerId,
            sessionId: sessionId,
            data: .scoreUpdated(score: score),
            priority: .normal
        )
    }
    
    static func createLevelAdvancedEvent(level: Int, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .levelAdvanced,
            sessionId: sessionId,
            data: .levelAdvanced(level: level),
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createHeartbeatEvent(playerId: String, sessionId: String) -> GameEvent {
        return GameEvent(
            type: .heartbeat,
            playerId: playerId,
            sessionId: sessionId,
            priority: .low,
            expiresIn: 5.0
        )
    }
}

// MARK: - GameEvent Extensions
extension GameEvent {
    
    // MARK: - Equatable
    static func == (lhs: GameEvent, rhs: GameEvent) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Comparable (by priority, then timestamp)
    static func < (lhs: GameEvent, rhs: GameEvent) -> Bool {
        if lhs.priority != rhs.priority {
            return lhs.priority > rhs.priority // Higher priority first
        }
        return lhs.timestamp < rhs.timestamp // Older events first for same priority
    }
}

// MARK: - Array Extensions
extension Array where Element == GameEvent {
    
    func sortedByPriority() -> [GameEvent] {
        return sorted()
    }
    
    func filterByType(_ type: GameEventType) -> [GameEvent] {
        return filter { $0.type == type }
    }
    
    func filterByPlayer(_ playerId: String) -> [GameEvent] {
        return filter { $0.playerId == playerId }
    }
    
    func filterRecent(within timeInterval: TimeInterval = 60.0) -> [GameEvent] {
        let cutoff = Date().addingTimeInterval(-timeInterval)
        return filter { $0.timestamp >= cutoff }
    }
    
    func filterUnprocessed() -> [GameEvent] {
        return filter { !$0.isProcessed }
    }
    
    func filterValid() -> [GameEvent] {
        return filter { $0.validate().isValid }
    }
    
    func removeExpired() -> [GameEvent] {
        return filter { !$0.isExpired }
    }
    
    func groupByType() -> [GameEventType: [GameEvent]] {
        return Dictionary(grouping: self) { $0.type }
    }
    
    func groupByPlayer() -> [String: [GameEvent]] {
        return Dictionary(grouping: self.compactMap { event in
            guard let playerId = event.playerId else { return nil }
            return (playerId, event)
        }) { $0.0 }.mapValues { $0.map { $0.1 } }
    }
    
    mutating func markAllAsProcessed() {
        for i in indices {
            self[i].markAsProcessed()
        }
    }
    
    func getEventSummary() -> String {
        let total = count
        let unprocessed = filterUnprocessed().count
        let expired = filter { $0.isExpired }.count
        let critical = filter { $0.priority == .critical }.count
        
        return "Events: \(total) total, \(unprocessed) unprocessed, \(expired) expired, \(critical) critical"
    }
}
