//
//  PowerUp.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - PowerUp Model
struct PowerUp: Codable, Identifiable {
    
    let id: String
    let type: PowerUpType
    let position: CGPoint
    let size: CGSize
    let duration: TimeInterval
    let effectStrength: CGFloat
    let rarity: PowerUpRarity
    
    // Visual Properties
    let animationType: PowerUpAnimation
    let glowEffect: Bool
    let particleEffect: String?
    
    // Collection Properties
    var isCollected: Bool
    var collectedBy: String?
    var collectedAt: Date?
    var respawnTimer: TimeInterval?
    
    // Spawn Properties
    let canRespawn: Bool
    let respawnDelay: TimeInterval
    let maxCollections: Int
    var collectionCount: Int
    
    // MARK: - Initialization
    init(
        id: String = UUID().uuidString,
        type: PowerUpType,
        position: CGPoint,
        size: CGSize = CGSize(width: 32, height: 32),
        duration: TimeInterval = Constants.powerUpDuration,
        effectStrength: CGFloat = 1.0,
        rarity: PowerUpRarity = .common,
        animationType: PowerUpAnimation = .float,
        glowEffect: Bool = true,
        particleEffect: String? = nil,
        canRespawn: Bool = true,
        respawnDelay: TimeInterval = Constants.powerUpRespawnDelay,
        maxCollections: Int = -1
    ) {
        self.id = id
        self.type = type
        self.position = position
        self.size = size
        self.duration = duration
        self.effectStrength = effectStrength
        self.rarity = rarity
        self.animationType = animationType
        self.glowEffect = glowEffect
        self.particleEffect = particleEffect
        self.isCollected = false
        self.collectedBy = nil
        self.collectedAt = nil
        self.respawnTimer = nil
        self.canRespawn = canRespawn
        self.respawnDelay = respawnDelay
        self.maxCollections = maxCollections
        self.collectionCount = 0
    }
    
    // MARK: - Collection Methods
    mutating func collect(by playerId: String) -> PowerUpCollectionResult {
        guard !isCollected else {
            return PowerUpCollectionResult(
                success: false,
                message: "Power-up already collected",
                effect: nil
            )
        }
        
        guard maxCollections == -1 || collectionCount < maxCollections else {
            return PowerUpCollectionResult(
                success: false,
                message: "Power-up exhausted",
                effect: nil
            )
        }
        
        // Mark as collected
        isCollected = true
        collectedBy = playerId
        collectedAt = Date()
        collectionCount += 1
        
        // Set respawn timer if applicable
        if canRespawn && (maxCollections == -1 || collectionCount < maxCollections) {
            respawnTimer = respawnDelay
        }
        
        // Create effect
        let effect = PowerUpEffect(
            type: type,
            duration: duration,
            strength: effectStrength,
            playerId: playerId,
            powerUpId: id
        )
        
        return PowerUpCollectionResult(
            success: true,
            message: type.collectionMessage,
            effect: effect
        )
    }
    
    mutating func updateRespawnTimer(deltaTime: TimeInterval) {
        guard let timer = respawnTimer else { return }
        
        let newTimer = timer - deltaTime
        
        if newTimer <= 0 {
            // Respawn the power-up
            respawn()
        } else {
            respawnTimer = newTimer
        }
    }
    
    mutating func respawn() {
        isCollected = false
        collectedBy = nil
        collectedAt = nil
        respawnTimer = nil
    }
    
    mutating func reset() {
        isCollected = false
        collectedBy = nil
        collectedAt = nil
        respawnTimer = nil
        collectionCount = 0
    }
    
    // MARK: - Query Methods
    func canBeCollectedBy(_ playerId: String) -> Bool {
        return !isCollected
    }
    
    func isInRange(of playerPosition: CGPoint, radius: CGFloat = 40) -> Bool {
        return position.distance(to: playerPosition) <= radius
    }
    
    func getTimeUntilRespawn() -> TimeInterval? {
        return respawnTimer
    }
    
    func getRespawnProgress() -> Double {
        guard let timer = respawnTimer else { return 0.0 }
        return 1.0 - (timer / respawnDelay)
    }
    
    // MARK: - Visual Properties
    var spriteName: String {
        let baseName = type.spriteName
        let raritySuffix = rarity.spriteSuffix
        return "\(baseName)\(raritySuffix)"
    }
    
    var effectColor: String {
        return type.effectColor
    }
    
    var glowColor: String {
        return rarity.glowColor
    }
    
    var animationSpeed: TimeInterval {
        switch animationType {
        case .float: return 2.0
        case .spin: return 1.5
        case .pulse: return 1.0
        case .bounce: return 0.8
        case .none: return 0.0
        }
    }
    
    var isVisible: Bool {
        return !isCollected || (respawnTimer != nil && getRespawnProgress() > 0.8)
    }
    
    var alpha: CGFloat {
        if isCollected {
            if let timer = respawnTimer {
                let progress = getRespawnProgress()
                return progress > 0.8 ? CGFloat(progress - 0.8) * 5 : 0
            }
            return 0
        }
        return 1.0
    }
    
    // MARK: - Status Properties
    var statusDescription: String {
        if isCollected {
            if let timer = respawnTimer {
                return "Respawning in \(Int(timer))s"
            } else {
                return "Collected"
            }
        } else {
            return "Available"
        }
    }
    
    var scoreValue: Int {
        return type.scoreValue * rarity.scoreMultiplier
    }
    
    var timeSinceCollection: TimeInterval? {
        guard let collectedAt = collectedAt else { return nil }
        return Date().timeIntervalSince(collectedAt)
    }
}

// MARK: - PowerUp Types (Extended)
extension PowerUpType {
    static let oil = PowerUpType(rawValue: "oil")!
    static let grass = PowerUpType(rawValue: "grass")!
    static let shield = PowerUpType(rawValue: "shield")!
    static let magnet = PowerUpType(rawValue: "magnet")!
    static let teleport = PowerUpType(rawValue: "teleport")!
    static let ghost = PowerUpType(rawValue: "ghost")!
    static let time = PowerUpType(rawValue: "time")!
    
    var spriteName: String {
        return "powerup_\(rawValue)"
    }
    
    var displayName: String {
        switch self {
        case .oil: return "Speed Boost"
        case .grass: return "Slow Motion"
        case .shield: return "Shield"
        case .magnet: return "Magnet"
        case .teleport: return "Teleport"
        case .ghost: return "Ghost Mode"
        case .time: return "Time Stop"
        default: return rawValue.capitalized
        }
    }
    
    var description: String {
        switch self {
        case .oil: return "Increases movement speed"
        case .grass: return "Slows down movement for precise control"
        case .shield: return "Protects from vortex damage"
        case .magnet: return "Attracts nearby checkpoints"
        case .teleport: return "Instantly move to last checkpoint"
        case .ghost: return "Pass through walls temporarily"
        case .time: return "Freezes time for strategic planning"
        default: return "Unknown power-up effect"
        }
    }
    
    var effectColor: String {
        switch self {
        case .oil: return "#FFD700"      // Gold
        case .grass: return "#32CD32"    // Lime Green
        case .shield: return "#4169E1"   // Royal Blue
        case .magnet: return "#FF1493"   // Deep Pink
        case .teleport: return "#9370DB" // Medium Purple
        case .ghost: return "#F0F8FF"    // Alice Blue
        case .time: return "#FF4500"     // Orange Red
        default: return "#FFFFFF"
        }
    }
    
    var collectionMessage: String {
        switch self {
        case .oil: return "Speed boost activated!"
        case .grass: return "Slow motion enabled!"
        case .shield: return "Shield up!"
        case .magnet: return "Magnetic field active!"
        case .teleport: return "Teleporter ready!"
        case .ghost: return "Ghost mode engaged!"
        case .time: return "Time frozen!"
        default: return "Power-up collected!"
        }
    }
    
    var scoreValue: Int {
        switch self {
        case .oil, .grass: return 5
        case .shield: return 10
        case .magnet: return 8
        case .teleport: return 15
        case .ghost: return 20
        case .time: return 25
        default: return 5
        }
    }
    
    var defaultDuration: TimeInterval {
        switch self {
        case .oil, .grass: return 5.0
        case .shield: return 8.0
        case .magnet: return 6.0
        case .teleport: return 0.0    // Instant effect
        case .ghost: return 3.0
        case .time: return 2.0
        default: return 5.0
        }
    }
    
    var rarity: PowerUpRarity {
        switch self {
        case .oil, .grass: return .common
        case .shield, .magnet: return .uncommon
        case .teleport: return .rare
        case .ghost, .time: return .legendary
        default: return .common
        }
    }
}

// MARK: - PowerUp Rarity
enum PowerUpRarity: String, CaseIterable, Codable {
    case common = "common"
    case uncommon = "uncommon"
    case rare = "rare"
    case epic = "epic"
    case legendary = "legendary"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var spawnChance: Double {
        switch self {
        case .common: return 0.6      // 60%
        case .uncommon: return 0.25   // 25%
        case .rare: return 0.1        // 10%
        case .epic: return 0.04       // 4%
        case .legendary: return 0.01  // 1%
        }
    }
    
    var scoreMultiplier: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 2
        case .rare: return 3
        case .epic: return 5
        case .legendary: return 10
        }
    }
    
    var glowColor: String {
        switch self {
        case .common: return "#FFFFFF"      // White
        case .uncommon: return "#00FF00"    // Green
        case .rare: return "#0080FF"        // Blue
        case .epic: return "#8000FF"        // Purple
        case .legendary: return "#FF8000"   // Orange
        }
    }
    
    var spriteSuffix: String {
        switch self {
        case .common: return ""
        case .uncommon: return "_green"
        case .rare: return "_blue"
        case .epic: return "_purple"
        case .legendary: return "_gold"
        }
    }
    
    var particleEffect: String {
        switch self {
        case .common: return "sparkle_white"
        case .uncommon: return "sparkle_green"
        case .rare: return "sparkle_blue"
        case .epic: return "sparkle_purple"
        case .legendary: return "sparkle_gold"
        }
    }
}

// MARK: - PowerUp Animation
enum PowerUpAnimation: String, CaseIterable, Codable {
    case float = "float"
    case spin = "spin"
    case pulse = "pulse"
    case bounce = "bounce"
    case none = "none"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - PowerUp Effect
struct PowerUpEffect: Codable, Identifiable {
    let id = UUID()
    let type: PowerUpType
    let duration: TimeInterval
    let strength: CGFloat
    let playerId: String
    let powerUpId: String
    let activatedAt: Date
    
    init(type: PowerUpType, duration: TimeInterval, strength: CGFloat, playerId: String, powerUpId: String) {
        self.type = type
        self.duration = duration
        self.strength = strength
        self.playerId = playerId
        self.powerUpId = powerUpId
        self.activatedAt = Date()
    }
    
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
    
    var isActive: Bool {
        return !isExpired
    }
    
    var effectMultiplier: CGFloat {
        switch type {
        case .oil: return Constants.oilSpeedMultiplier * strength
        case .grass: return Constants.grassSpeedMultiplier * strength
        case .shield: return 1.0 // Boolean effect
        case .magnet: return 2.0 * strength
        case .ghost: return 1.0 // Boolean effect
        case .time: return 0.1 * strength // Time scale
        default: return strength
        }
    }
}

// MARK: - PowerUp Collection Result
struct PowerUpCollectionResult {
    let success: Bool
    let message: String
    let effect: PowerUpEffect?
    
    var shouldPlaySound: Bool {
        return success
    }
    
    var shouldShowParticles: Bool {
        return success && effect != nil
    }
}

// MARK: - PowerUp Factory
struct PowerUpFactory {
    
    static func createOilPowerUp(at position: CGPoint) -> PowerUp {
        return PowerUp(
            type: .oil,
            position: position,
            duration: PowerUpType.oil.defaultDuration,
            rarity: .common,
            animationType: .float,
            particleEffect: "oil_splash"
        )
    }
    
    static func createGrassPowerUp(at position: CGPoint) -> PowerUp {
        return PowerUp(
            type: .grass,
            position: position,
            duration: PowerUpType.grass.defaultDuration,
            rarity: .common,
            animationType: .bounce,
            particleEffect: "grass_leaves"
        )
    }
    
    static func createShieldPowerUp(at position: CGPoint) -> PowerUp {
        return PowerUp(
            type: .shield,
            position: position,
            duration: PowerUpType.shield.defaultDuration,
            rarity: .uncommon,
            animationType: .pulse,
            particleEffect: "shield_energy"
        )
    }
    
    static func createRandomPowerUp(at position: CGPoint, allowedTypes: [PowerUpType]? = nil) -> PowerUp {
        let types = allowedTypes ?? [.oil, .grass, .shield, .magnet]
        let randomType = types.randomElement()!
        
        // Determine rarity based on spawn chance
        let rarity = determineRarity()
        
        return PowerUp(
            type: randomType,
            position: position,
            duration: randomType.defaultDuration,
            rarity: rarity,
            animationType: .float,
            particleEffect: rarity.particleEffect
        )
    }
    
    static func createPowerUpsFromLevelData(_ levelData: String, cellSize: CGFloat) -> [PowerUp] {
        var powerUps: [PowerUp] = []
        let lines = levelData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, character) in line.enumerated() {
                let position = CGPoint(
                    x: (cellSize * CGFloat(column)) + (cellSize/2),
                    y: (cellSize * CGFloat(row)) + (cellSize/2)
                )
                
                switch character {
                case "o":
                    powerUps.append(createOilPowerUp(at: position))
                case "g":
                    powerUps.append(createGrassPowerUp(at: position))
                default:
                    break
                }
            }
        }
        
        return powerUps
    }
    
    private static func determineRarity() -> PowerUpRarity {
        let random = Double.random(in: 0...1)
        var cumulativeChance: Double = 0
        
        for rarity in PowerUpRarity.allCases.reversed() {
            cumulativeChance += rarity.spawnChance
            if random <= cumulativeChance {
                return rarity
            }
        }
        
        return .common
    }
}

// MARK: - PowerUp Extensions
extension PowerUp {
    
    // MARK: - Equatable
    static func == (lhs: PowerUp, rhs: PowerUp) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Comparable (by rarity, then by type)
    static func < (lhs: PowerUp, rhs: PowerUp) -> Bool {
        if lhs.rarity.scoreMultiplier != rhs.rarity.scoreMultiplier {
            return lhs.rarity.scoreMultiplier < rhs.rarity.scoreMultiplier
        }
        return lhs.type.scoreValue < rhs.type.scoreValue
    }
}

// MARK: - Array Extensions
extension Array where Element == PowerUp {
    
    func available() -> [PowerUp] {
        return filter { !$0.isCollected }
    }
    
    func collected() -> [PowerUp] {
        return filter { $0.isCollected }
    }
    
    func respawning() -> [PowerUp] {
        return filter { $0.respawnTimer != nil }
    }
    
    func inRange(of position: CGPoint, radius: CGFloat = 40) -> [PowerUp] {
        return filter { $0.isInRange(of: position, radius: radius) }
    }
    
    func ofType(_ type: PowerUpType) -> [PowerUp] {
        return filter { $0.type == type }
    }
    
    func ofRarity(_ rarity: PowerUpRarity) -> [PowerUp] {
        return filter { $0.rarity == rarity }
    }
    
    mutating func updateRespawnTimers(deltaTime: TimeInterval) {
        for i in indices {
            self[i].updateRespawnTimer(deltaTime: deltaTime)
        }
    }
    
    mutating func resetAll() {
        for i in indices {
            self[i].reset()
        }
    }
    
    func getTotalScore() -> Int {
        return collected().reduce(0) { $0 + $1.scoreValue }
    }
    
    func getCollectionStats() -> (total: Int, collected: Int, available: Int) {
        return (
            total: count,
            collected: collected().count,
            available: available().count
        )
    }
}
