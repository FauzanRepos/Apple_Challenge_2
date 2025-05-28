//
//  LevelManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SpriteKit

class LevelManager: ObservableObject {
    static let shared = LevelManager()
    
    // MARK: - Properties
    @Published var currentLevel: Level?
    @Published var currentLevelNumber: Int = 1
    
    private var levelCache: [Int: Level] = [:]
    
    private init() {}
    
    // MARK: - Level Loading
    func loadLevel(_ levelNumber: Int) {
        print("📄 Loading level \(levelNumber)")
        
        // Check cache first
        if let cachedLevel = levelCache[levelNumber] {
            currentLevel = cachedLevel
            currentLevelNumber = levelNumber
            return
        }
        
        // Load from file
        guard let levelPath = Bundle.main.path(forResource: "level\(levelNumber)", ofType: "txt"),
              let levelString = try? String(contentsOfFile: levelPath) else {
            print("❌ Failed to load level \(levelNumber)")
            return
        }
        
        let level = parseLevel(from: levelString, levelNumber: levelNumber)
        
        // Cache the level
        levelCache[levelNumber] = level
        currentLevel = level
        currentLevelNumber = levelNumber
        
        print("✅ Level \(levelNumber) loaded successfully")
    }
    
    func levelExists(_ levelNumber: Int) -> Bool {
        return Bundle.main.path(forResource: "level\(levelNumber)", ofType: "txt") != nil
    }
    
    // MARK: - Level Parsing
    private func parseLevel(from levelString: String, levelNumber: Int) -> Level {
        let lines = levelString.components(separatedBy: "\n").filter { !$0.isEmpty }
        
        var walls: [Wall] = []
        var checkpoints: [Checkpoint] = []
        var vortexes: [Vortex] = []
        var powerUps: [PowerUp] = []
        var finishPoint: FinishPoint?
        var playerStartPositions: [CGPoint] = []
        
        let cellSize: CGFloat = 64
        
        for (row, line) in lines.reversed().enumerated() {
            for (column, letter) in line.enumerated() {
                let position = CGPoint(
                    x: (cellSize * CGFloat(column)) + (cellSize/2),
                    y: (cellSize * CGFloat(row)) + (cellSize/2)
                )
                
                switch letter {
                case "x":
                    walls.append(Wall(position: position, size: CGSize(width: cellSize, height: cellSize)))
                    
                case "s":
                    let checkpointId = "checkpoint_\(row)_\(column)"
                    checkpoints.append(Checkpoint(id: checkpointId, position: position))
                    
                case "v":
                    vortexes.append(Vortex(position: position))
                    
                case "f":
                    finishPoint = FinishPoint(position: position)
                    
                case "o": // Oil power-up
                    powerUps.append(PowerUp(type: PowerUpType.oil, position: position))
                    
                case "g": // Grass power-up
                    powerUps.append(PowerUp(type: PowerUpType.grass, position: position))
                    
                case "p": // Player start position
                    playerStartPositions.append(position)
                    
                default:
                    break // Empty space
                }
            }
        }
        
        // If no explicit player start positions, use default
        if playerStartPositions.isEmpty {
            playerStartPositions.append(CGPoint(x: cellSize * 1.5, y: cellSize * 1.5))
        }
        
        let levelSize = CGSize(
            width: cellSize * CGFloat(lines.first?.count ?? 0),
            height: cellSize * CGFloat(lines.count)
        )
        
        return Level(
            number: levelNumber,
            size: levelSize,
            walls: walls,
            checkpoints: checkpoints,
            vortexes: vortexes,
            powerUps: powerUps,
            finishPoint: finishPoint ?? FinishPoint(position: CGPoint.zero),
            playerStartPositions: playerStartPositions
        )
    }
    
    // MARK: - Level Information
    func getPlayerStartPositions(for playerCount: Int) -> [CGPoint] {
        guard let level = currentLevel else { return [] }
        
        let availablePositions = level.playerStartPositions
        
        // If we have enough defined positions, use them
        if availablePositions.count >= playerCount {
            return Array(availablePositions.prefix(playerCount))
        }
        
        // Otherwise, generate positions around the first start position
        let basePosition = availablePositions.first ?? CGPoint(x: 96, y: 672)
        var positions: [CGPoint] = [basePosition]
        
        let spacing: CGFloat = 80
        for i in 1..<playerCount {
            let angle = (CGFloat.pi * 2 / CGFloat(playerCount)) * CGFloat(i)
            let x = basePosition.x + cos(angle) * spacing
            let y = basePosition.y + sin(angle) * spacing
            positions.append(CGPoint(x: x, y: y))
        }
        
        return positions
    }
    
    func getCheckpoints() -> [Checkpoint] {
        return currentLevel?.checkpoints ?? []
    }
    
    func getWalls() -> [Wall] {
        return currentLevel?.walls ?? []
    }
    
    func getVortexes() -> [Vortex] {
        return currentLevel?.vortexes ?? []
    }
    
    func getPowerUps() -> [PowerUp] {
        return currentLevel?.powerUps ?? []
    }
    
    func getFinishPoint() -> FinishPoint? {
        return currentLevel?.finishPoint
    }
    
    func getLevelSize() -> CGSize {
        return currentLevel?.size ?? CGSize(width: 1024, height: 768)
    }
    
    // MARK: - Level Progress
    func isLevelCompleted() -> Bool {
        // Level is completed when all players reach the finish point
        // This will be handled by the GameScene
        return false
    }
    
    func getNextLevelNumber() -> Int? {
        let nextLevel = currentLevelNumber + 1
        return levelExists(nextLevel) ? nextLevel : nil
    }
    
    func resetLevel() {
        // Reload the current level
        loadLevel(currentLevelNumber)
    }
}
