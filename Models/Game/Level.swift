//
//  Level.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Parsed tile-based level structure for Space Maze
struct LevelData: Codable {
    let wallPositions: [CGPoint]
    let checkpointPositions: [CGPoint]
    let vortexPositions: [CGPoint]
    let oilPositions: [CGPoint]
    let grassPositions: [CGPoint]
    let spikePositions: [CGPoint]
    let finishPositions: [CGPoint]
    let spawn: CGPoint        // the 's' tile (spawn/start)
    let width: Int
    let height: Int
    let tileSize: CGFloat     // In world units (pixels/points)
    
    /// Parse an ASCII grid level (.txt)
    static func parse(from text: String, tileSize: CGFloat = 48) -> LevelData? {
        var wallPositions: [CGPoint] = []
        var checkpointPositions: [CGPoint] = []
        var vortexPositions: [CGPoint] = []
        var oilPositions: [CGPoint] = []
        var grassPositions: [CGPoint] = []
        var spikePositions: [CGPoint] = []
        var finishPositions: [CGPoint] = []
        var spawn: CGPoint?
        
        let lines = text.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        let height = lines.count
        let width = lines.first?.count ?? 0
        
        for (row, line) in lines.enumerated() {
            for (col, char) in line.enumerated() {
                let x = CGFloat(col) * tileSize + tileSize/2
                let y = CGFloat(height - row - 1) * tileSize + tileSize/2 // (0,0) bottom left
                let pos = CGPoint(x: x, y: y)
                switch char {
                case "x":
                    wallPositions.append(pos)
                case "c":
                    checkpointPositions.append(pos)
                case "v":
                    vortexPositions.append(pos)
                case "o":
                    oilPositions.append(pos)
                case "g":
                    grassPositions.append(pos)
                case "#":
                    spikePositions.append(pos)
                case "f":
                    finishPositions.append(pos)
                case "s":
                    spawn = pos
                default:
                    continue // walkable/empty
                }
            }
        }
        
        guard let spawnPoint = spawn else { return nil }
        
        return LevelData(
            wallPositions: wallPositions,
            checkpointPositions: checkpointPositions,
            vortexPositions: vortexPositions,
            oilPositions: oilPositions,
            grassPositions: grassPositions,
            spikePositions: spikePositions,
            finishPositions: finishPositions,
            spawn: spawnPoint,
            width: width,
            height: height,
            tileSize: tileSize
        )
    }
}
