//
//  SessionState.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Represents the overall multiplayer session state (used for syncing game start/progress).
struct SessionState: Codable, Equatable {
    var roomCode: String
    var isStarted: Bool
    var currentLevel: Int
    var playersReady: [String] // Player IDs ready
    
    init(roomCode: String, isStarted: Bool = false, currentLevel: Int = 1, playersReady: [String] = []) {
        self.roomCode = roomCode
        self.isStarted = isStarted
        self.currentLevel = currentLevel
        self.playersReady = playersReady
    }
}
