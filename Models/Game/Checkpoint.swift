//
//  Checkpoint.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Checkpoint Model
struct Checkpoint: Codable, Identifiable {
    
    let id: String
    let position: CGPoint
    let type: CheckpointType
    let isRequired: Bool
    let scoreReward: Int
    let activationRadius: CGFloat
    let sequence: Int
    
    // Visual Properties
    let size: CGSize
    let color: CheckpointColor
    let animationType: CheckpointAnimation
    
    // State Properties
    var isActivated: Bool
    var activatedBy: [String]
    var activatedAt: Date?
    var completionRequirement: CompletionRequirement
    
    // MARK: - Initialization
    init(
        id: String,
        position: CGPoint,
        type: CheckpointType = .standard,
        isRequired: Bool = true,
        scoreReward: Int = Constants.checkpointScore,
        activationRadius: CGFloat = 40,
        sequence: Int = 0,
        size: CGSize = CGSize(width: 48, height: 48),
        color: CheckpointColor = .blue,
        animationType: CheckpointAnimation = .pulse,
        completionRequirement: CompletionRequirement = .anyPlayer
    ) {
        self.id = id
        self.position = position
        self.type = type
        self.isRequired = isRequired
        self.scoreReward = scoreReward
        self.activationRadius = activationRadius
        self.sequence = sequence
        self.size = size
        self.color = color
        self.animationType = animationType
        self.isActivated = false
        self.activatedBy = []
        self.activatedAt = nil
        self.completionRequirement = completionRequirement
    }
    
    // MARK: - Activation Methods
    mutating func activate(by playerId: String) -> CheckpointActivationResult {
        // Check if already activated by this player
        if activatedBy.contains(playerId) {
            return CheckpointActivationResult(
                success: false,
                message: "Already activated by this player",
                scoreAwarded: 0,
                isFirstActivation: false
            )
        }
        
        // Add player to activated list
        activatedBy.append(playerId)
        
        let isFirstActivation = !isActivated
        
        // Check completion requirement
        let shouldMarkAsActivated = checkCompletionRequirement()
        
        if shouldMarkAsActivated && !isActivated {
            isActivated = true
            activatedAt = Date()
        }
        
        // Calculate score reward
        let score = calculateScoreReward(isFirstActivation: isFirstActivation)
        
        return CheckpointActivationResult(
            success: true,
            message: isFirstActivation ? "Checkpoint activated!" : "Checkpoint progress updated",
            scoreAwarded: score,
            isFirstActivation: isFirstActivation
        )
    }
    
    mutating func reset() {
        isActivated = false
        activatedBy.removeAll()
        activatedAt = nil
    }
    
    private func checkCompletionRequirement() -> Bool {
        switch completionRequirement {
        case .anyPlayer:
            return !activatedBy.isEmpty
            
        case .allPlayers(let requiredCount):
            return activatedBy.count >= requiredCount
            
        case .specificPlayer(let playerId):
            return activatedBy.contains(playerId)
            
        case .majority(let totalPlayers):
            let majorityCount = (totalPlayers / 2) + 1
            return activatedBy.count >= majorityCount
            
        case .teamwork(let requiredCount):
            return activatedBy.count >= requiredCount
        }
    }
    
    private func calculateScoreReward(isFirstActivation: Bool) -> Int {
        var reward = scoreReward
        
        // Bonus for first activation
        if isFirstActivation {
            reward = Int(Double(reward) * 1.5)
        }
        
        // Type modifiers
        switch type {
        case .standard:
            break
        case .bonus:
            reward *= 2
        case .secret:
            reward *= 3
        case .critical:
            reward = Int(Double(reward) * 2.5)
        case .team:
            reward = Int(Double(reward) * Double(activatedBy.count))
        }
        
        return reward
    }
    
    // MARK: - Query Methods
    func canBeActivatedBy(_ playerId: String) -> Bool {
        return !activatedBy.contains(playerId)
    }
    
    func isActivatedBy(_ playerId: String) -> Bool {
        return activatedBy.contains(playerId)
    }
    
    func getActivationProgress(totalPlayers: Int) -> Double {
        switch completionRequirement {
        case .anyPlayer:
            return activatedBy.isEmpty ? 0.0 : 1.0
            
        case .allPlayers(let requiredCount):
            return Double(activatedBy.count) / Double(requiredCount)
            
        case .specificPlayer:
            return isActivated ? 1.0 : 0.0
            
        case .majority(let totalPlayers):
            let majorityCount = (totalPlayers / 2) + 1
            return Double(activatedBy.count) / Double(majorityCount)
            
        case .teamwork(let requiredCount):
            return Double(activatedBy.count) / Double(requiredCount)
        }
    }
    
    func getDistanceTo(_ position: CGPoint) -> CGFloat {
        return self.position.distance(to: position)
    }
    
    func isPlayerInRange(_ playerPosition: CGPoint) -> Bool {
        return getDistanceTo(playerPosition) <= activationRadius
    }
    
    // MARK: - Visual Properties
    var spriteName: String {
        let baseSprite = type.spriteName
        let colorSuffix = color.suffix
        return "\(baseSprite)_\(colorSuffix)"
    }
    
    var glowColor: String {
        return isActivated ? color.activatedGlow : color.inactiveGlow
    }
    
    var animationScale: ClosedRange<CGFloat> {
        switch animationType {
        case .pulse:
            return 0.9...1.1
        case .bounce:
            return 0.8...1.2
        case .rotate:
            return 1.0...1.0
        case .glow:
            return 0.95...1.05
        case .none:
            return 1.0...1.0
        }
    }
    
    var animationDuration: TimeInterval {
        switch animationType {
        case .pulse: return 1.0
        case .bounce: return 0.6
        case .rotate: return 2.0
        case .glow: return 1.5
        case .none: return 0.0
        }
    }
    
    // MARK: - Status Properties
    var statusDescription: String {
        if isActivated {
            return "Activated by \(activatedBy.count) player(s)"
        } else {
            return "Progress: \(activatedBy.count)/\(completionRequirement.requiredCount)"
        }
    }
    
    var completionPercentage: Double {
        return getActivationProgress(totalPlayers: 8) // Max players
    }
    
    var isPartiallyCompleted: Bool {
        return !activatedBy.isEmpty && !isActivated
    }
    
    var timeSinceActivation: TimeInterval? {
        guard let activatedAt = activatedAt else { return nil }
        return Date().timeIntervalSince(activatedAt)
    }
}

// MARK: - Checkpoint Types
enum CheckpointType: String, CaseIterable, Codable {
    case standard = "standard"
    case bonus = "bonus"
    case secret = "secret"
    case critical = "critical"
    case team = "team"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var spriteName: String {
        return "checkpoint_\(rawValue)"
    }
    
    var description: String {
        switch self {
        case .standard:
            return "Regular checkpoint that saves progress"
        case .bonus:
            return "Bonus checkpoint with extra points"
        case .secret:
            return "Hidden checkpoint with high rewards"
        case .critical:
            return "Must be activated to complete level"
        case .team:
            return "Requires multiple players to activate"
        }
    }
    
    var priority: Int {
        switch self {
        case .critical: return 5
        case .standard: return 3
        case .team: return 4
        case .bonus: return 2
        case .secret: return 1
        }
    }
}

// MARK: - Checkpoint Colors
enum CheckpointColor: String, CaseIterable, Codable {
    case blue = "blue"
    case green = "green"
    case yellow = "yellow"
    case orange = "orange"
    case purple = "purple"
    case red = "red"
    
    var suffix: String {
        return rawValue
    }
    
    var activatedGlow: String {
        return "\(rawValue)_bright"
    }
    
    var inactiveGlow: String {
        return "\(rawValue)_dim"
    }
    
    var hexColor: String {
        switch self {
        case .blue: return "#007AFF"
        case .green: return "#34C759"
        case .yellow: return "#FFCC00"
        case .orange: return "#FF9500"
        case .purple: return "#AF52DE"
        case .red: return "#FF3B30"
        }
    }
}

// MARK: - Checkpoint Animations
enum CheckpointAnimation: String, CaseIterable, Codable {
    case pulse = "pulse"
    case bounce = "bounce"
    case rotate = "rotate"
    case glow = "glow"
    case none = "none"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

// MARK: - Completion Requirements
enum CompletionRequirement: Codable {
    case anyPlayer
    case allPlayers(count: Int)
    case specificPlayer(id: String)
    case majority(totalPlayers: Int)
    case teamwork(requiredCount: Int)
    
    var requiredCount: Int {
        switch self {
        case .anyPlayer:
            return 1
        case .allPlayers(let count):
            return count
        case .specificPlayer:
            return 1
        case .majority(let totalPlayers):
            return (totalPlayers / 2) + 1
        case .teamwork(let requiredCount):
            return requiredCount
        }
    }
    
    var description: String {
        switch self {
        case .anyPlayer:
            return "Any player can activate"
        case .allPlayers(let count):
            return "Requires \(count) players"
        case .specificPlayer(let id):
            return "Requires specific player: \(id)"
        case .majority(let totalPlayers):
            return "Requires majority of \(totalPlayers) players"
        case .teamwork(let requiredCount):
            return "Requires \(requiredCount) players working together"
        }
    }
}

// MARK: - Checkpoint Activation Result
struct CheckpointActivationResult {
    let success: Bool
    let message: String
    let scoreAwarded: Int
    let isFirstActivation: Bool
    
    var shouldPlaySound: Bool {
        return success && scoreAwarded > 0
    }
    
    var shouldShowEffect: Bool {
        return success && isFirstActivation
    }
}

// MARK: - Checkpoint Factory
struct CheckpointFactory {
    
    static func createStandardCheckpoint(id: String, position: CGPoint, sequence: Int = 0) -> Checkpoint {
        return Checkpoint(
            id: id,
            position: position,
            type: .standard,
            sequence: sequence,
            color: .blue
        )
    }
    
    static func createBonusCheckpoint(id: String, position: CGPoint) -> Checkpoint {
        return Checkpoint(
            id: id,
            position: position,
            type: .bonus,
            scoreReward: Constants.checkpointScore * 2,
            color: .yellow,
            animationType: .bounce
        )
    }
    
    static func createSecretCheckpoint(id: String, position: CGPoint) -> Checkpoint {
        return Checkpoint(
            id: id,
            position: position,
            type: .secret,
            scoreReward: Constants.checkpointScore * 3,
            activationRadius: 30,
            size: CGSize(width: 32, height: 32),
            color: .purple,
            animationType: .glow
        )
    }
    
    static func createTeamCheckpoint(id: String, position: CGPoint, requiredPlayers: Int) -> Checkpoint {
        return Checkpoint(
            id: id,
            position: position,
            type: .team,
            scoreReward: Constants.checkpointScore * requiredPlayers,
            activationRadius: 60,
            size: CGSize(width: 64, height: 64),
            color: .green,
            animationType: .pulse,
            completionRequirement: .teamwork(requiredCount: requiredPlayers)
        )
    }
    
    static func createCriticalCheckpoint(id: String, position: CGPoint) -> Checkpoint {
        return Checkpoint(
            id: id,
            position: position,
            type: .critical,
            isRequired: true,
            scoreReward: Constants.checkpointScore * 2,
            color: .red,
            animationType: .rotate
        )
    }
    
    static func createCheckpointsFromLevelData(_ levelData: String, cellSize: CGFloat) -> [Checkpoint] {
        var checkpoints: [Checkpoint] = []
        let lines = levelData.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        var checkpointIndex = 0
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, character) in line.enumerated() {
                if character == "s" {
                    let position = CGPoint(
                        x: (cellSize * CGFloat(column)) + (cellSize/2),
                        y: (cellSize * CGFloat(row)) + (cellSize/2)
                    )
                    
                    let checkpointId = "checkpoint_\(row)_\(column)"
                    let checkpoint = createStandardCheckpoint(
                        id: checkpointId,
                        position: position,
                        sequence: checkpointIndex
                    )
                    
                    checkpoints.append(checkpoint)
                    checkpointIndex += 1
                }
            }
        }
        
        return checkpoints
    }
}

// MARK: - Checkpoint Extensions
extension Checkpoint {
    
    // MARK: - Equatable
    static func == (lhs: Checkpoint, rhs: Checkpoint) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Comparable (by sequence)
    static func < (lhs: Checkpoint, rhs: Checkpoint) -> Bool {
        return lhs.sequence < rhs.sequence
    }
}

// MARK: - Array Extensions
extension Array where Element == Checkpoint {
    
    func sortedBySequence() -> [Checkpoint] {
        return sorted { $0.sequence < $1.sequence }
    }
    
    func activated() -> [Checkpoint] {
        return filter { $0.isActivated }
    }
    
    func pending() -> [Checkpoint] {
        return filter { !$0.isActivated }
    }
    
    func required() -> [Checkpoint] {
        return filter { $0.isRequired }
    }
    
    func nearest(to position: CGPoint) -> Checkpoint? {
        return self.min { checkpoint1, checkpoint2 in
            checkpoint1.getDistanceTo(position) < checkpoint2.getDistanceTo(position)
        }
    }
    
    func inRadius(of position: CGPoint, radius: CGFloat) -> [Checkpoint] {
        return filter { $0.getDistanceTo(position) <= radius }
    }
    
    func getOverallProgress() -> Double {
        guard !isEmpty else { return 0.0 }
        let activatedCount = activated().count
        return Double(activatedCount) / Double(count)
    }
    
    func getTotalScore() -> Int {
        return activated().reduce(0) { $0 + $1.scoreReward }
    }
}
