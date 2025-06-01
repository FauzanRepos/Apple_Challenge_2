//
//  Level.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a parsed level with all its environment and objectives.
struct Level: Codable {
    let id: Int
    let planet: Int
    let name: String
    let width: Int
    let height: Int
    let wallRects: [CGRect]
    let checkpointPositions: [CGPoint]
    let vortexPositions: [CGPoint]
    let oilPositions: [CGPoint]
    let grassPositions: [CGPoint]
    let start: CGPoint
    let finish: CGPoint
    
    init(id: Int, planet: Int, name: String, width: Int, height: Int, wallRects: [CGRect], checkpointPositions: [CGPoint], vortexPositions: [CGPoint], oilPositions: [CGPoint], grassPositions: [CGPoint], start: CGPoint, finish: CGPoint) {
        self.id = id
        self.planet = planet
        self.name = name
        self.width = width
        self.height = height
        self.wallRects = wallRects
        self.checkpointPositions = checkpointPositions
        self.vortexPositions = vortexPositions
        self.oilPositions = oilPositions
        self.grassPositions = grassPositions
        self.start = start
        self.finish = finish
    }
}
