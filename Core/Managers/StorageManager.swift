//
//  StorageManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

/// Handles persistent storage for highscores and achievements.
final class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    @Published var highScore: HighScore = HighScore()
    
    private let highScoreKey = "spaceMazeHighScore"
    
    private init() {
        loadHighScore()
    }
    
    func saveHighScoreIfNeeded(_ level: Int, section: Int) {
        // If new high score, update
        if level > highScore.planet || (level == highScore.planet && section > highScore.section) {
            highScore = HighScore(planet: level, section: section)
            persistHighScore()
        }
    }
    
    func loadHighScore() {
        let defaults = UserDefaults.standard
        let planet = defaults.integer(forKey: "\(highScoreKey)_planet")
        let section = defaults.integer(forKey: "\(highScoreKey)_section")
        highScore = HighScore(planet: planet, section: section)
    }
    
    func persistHighScore() {
        let defaults = UserDefaults.standard
        defaults.set(highScore.planet, forKey: "\(highScoreKey)_planet")
        defaults.set(highScore.section, forKey: "\(highScoreKey)_section")
    }
    
    func resetHighScore() {
        highScore = HighScore()
        persistHighScore()
    }
}

/// Struct for storing team highscore as "Planet X Section Y/4"
struct HighScore: Codable, Equatable {
    var planet: Int = 1
    var section: Int = 1
}
