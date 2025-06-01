//
//  GameEvent.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Encodes key in-game events for multiplayer sync.
enum GameEventType: String, Codable {
    case playerDeath
    case checkpointReached
    case missionAccomplished
    case missionFailed
    case pause
    case cameraMoved
    case resumeRequest
}

struct GameEvent: Codable {
    let type: GameEventType
    let playerID: String?    // Affected player (if any)
    let section: Int?        // Section index (if checkpoint)
    let timestamp: Date
    let cameraPosition: CGPoint?
    
    init(type: GameEventType, playerID: String? = nil, section: Int? = nil, cameraPosition: CGPoint? = nil, timestamp: Date = Date()) {
        self.type = type
        self.playerID = playerID
        self.section = section
        self.cameraPosition = cameraPosition
        self.timestamp = timestamp
    }
}
