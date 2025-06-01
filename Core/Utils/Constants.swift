//
//  Constants.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SwiftUI

struct Constants {
    static let maxPlayers = 8
    static let minPlayers = 2
    static let maxTeamLives = 5
    static let defaultPlayerLives = 5
    static let numberOfSections = 4
    static let defaultSensitivity: Float = 1.0
    static let gameVersion = "1.0"
    static let checkpointRadius: CGFloat = 36
    static let playerSize: CGFloat = 48
    static let spikeSize: CGFloat = 44
    static let oilSize: CGFloat = 36
    static let grassSize: CGFloat = 40
    static let vortexSize: CGFloat = 44
    static let finishSize: CGFloat = 52
    
    // Color overlays for up to 8 players (player index as array position)
    static let playerColors: [Color] = [
        .blue, .red, .green, .yellow, .orange, .purple, .pink, .mint
    ]
    
    // Asset naming for planet-specific objects
    static func asset(for type: GameObjectType, planet: Int) -> String {
        "Planets/Planet\(planet)/\(type.assetName)"
    }
}

/// All types of game objects that require asset switching
enum GameObjectType: String, CaseIterable {
    case wall, floor, checkpoint, spike, oil, grass, vortex, spaceship
    var assetName: String { rawValue }
}
