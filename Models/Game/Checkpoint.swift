//
//  Checkpoint.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

/// Represents a checkpoint (for revive and progress) in the game level.
struct Checkpoint: Identifiable, Codable, Equatable {
    let id: Int
    let position: CGPoint
    var isReached: Bool
    
    init(id: Int, position: CGPoint, isReached: Bool = false) {
        self.id = id
        self.position = position
        self.isReached = isReached
    }
}
