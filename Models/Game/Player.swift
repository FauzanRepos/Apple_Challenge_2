//
//  Player.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a player in the game (used for local logic only)
struct Player: Identifiable, Codable, Equatable {
    let id: String
    let colorIndex: Int
    var position: CGPoint
    var velocity: CGVector
    var lives: Int
    var isMapMover: Bool
    
    init(id: String, colorIndex: Int, position: CGPoint = .zero, velocity: CGVector = .zero, lives: Int = Constants.defaultPlayerLives, isMapMover: Bool = false) {
        self.id = id
        self.colorIndex = colorIndex
        self.position = position
        self.velocity = velocity
        self.lives = lives
        self.isMapMover = isMapMover
    }
}
