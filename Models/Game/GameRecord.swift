//
//  GameRecord.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Represents a finished game session (for stats/highscore table).
struct GameRecord: Identifiable, Codable, Equatable {
    let id: String
    let date: Date
    let planet: Int
    let section: Int
    let playerCount: Int
    
    init(id: String = UUID().uuidString, date: Date = Date(), planet: Int, section: Int, playerCount: Int) {
        self.id = id
        self.date = date
        self.planet = planet
        self.section = section
        self.playerCount = playerCount
    }
}
