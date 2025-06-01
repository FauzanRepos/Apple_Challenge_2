//
//  PowerUp.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a power-up or environmental modifier in the level.
enum PowerUpType: String, Codable, CaseIterable {
    case oil    // Makes player faster
    case grass  // Makes player slower
}

struct PowerUp: Identifiable, Codable, Equatable {
    let id: Int
    let type: PowerUpType
    let position: CGPoint
    var isActive: Bool
    
    init(id: Int, type: PowerUpType, position: CGPoint, isActive: Bool = true) {
        self.id = id
        self.type = type
        self.position = position
        self.isActive = isActive
    }
}
