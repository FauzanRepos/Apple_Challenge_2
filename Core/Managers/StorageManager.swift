//
//  StorageManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    // MARK: - UserDefaults Keys
    private enum Keys {
        static let highScore = "highScore"
        static let currentLevel = "currentLevel"
        static let musicEnabled = "musicEnabled"
        static let soundEffectsEnabled = "soundEffectsEnabled"
        static let musicVolume = "musicVolume"
        static let soundEffectsVolume = "soundEffectsVolume"
        static let playerName = "playerName"
        static let gamesPlayed = "gamesPlayed"
        static let levelsCompleted = "levelsCompleted"
        static let totalScore = "totalScore"
        static let lastPlayedDate = "lastPlayedDate"
        static let gameSettings = "gameSettings"
    }
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        setupDefaultValues()
    }
    
    // MARK: - Setup
    private func setupDefaultValues() {
        // Set default values if they don't exist
        if userDefaults.object(forKey: Keys.musicEnabled) == nil {
            userDefaults.set(true, forKey: Keys.musicEnabled)
        }
        
        if userDefaults.object(forKey: Keys.soundEffectsEnabled) == nil {
            userDefaults.set(true, forKey: Keys.soundEffectsEnabled)
        }
        
        if userDefaults.object(forKey: Keys.musicVolume) == nil {
            userDefaults.set(0.7, forKey: Keys.musicVolume)
        }
        
        if userDefaults.object(forKey: Keys.soundEffectsVolume) == nil {
            userDefaults.set(0.8, forKey: Keys.soundEffectsVolume)
        }
        
        if userDefaults.object(forKey: Keys.playerName) == nil {
            userDefaults.set("Player", forKey: Keys.playerName)
        }
    }
    
    // MARK: - Game Data
    func saveHighScore(_ score: Int) {
        userDefaults.set(score, forKey: Keys.highScore)
        print("💾 High score saved: \(score)")
    }
    
    func getHighScore() -> Int {
        return userDefaults.integer(forKey: Keys.highScore)
    }
    
    func saveCurrentLevel(_ level: Int) {
        userDefaults.set(level, forKey: Keys.currentLevel)
    }
    
    func getCurrentLevel() -> Int {
        let level = userDefaults.integer(forKey: Keys.currentLevel)
        return level > 0 ? level : 1
    }
    
    func saveGameData() {
        // Save current game state
        userDefaults.set(Date(), forKey: Keys.lastPlayedDate)
        
        // Increment games played
        let gamesPlayed = userDefaults.integer(forKey: Keys.gamesPlayed)
        userDefaults.set(gamesPlayed + 1, forKey: Keys.gamesPlayed)
        
        print("💾 Game data saved")
    }
    
    func getGamesPlayed() -> Int {
        return userDefaults.integer(forKey: Keys.gamesPlayed)
    }
    
    func saveLevelCompleted() {
        let levelsCompleted = userDefaults.integer(forKey: Keys.levelsCompleted)
        userDefaults.set(levelsCompleted + 1, forKey: Keys.levelsCompleted)
    }
    
    func getLevelsCompleted() -> Int {
        return userDefaults.integer(forKey: Keys.levelsCompleted)
    }
    
    func addToTotalScore(_ score: Int) {
        let totalScore = userDefaults.integer(forKey: Keys.totalScore)
        userDefaults.set(totalScore + score, forKey: Keys.totalScore)
    }
    
    func getTotalScore() -> Int {
        return userDefaults.integer(forKey: Keys.totalScore)
    }
    
    func getLastPlayedDate() -> Date? {
        return userDefaults.object(forKey: Keys.lastPlayedDate) as? Date
    }
    
    // MARK: - Settings
    func saveMusicEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.musicEnabled)
    }
    
    func isMusicEnabled() -> Bool {
        return userDefaults.bool(forKey: Keys.musicEnabled)
    }
    
    func saveSoundEffectsEnabled(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: Keys.soundEffectsEnabled)
    }
    
    func areSoundEffectsEnabled() -> Bool {
        return userDefaults.bool(forKey: Keys.soundEffectsEnabled)
    }
    
    func saveMusicVolume(_ volume: Float) {
        userDefaults.set(volume, forKey: Keys.musicVolume)
    }
    
    func getMusicVolume() -> Float {
        return userDefaults.float(forKey: Keys.musicVolume)
    }
    
    func saveSoundEffectsVolume(_ volume: Float) {
        userDefaults.set(volume, forKey: Keys.soundEffectsVolume)
    }
    
    func getSoundEffectsVolume() -> Float {
        return userDefaults.float(forKey: Keys.soundEffectsVolume)
    }
    
    func savePlayerName(_ name: String) {
        userDefaults.set(name, forKey: Keys.playerName)
    }
    
    func getPlayerName() -> String {
        return userDefaults.string(forKey: Keys.playerName) ?? "Player"
    }
    
    // MARK: - Game Settings
    func saveGameSettings(_ settings: GameSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            userDefaults.set(data, forKey: Keys.gameSettings)
        }
    }
    
    func getGameSettings() -> GameSettings {
        if let data = userDefaults.data(forKey: Keys.gameSettings),
           let settings = try? JSONDecoder().decode(GameSettings.self, from: data) {
            return settings
        }
        return GameSettings() // Return default settings
    }
    
    // MARK: - Data Management
    func resetGameData() {
        userDefaults.removeObject(forKey: Keys.highScore)
        userDefaults.removeObject(forKey: Keys.currentLevel)
        userDefaults.removeObject(forKey: Keys.gamesPlayed)
        userDefaults.removeObject(forKey: Keys.levelsCompleted)
        userDefaults.removeObject(forKey: Keys.totalScore)
        userDefaults.removeObject(forKey: Keys.lastPlayedDate)
        
        print("🗑️ Game data reset")
    }
    
    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier!
        userDefaults.removePersistentDomain(forName: domain)
        setupDefaultValues()
        
        print("🗑️ All data reset")
    }
    
    // MARK: - Statistics
    func getGameStatistics() -> GameStatistics {
        return GameStatistics(
            highScore: getHighScore(),
            gamesPlayed: getGamesPlayed(),
            levelsCompleted: getLevelsCompleted(),
            totalScore: getTotalScore(),
            lastPlayedDate: getLastPlayedDate()
        )
    }
}

// MARK: - Data Models
struct GameSettings: Codable {
    var musicEnabled: Bool = true
    var soundEffectsEnabled: Bool = true
    var musicVolume: Float = 0.7
    var soundEffectsVolume: Float = 0.8
    var playerName: String = "Player"
    
    init() {}
}

struct GameStatistics {
    let highScore: Int
    let gamesPlayed: Int
    let levelsCompleted: Int
    let totalScore: Int
    let lastPlayedDate: Date?
}
