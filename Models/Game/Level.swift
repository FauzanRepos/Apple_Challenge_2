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
    var wallPositions: [CGPoint]
    var checkpointPositions: [CGPoint]
    var vortexPositions: [CGPoint]
    var oilPositions: [CGPoint]
    var grassPositions: [CGPoint]
    var spikePositions: [CGPoint]
    var finishPositions: [CGPoint]
    var spawn: CGPoint        // the 's' tile (spawn/start)
    var width: Int
    var height: Int
    var tileSize: CGFloat     // In world units (pixels/points)
    
    /// Parse an ASCII grid level (.txt)
    static func parse(from text: String, tileSize: CGFloat = 48) -> LevelData? {
        print("[LevelData] Starting to parse level data")
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
        
        print("[LevelData] Level dimensions: \(width)x\(height)")
        
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
        
        guard let spawnPoint = spawn else {
            print("[LevelData] ERROR: No spawn point found in level")
            return nil
        }
        
        print("[LevelData] Parsed level elements:")
        print("- Walls: \(wallPositions.count)")
        print("- Checkpoints: \(checkpointPositions.count)")
        print("- Vortexes: \(vortexPositions.count)")
        print("- Oil: \(oilPositions.count)")
        print("- Grass: \(grassPositions.count)")
        print("- Spikes: \(spikePositions.count)")
        print("- Finish: \(finishPositions.count)")
        print("- Spawn: \(spawnPoint)")
        
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
