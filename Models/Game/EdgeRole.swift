//
//  EdgeRole.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Represents which edge of the map a player can move (if any)
enum EdgeRole: String, Codable, CaseIterable {
    case top
    case bottom
    case left
    case right
}
