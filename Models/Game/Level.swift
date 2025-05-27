//
//  Level.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Level Model
struct Level: Codable, Identifiable {
    
    let id = UUID()
    let number: Int
    let name: String
    let size: CGSize
    let cellSize: CGFloat
    let difficulty: LevelDifficulty
    
    // Level Elements
    let walls: [Wall]
    let checkpoints: [Checkpoint]
    let vortexes: [Vortex]
    let powerUps: [PowerUp]
    let finishPoint: FinishPoint
    let playerStartPositions: [CGPoint]
    
    // Level Metadata
    let timeLimit: TimeInterval?
    let requiredCheckpoints: Int
    let backgroundMusic: String?
    let theme: LevelTheme
    let createdAt: Date
    
    // MARK: - Initialization
    init(
        number: Int = 1,
        name: String = "",
        size: CGSize,
        cellSize: CGFloat = Constants.defaultCellSize,
        difficulty: LevelDifficulty = .normal,
        walls: [Wall] = [],
        checkpoints: [Checkpoint] = [],
        vortexes: [Vortex] = [],
        powerUps: [PowerUp] = [],
        finishPoint: FinishPoint,
        playerStartPositions: [CGPoint] = [],
        timeLimit: TimeInterval? = nil,
        requiredCheckpoints: Int? = nil,
        backgroundMusic: String? = nil,
        theme: LevelTheme = .space
    ) {
        self.number = number
        self.name = name.isEmpty ? "Level \(number)" : name
        self.size = size
        self.cellSize = cellSize
        self.difficulty = difficulty
        self.walls = walls
        self.checkpoints = checkpoints
        self.vortexes = vortexes
        self.powerUps = powerUps
        self.finishPoint = finishPoint
        self.playerStartPositions = playerStartPositions
        self.timeLimit = timeLimit
        self.requiredCheckpoints = requiredCheckpoints ?? checkpoints.count
        self.backgroundMusic = backgroundMusic
        self.theme = theme
        self.createdAt = Date()
    }
    
    // MARK: - Level Properties
    var gridWidth: Int {
        return Int(size.width / cellSize)
    }
    
    var gridHeight: Int {
        return Int(size.height / cellSize)
    }
    
    var totalElements: Int {
        return walls.count + checkpoints.count + vortexes.count + powerUps.count + 1
    }
    
    var hasTimeLimit: Bool {
        return timeLimit != nil
    }
    
    var estimatedDifficulty: Double {
        let vortexRatio = Double(vortexes.count) / Double(totalElements)
        let wallRatio = Double(walls.count) / Double(totalElements)
        let checkpointRatio = Double(checkpoints.count) / Double(totalElements)
        
        return (vortexRatio * 3.0) + (wallRatio * 1.5) - (checkpointRatio * 0.5)
    }
    
    var recommendedPlayerCount: ClosedRange<Int> {
        switch difficulty {
        case .easy: return 2...4
        case .normal: return 2...6
        case .hard: return 3...8
        case .expert: return 4...8
        }
    }
    
    // MARK: - Level Validation
    func validate() -> LevelValidationResult {
        var errors: [String] = []
        var warnings: [String] = []
        
        // Check minimum size
        if gridWidth < 5 || gridHeight < 5 {
            errors.append("Level must be at least 5x5 cells")
        }
        
        // Check if finish point exists
        if finishPoint.position == .zero {
            errors.append("Level must have a finish point")
        }
        
        // Check if there are enough checkpoints
        if checkpoints.count < 2 {
            warnings.append("Level should have at least 2 checkpoints")
        }
        
        // Check if level is completely surrounded by walls
        let borderWalls = walls.filter { wall in
            wall.position.x <= cellSize/2 ||
            wall.position.x >= size.width - cellSize/2 ||
            wall.position.y <= cellSize/2 ||
            wall.position.y >= size.height - cellSize/2
        }
        
        if borderWalls.count < Int((gridWidth + gridHeight) * 2 - 4) {
            warnings.append("Level should be completely surrounded by walls")
        }
        
        // Check player start positions
        if playerStartPositions.isEmpty {
            warnings.append("No player start positions defined, using default")
        }
        
        // Check for overlapping elements
        let allPositions = walls.map { $0.position } +
                          checkpoints.map { $0.position } +
                          vortexes.map { $0.position } +
                          powerUps.map { $0.position } +
                          [finishPoint.position]
        
        let uniquePositions = Set(allPositions.map { "\($0.x),\($0.y)" })
        if uniquePositions.count != allPositions.count {
            warnings.append("Some elements may be overlapping")
        }
        
        return LevelValidationResult(
            isValid: errors.isEmpty,
            errors: errors,
            warnings: warnings
        )
    }
    
    // MARK: - Level Analysis
    func getPathComplexity() -> PathComplexity {
        let totalCells = gridWidth * gridHeight
        let obstacleRatio = Double(walls.count + vortexes.count) / Double(totalCells)
        
        switch obstacleRatio {
        case 0.0..<0.2: return .simple
        case 0.2..<0.4: return .moderate
        case 0.4..<0.6: return .complex
        default: return .veryComplex
        }
    }
    
    func getHazardLevel() -> HazardLevel {
        let hazardRatio = Double(vortexes.count) / Double(totalElements)
        
        switch hazardRatio {
        case 0.0..<0.1: return .low
        case 0.1..<0.25: return .medium
        case 0.25..<0.4: return .high
        default: return .extreme
        }
    }
    
    func getRecommendedTime() -> TimeInterval {
        let baseTime: TimeInterval = 60 // 1 minute base
        let difficultyMultiplier = difficulty.timeMultiplier
        let complexityMultiplier = getPathComplexity().timeMultiplier
        
        return baseTime * difficultyMultiplier * complexityMultiplier
    }
    
    // MARK: - Element Queries
    func getElementAt(position: CGPoint, tolerance: CGFloat = 5.0) -> LevelElement? {
        // Check walls
        if let wall = walls.first(where: { $0.position.distance(to: position) <= tolerance }) {
            return .wall(wall)
        }
        
        // Check checkpoints
        if let checkpoint = checkpoints.first(where: { $0.position.distance(to: position) <= tolerance }) {
            return .checkpoint(checkpoint)
        }
        
        // Check vortexes
        if let vortex = vortexes.first(where: { $0.position.distance(to: position) <= tolerance }) {
            return .vortex(vortex)
        }
        
        // Check power-ups
        if let powerUp = powerUps.first(where: { $0.position.distance(to: position) <= tolerance }) {
            return .powerUp(powerUp)
        }
        
        // Check finish point
        if finishPoint.position.distance(to: position) <= tolerance {
            return .finish(finishPoint)
        }
        
        return nil
    }
    
    func getElementsInRect(_ rect: CGRect) -> [LevelElement] {
        var elements: [LevelElement] = []
        
        // Add walls in rect
        elements.append(contentsOf: walls.filter { rect.contains($0.position) }.map { .wall($0) })
        
        // Add checkpoints in rect
        elements.append(contentsOf: checkpoints.filter { rect.contains($0.position) }.map { .checkpoint($0) })
        
        // Add vortexes in rect
        elements.append(contentsOf: vortexes.filter { rect.contains($0.position) }.map { .vortex($0) })
        
        // Add power-ups in rect
        elements.append(contentsOf: powerUps.filter { rect.contains($0.position) }.map { .powerUp($0) })
        
        // Add finish point if in rect
        if rect.contains(finishPoint.position) {
            elements.append(.finish(finishPoint))
        }
        
        return elements
    }
    
    func getNearestCheckpoint(to position: CGPoint) -> Checkpoint? {
        return checkpoints.min { checkpoint1, checkpoint2 in
            checkpoint1.position.distance(to: position) < checkpoint2.position.distance(to: position)
        }
    }
    
    func getPlayerStartPosition(for playerIndex: Int) -> CGPoint {
        if playerIndex < playerStartPositions.count {
            return playerStartPositions[playerIndex]
        } else {
            // Generate position around first start position
            let basePosition = playerStartPositions.first ?? CGPoint(x: cellSize * 2, y: cellSize * 2)
            let angle = (Double.pi * 2 / 8) * Double(playerIndex)
            let radius: CGFloat = cellSize * 1.5
            
            return CGPoint(
                x: basePosition.x + cos(angle) * radius,
                y: basePosition.y + sin(angle) * radius
            )
        }
    }
    
    // MARK: - Level Statistics
    func getStatistics() -> LevelStatistics {
        return LevelStatistics(
            level: self,
            totalElements: totalElements,
            pathComplexity: getPathComplexity(),
            hazardLevel: getHazardLevel(),
            estimatedPlayTime: getRecommendedTime(),
            recommendedPlayers: recommendedPlayerCount
        )
    }
}

// MARK: - Supporting Types
enum LevelDifficulty: String, CaseIterable, Codable {
    case easy = "easy"
    case normal = "normal"
    case hard = "hard"
    case expert = "expert"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var timeMultiplier: Double {
        switch self {
        case .easy: return 1.5
        case .normal: return 1.0
        case .hard: return 0.8
        case .expert: return 0.6
        }
    }
    
    var scoreMultiplier: Double {
        switch self {
        case .easy: return 0.8
        case .normal: return 1.0
        case .hard: return 1.5
        case .expert: return 2.0
        }
    }
}

enum LevelTheme: String, CaseIterable, Codable {
    case space = "space"
    case forest = "forest"
    case ocean = "ocean"
    case desert = "desert"
    case ice = "ice"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var backgroundColor: String {
        switch self {
        case .space: return "SpaceBackground"
        case .forest: return "ForestBackground"
        case .ocean: return "OceanBackground"
        case .desert: return "DesertBackground"
        case .ice: return "IceBackground"
        }
    }
}

enum PathComplexity: CaseIterable {
    case simple, moderate, complex, veryComplex
    
    var displayName: String {
        switch self {
        case .simple: return "Simple"
        case .moderate: return "Moderate"
        case .complex: return "Complex"
        case .veryComplex: return "Very Complex"
        }
    }
    
    var timeMultiplier: Double {
        switch self {
        case .simple: return 0.8
        case .moderate: return 1.0
        case .complex: return 1.3
        case .veryComplex: return 1.6
        }
    }
}

enum HazardLevel: CaseIterable {
    case low, medium, high, extreme
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .extreme: return "Extreme"
        }
    }
}

enum LevelElement {
    case wall(Wall)
    case checkpoint(Checkpoint)
    case vortex(Vortex)
    case powerUp(PowerUp)
    case finish(FinishPoint)
    
    var position: CGPoint {
        switch self {
        case .wall(let wall): return wall.position
        case .checkpoint(let checkpoint): return checkpoint.position
        case .vortex(let vortex): return vortex.position
        case .powerUp(let powerUp): return powerUp.position
        case .finish(let finish): return finish.position
        }
    }
}

struct LevelValidationResult {
    let isValid: Bool
    let errors: [String]
    let warnings: [String]
    
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
    
    var allIssues: [String] {
        return errors + warnings
    }
}

struct LevelStatistics {
    let level: Level
    let totalElements: Int
    let pathComplexity: PathComplexity
    let hazardLevel: HazardLevel
    let estimatedPlayTime: TimeInterval
    let recommendedPlayers: ClosedRange<Int>
    
    var description: String {
        return """
        Level \(level.number) Statistics:
        - Elements: \(totalElements)
        - Complexity: \(pathComplexity.displayName)
        - Hazard Level: \(hazardLevel.displayName)
        - Est. Time: \(Int(estimatedPlayTime/60))min
        - Players: \(recommendedPlayers.lowerBound)-\(recommendedPlayers.upperBound)
        """
    }
}

// MARK: - Wall
struct Wall: Codable, Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGSize
    let isBreakable: Bool
    let theme: WallTheme
    
    init(position: CGPoint, size: CGSize = CGSize(width: 64, height: 64), isBreakable: Bool = false, theme: WallTheme = .stone) {
        self.position = position
        self.size = size
        self.isBreakable = isBreakable
        self.theme = theme
    }
}

enum WallTheme: String, CaseIterable, Codable {
    case stone = "stone"
    case metal = "metal"
    case wood = "wood"
    case crystal = "crystal"
    
    var spriteName: String {
        return "wall_\(rawValue)"
    }
}

// MARK: - Vortex
struct Vortex: Codable, Identifiable {
    let id = UUID()
    let position: CGPoint
    let radius: CGFloat
    let strength: VortexStrength
    let rotationSpeed: CGFloat
    
    init(position: CGPoint, radius: CGFloat = 32, strength: VortexStrength = .normal, rotationSpeed: CGFloat = 1.0) {
        self.position = position
        self.radius = radius
        self.strength = strength
        self.rotationSpeed = rotationSpeed
    }
}

enum VortexStrength: String, CaseIterable, Codable {
    case weak = "weak"
    case normal = "normal"
    case strong = "strong"
    
    var pullForce: CGFloat {
        switch self {
        case .weak: return 50
        case .normal: return 100
        case .strong: return 200
        }
    }
}

// MARK: - Finish Point
struct FinishPoint: Codable, Identifiable {
    let id = UUID()
    let position: CGPoint
    let size: CGSize
    let type: FinishType
    
    init(position: CGPoint, size: CGSize = CGSize(width: 64, height: 64), type: FinishType = .spaceship) {
        self.position = position
        self.size = size
        self.type = type
    }
}

enum FinishType: String, CaseIterable, Codable {
    case spaceship = "spaceship"
    case portal = "portal"
    case teleporter = "teleporter"
    
    var spriteName: String {
        return "finish_\(rawValue)"
    }
}
