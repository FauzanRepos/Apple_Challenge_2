//
//  NetworkMessage.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Network Message
struct NetworkMessage: Codable {
    
    let id: String
    let type: MessageType
    let timestamp: Date
    let senderId: String
    let data: MessageData
    let priority: MessagePriority
    let requiresAcknowledgment: Bool
    
    init(
        type: MessageType,
        senderId: String,
        data: MessageData = .empty,
        priority: MessagePriority = .normal,
        requiresAcknowledgment: Bool = false
    ) {
        self.id = UUID().uuidString
        self.type = type
        self.timestamp = Date()
        self.senderId = senderId
        self.data = data
        self.priority = priority
        self.requiresAcknowledgment = requiresAcknowledgment
    }
    
    // MARK: - Message Properties
    var age: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
    
    var isExpired: Bool {
        let maxAge: TimeInterval
        switch type {
        case .playerMovement: maxAge = 1.0
        case .heartbeat: maxAge = 5.0
        case .gameState: maxAge = 2.0
        default: maxAge = 30.0
        }
        return age > maxAge
    }
    
    var sizeEstimate: Int {
        return (try? JSONEncoder().encode(self).count) ?? 0
    }
}

// MARK: - Message Types
enum MessageType: String, Codable, CaseIterable {
    // Connection Messages
    case playerJoined = "playerJoined"
    case playerLeft = "playerLeft"
    case playerReady = "playerReady"
    case heartbeat = "heartbeat"
    
    // Game Control Messages
    case gameStart = "gameStart"
    case gamePause = "gamePause"
    case gameResume = "gameResume"
    case gameEnd = "gameEnd"
    case levelAdvance = "levelAdvance"
    
    // Gameplay Messages
    case playerMovement = "playerMovement"
    case checkpointReached = "checkpointReached"
    case powerUpCollected = "powerUpCollected"
    case playerDied = "playerDied"
    case mapScrolled = "mapScrolled"
    
    // Synchronization Messages
    case gameState = "gameState"
    case syncRequest = "syncRequest"
    case acknowledgment = "acknowledgment"
    
    // Chat Messages
    case chatMessage = "chatMessage"
    case systemMessage = "systemMessage"
    
    var shouldBroadcast: Bool {
        switch self {
        case .heartbeat, .acknowledgment:
            return false
        default:
            return true
        }
    }
    
    var isHighPriority: Bool {
        switch self {
        case .gameStart, .gameEnd, .playerDied:
            return true
        default:
            return false
        }
    }
}

// MARK: - Message Data
enum MessageData: Codable {
    case empty
    case playerInfo(NetworkPlayerData)
    case movement(position: CGPoint, velocity: CGVector)
    case checkpoint(checkpointId: String)
    case powerUp(powerUpId: String, type: String)
    case gameState(GameStateData)
    case chat(message: String)
    case mapScroll(offset: CGPoint)
    case acknowledgment(messageId: String)
    case custom([String: String])
    
    // MARK: - Codable Implementation
    private enum CodingKeys: String, CodingKey {
        case type
        case playerInfo, position, velocity, checkpointId
        case powerUpId, powerUpType, gameState, message
        case offset, messageId, custom
    }
    
    private enum DataType: String, Codable {
        case empty, playerInfo, movement, checkpoint, powerUp
        case gameState, chat, mapScroll, acknowledgment, custom
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(DataType.self, forKey: .type)
        
        switch type {
        case .empty:
            self = .empty
        case .playerInfo:
            let playerInfo = try container.decode(NetworkPlayerData.self, forKey: .playerInfo)
            self = .playerInfo(playerInfo)
        case .movement:
            let position = try container.decode(CGPoint.self, forKey: .position)
            let velocity = try container.decode(CGVector.self, forKey: .velocity)
            self = .movement(position: position, velocity: velocity)
        case .checkpoint:
            let checkpointId = try container.decode(String.self, forKey: .checkpointId)
            self = .checkpoint(checkpointId: checkpointId)
        case .powerUp:
            let powerUpId = try container.decode(String.self, forKey: .powerUpId)
            let powerUpType = try container.decode(String.self, forKey: .powerUpType)
            self = .powerUp(powerUpId: powerUpId, type: powerUpType)
        case .gameState:
            let gameState = try container.decode(GameStateData.self, forKey: .gameState)
            self = .gameState(gameState)
        case .chat:
            let message = try container.decode(String.self, forKey: .message)
            self = .chat(message: message)
        case .mapScroll:
            let offset = try container.decode(CGPoint.self, forKey: .offset)
            self = .mapScroll(offset: offset)
        case .acknowledgment:
            let messageId = try container.decode(String.self, forKey: .messageId)
            self = .acknowledgment(messageId: messageId)
        case .custom:
            let custom = try container.decode([String: String].self, forKey: .custom)
            self = .custom(custom)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .empty:
            try container.encode(DataType.empty, forKey: .type)
        case .playerInfo(let playerInfo):
            try container.encode(DataType.playerInfo, forKey: .type)
            try container.encode(playerInfo, forKey: .playerInfo)
        case .movement(let position, let velocity):
            try container.encode(DataType.movement, forKey: .type)
            try container.encode(position, forKey: .position)
            try container.encode(velocity, forKey: .velocity)
        case .checkpoint(let checkpointId):
            try container.encode(DataType.checkpoint, forKey: .type)
            try container.encode(checkpointId, forKey: .checkpointId)
        case .powerUp(let powerUpId, let type):
            try container.encode(DataType.powerUp, forKey: .type)
            try container.encode(powerUpId, forKey: .powerUpId)
            try container.encode(type, forKey: .powerUpType)
        case .gameState(let gameState):
            try container.encode(DataType.gameState, forKey: .type)
            try container.encode(gameState, forKey: .gameState)
        case .chat(let message):
            try container.encode(DataType.chat, forKey: .type)
            try container.encode(message, forKey: .message)
        case .mapScroll(let offset):
            try container.encode(DataType.mapScroll, forKey: .type)
            try container.encode(offset, forKey: .offset)
        case .acknowledgment(let messageId):
            try container.encode(DataType.acknowledgment, forKey: .type)
            try container.encode(messageId, forKey: .messageId)
        case .custom(let custom):
            try container.encode(DataType.custom, forKey: .type)
            try container.encode(custom, forKey: .custom)
        }
    }
}

// MARK: - Message Priority
enum MessagePriority: Int, Codable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case critical = 3
    
    static func < (lhs: MessagePriority, rhs: MessagePriority) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Supporting Data Types
struct NetworkPlayerData: Codable {
    let id: String
    let name: String
    let isHost: Bool
    let isReady: Bool
    let playerType: String
    let score: Int
    let lives: Int
}

struct GameStateData: Codable {
    let currentLevel: Int
    let teamScore: Int
    let teamLives: Int
    let gameStarted: Bool
    let gamePaused: Bool
    let completedCheckpoints: [String]
    let playerPositions: [String: CGPoint]
}

// MARK: - Message Factory
struct MessageFactory {
    
    static func createPlayerJoinedMessage(player: NetworkPlayer) -> NetworkMessage {
        let playerData = NetworkPlayerData(
            id: player.id,
            name: player.name,
            isHost: player.isHost,
            isReady: player.isReady,
            playerType: player.playerType.rawValue,
            score: player.score,
            lives: player.lives
        )
        
        return NetworkMessage(
            type: .playerJoined,
            senderId: player.id,
            data: .playerInfo(playerData),
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createPlayerMovementMessage(playerId: String, position: CGPoint, velocity: CGVector) -> NetworkMessage {
        return NetworkMessage(
            type: .playerMovement,
            senderId: playerId,
            data: .movement(position: position, velocity: velocity),
            priority: .low
        )
    }
    
    static func createCheckpointMessage(playerId: String, checkpointId: String) -> NetworkMessage {
        return NetworkMessage(
            type: .checkpointReached,
            senderId: playerId,
            data: .checkpoint(checkpointId: checkpointId),
            priority: .high,
            requiresAcknowledgment: true
        )
    }
    
    static func createPowerUpMessage(playerId: String, powerUpId: String, type: String) -> NetworkMessage {
        return NetworkMessage(
            type: .powerUpCollected,
            senderId: playerId,
            data: .powerUp(powerUpId: powerUpId, type: type),
            priority: .normal,
            requiresAcknowledgment: true
        )
    }
    
    static func createGameStartMessage(hostId: String) -> NetworkMessage {
        return NetworkMessage(
            type: .gameStart,
            senderId: hostId,
            priority: .critical,
            requiresAcknowledgment: true
        )
    }
    
    static func createGameEndMessage(hostId: String, reason: String) -> NetworkMessage {
        return NetworkMessage(
            type: .gameEnd,
            senderId: hostId,
            data: .custom(["reason": reason]),
            priority: .critical,
            requiresAcknowledgment: true
        )
    }
    
    static func createHeartbeatMessage(playerId: String) -> NetworkMessage {
        return NetworkMessage(
            type: .heartbeat,
            senderId: playerId,
            priority: .low
        )
    }
    
    static func createChatMessage(playerId: String, message: String) -> NetworkMessage {
        return NetworkMessage(
            type: .chatMessage,
            senderId: playerId,
            data: .chat(message: message),
            priority: .normal
        )
    }
    
    static func createAcknowledgmentMessage(playerId: String, messageId: String) -> NetworkMessage {
        return NetworkMessage(
            type: .acknowledgment,
            senderId: playerId,
            data: .acknowledgment(messageId: messageId),
            priority: .low
        )
    }
    
    static func createGameStateMessage(hostId: String, gameState: GameStateData) -> NetworkMessage {
        return NetworkMessage(
            type: .gameState,
            senderId: hostId,
            data: .gameState(gameState),
            priority: .high
        )
    }
}

// MARK: - Message Validation
extension NetworkMessage {
    
    func validate() -> Bool {
        // Check message age
        if isExpired {
            return false
        }
        
        // Check sender ID
        if senderId.isEmpty {
            return false
        }
        
        // Validate data based on type
        switch type {
        case .playerMovement:
            if case .movement = data {
                return true
            }
            return false
            
        case .checkpointReached:
            if case .checkpoint = data {
                return true
            }
            return false
            
        case .chatMessage:
            if case .chat(let message) = data {
                return !message.isEmpty && message.count <= 200
            }
            return false
            
        default:
            return true
        }
    }
}

// MARK: - Message Queue
class MessageQueue {
    
    private var messages: [NetworkMessage] = []
    private let queue = DispatchQueue(label: "messageQueue", qos: .userInitiated)
    private let maxQueueSize = 100
    
    func enqueue(_ message: NetworkMessage) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.messages.append(message)
            
            // Sort by priority and timestamp
            self.messages.sort { msg1, msg2 in
                if msg1.priority != msg2.priority {
                    return msg1.priority > msg2.priority
                }
                return msg1.timestamp < msg2.timestamp
            }
            
            // Remove old messages if queue is full
            if self.messages.count > self.maxQueueSize {
                self.messages.removeFirst(self.messages.count - self.maxQueueSize)
            }
        }
    }
    
    func dequeue() -> NetworkMessage? {
        return queue.sync { [weak self] in
            guard let self = self, !self.messages.isEmpty else { return nil }
            return self.messages.removeFirst()
        }
    }
    
    func peek() -> NetworkMessage? {
        return queue.sync { [weak self] in
            return self?.messages.first
        }
    }
    
    func removeExpiredMessages() {
        queue.async { [weak self] in
            self?.messages.removeAll { $0.isExpired }
        }
    }
    
    func clear() {
        queue.async { [weak self] in
            self?.messages.removeAll()
        }
    }
    
    var count: Int {
        return queue.sync { [weak self] in
            return self?.messages.count ?? 0
        }
    }
    
    var isEmpty: Bool {
        return count == 0
    }
}
