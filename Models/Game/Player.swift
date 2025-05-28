//
//  Player.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics
import MultipeerConnectivity

// MARK: - Player Model
class Player: ObservableObject, Identifiable, Codable {
    
    let id: String
    @Published var name: String
    @Published var score: Int
    @Published var lives: Int
    @Published var isReady: Bool
    @Published var playerType: PlayerType
    @Published var position: CGPoint
    @Published var velocity: CGVector
    @Published var lastCheckpointId: String?
    @Published var activePowerUps: [ActivePowerUp]
    @Published var isAlive: Bool
    @Published var respawnTimer: TimeInterval?
    
    // Local game state
    var isLocal: Bool
    var lastUpdateTimestamp: TimeInterval
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        name: String = "Player",
        playerType: PlayerType = .regular,
        isLocal: Bool = false
    ) {
        self.id = id
        self.name = name
        self.score = 0
        self.lives = Constants.defaultPlayerLives
        self.isReady = false
        self.playerType = playerType
        self.position = CGPoint.zero
        self.velocity = CGVector.zero
        self.lastCheckpointId = nil
        self.activePowerUps = []
        self.isAlive = true
        self.respawnTimer = nil
        self.isLocal = isLocal
        self.lastUpdateTimestamp = Date().timeIntervalSince1970
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, score, lives, isReady, playerType
        case position, velocity, lastCheckpointId, activePowerUps
        case isAlive, respawnTimer, isLocal, lastUpdateTimestamp
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        score = try container.decode(Int.self, forKey: .score)
        lives = try container.decode(Int.self, forKey: .lives)
        isReady = try container.decode(Bool.self, forKey: .isReady)
        playerType = try container.decode(PlayerType.self, forKey: .playerType)
        position = try container.decode(CGPoint.self, forKey: .position)
        velocity = try container.decode(CGVector.self, forKey: .velocity)
        lastCheckpointId = try container.decodeIfPresent(String.self, forKey: .lastCheckpointId)
        activePowerUps = try container.decode([ActivePowerUp].self, forKey: .activePowerUps)
        isAlive = try container.decode(Bool.self, forKey: .isAlive)
        respawnTimer = try container.decodeIfPresent(TimeInterval.self, forKey: .respawnTimer)
        isLocal = try container.decode(Bool.self, forKey: .isLocal)
        lastUpdateTimestamp = try container.decode(TimeInterval.self, forKey: .lastUpdateTimestamp)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(score, forKey: .score)
        try container.encode(lives, forKey: .lives)
        try container.encode(isReady, forKey: .isReady)
        try container.encode(playerType, forKey: .playerType)
        try container.encode(position, forKey: .position)
        try container.encode(velocity, forKey: .velocity)
        try container.encode(lastCheckpointId, forKey: .lastCheckpointId)
        try container.encode(activePowerUps, forKey: .activePowerUps)
        try container.encode(isAlive, forKey: .isAlive)
        try container.encode(respawnTimer, forKey: .respawnTimer)
        try container.encode(isLocal, forKey: .isLocal)
        try container.encode(lastUpdateTimestamp, forKey: .lastUpdateTimestamp)
    }
    
    // MARK: - Player Actions
    func updatePosition(_ newPosition: CGPoint, velocity newVelocity: CGVector) {
        position = newPosition
        velocity = newVelocity
        lastUpdateTimestamp = Date().timeIntervalSince1970
    }
    
    func addScore(_ points: Int) {
        score += points
    }
    
    func loseLife() {
        lives = max(0, lives - 1)
        if lives <= 0 {
            die()
        }
    }
    
    func die() {
        isAlive = false
        velocity = CGVector.zero
        respawnTimer = Constants.defaultRespawnDelay
    }
    
    func respawn(at checkpointPosition: CGPoint) {
        isAlive = true
        position = checkpointPosition
        velocity = CGVector.zero
        respawnTimer = nil
        
        // Add temporary invulnerability
        addInvulnerability()
    }
    
    func reachCheckpoint(_ checkpointId: String) {
        lastCheckpointId = checkpointId
        addScore(Constants.checkpointScore)
    }
    
    func collectPowerUp(_ powerUp: PowerUp) {
        let activePowerUp = ActivePowerUp(
            id: UUID().uuidString,
            type: powerUp.type,
            playerId: id,
            activatedAt: Date(),
            duration: powerUp.duration
        )
        
        activePowerUps.append(activePowerUp)
        addScore(Constants.starCollectionScore)
    }
    
    func updateActivePowerUps() {
        let now = Date()
        activePowerUps.removeAll { powerUp in
            now.timeIntervalSince(powerUp.activatedAt) >= powerUp.duration
        }
    }
    
    func getSpeedMultiplier() -> CGFloat {
        var multiplier: CGFloat = 1.0
        
        for powerUp in activePowerUps {
            switch powerUp.type {
            case .oil:
                multiplier *= Constants.oilSpeedMultiplier
            case .grass:
                multiplier *= Constants.grassSpeedMultiplier
            }
        }
        
        return multiplier
    }
    
    func hasActivePowerUp(of type: PowerUpType) -> Bool {
        return activePowerUps.contains { $0.type == type }
    }
    
    func setReady(_ ready: Bool) {
        isReady = ready
    }
    
    func reset() {
        score = 0
        lives = Constants.defaultPlayerLives
        isReady = false
        position = CGPoint.zero
        velocity = CGVector.zero
        lastCheckpointId = nil
        activePowerUps.removeAll()
        isAlive = true
        respawnTimer = nil
    }
    
    // MARK: - Private Methods
    private func addInvulnerability() {
        let invulnerability = ActivePowerUp(
            id: UUID().uuidString,
            type: PowerUpType.invulnerability,
            playerId: id,
            activatedAt: Date(),
            duration: 2.0
        )
        activePowerUps.append(invulnerability)
    }
    
    // MARK: - Computed Properties
    var isInvulnerable: Bool {
        return hasActivePowerUp(of: PowerUpType.invulnerability)
    }
    
    var displayName: String {
        return name.isEmpty ? "Player \(id.prefix(4))" : name
    }
    
    var statusDescription: String {
        if !isAlive {
            return "Dead"
        } else if respawnTimer != nil {
            return "Respawning..."
        } else if !activePowerUps.isEmpty {
            let powerUpNames = activePowerUps.map { $0.type.displayName }
            return "Active: \(powerUpNames.joined(separator: ", "))"
        } else {
            return "Ready"
        }
    }
    
    var healthPercentage: Double {
        return Double(lives) / Double(Constants.defaultPlayerLives)
    }
}

// MARK: - Equatable & Hashable
extension Player: Equatable, Hashable {
    static func == (lhs: Player, rhs: Player) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Active Power Up
struct ActivePowerUp: Codable, Identifiable {
    let id: String
    let type: PowerUpType
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
    
    var progress: Double {
        let elapsed = Date().timeIntervalSince(activatedAt)
        return min(1.0, elapsed / duration)
    }
}

// MARK: - Player Factory
struct PlayerFactory {
    static func createLocalPlayer(name: String = "", type: PlayerType = .regular) -> Player {
        let playerName = name.isEmpty ? SettingsManager.shared.getPlayerName() : name
        return Player(
            id: UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString,
            name: playerName,
            playerType: type,
            isLocal: true
        )
    }
    
    static func createNetworkPlayer(from networkPlayer: NetworkPlayer) -> Player {
        let player = Player(
            id: networkPlayer.id,
            name: networkPlayer.name,
            playerType: networkPlayer.playerType,
            isLocal: false
        )
        
        player.score = networkPlayer.score
        player.lives = networkPlayer.lives
        player.isReady = networkPlayer.isReady
        
        return player
    }
    
    static func createTestPlayers(count: Int) -> [Player] {
        return (1...count).map { index in
            Player(
                id: "test_player_\(index)",
                name: "Test Player \(index)",
                playerType: index == 1 ? .mapMover : .regular,
                isLocal: index == 1
            )
        }
    }
}
