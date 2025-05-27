//
//  SettingsManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import Combine

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    // MARK: - Published Properties
    @Published var gameSettings: GameSettings {
        didSet {
            saveSettings()
            applySettings()
        }
    }
    
    // MARK: - Private Properties
    private let storageManager = StorageManager.shared
    private let audioManager = AudioManager.shared
    
    private init() {
        // Load settings from storage
        self.gameSettings = storageManager.getGameSettings()
        applySettings()
    }
    
    // MARK: - Settings Management
    private func saveSettings() {
        storageManager.saveGameSettings(gameSettings)
    }
    
    private func applySettings() {
        // Apply audio settings
        audioManager.updateSettings(
            musicEnabled: gameSettings.musicEnabled,
            soundEffectsEnabled: gameSettings.soundEffectsEnabled,
            musicVolume: gameSettings.musicVolume,
            soundEffectsVolume: gameSettings.soundEffectsVolume
        )
        
        // Save individual settings for backward compatibility
        storageManager.saveMusicEnabled(gameSettings.musicEnabled)
        storageManager.saveSoundEffectsEnabled(gameSettings.soundEffectsEnabled)
        storageManager.saveMusicVolume(gameSettings.musicVolume)
        storageManager.saveSoundEffectsVolume(gameSettings.soundEffectsVolume)
        storageManager.savePlayerName(gameSettings.playerName)
    }
    
    // MARK: - Audio Settings
    func toggleMusic() {
        gameSettings.musicEnabled.toggle()
        audioManager.playButtonSound()
    }
    
    func toggleSoundEffects() {
        let wasEnabled = gameSettings.soundEffectsEnabled
        gameSettings.soundEffectsEnabled.toggle()
        
        // Play sound effect if we just enabled it
        if !wasEnabled && gameSettings.soundEffectsEnabled {
            audioManager.playButtonSound()
        }
    }
    
    func setMusicVolume(_ volume: Float) {
        gameSettings.musicVolume = max(0.0, min(1.0, volume))
    }
    
    func setSoundEffectsVolume(_ volume: Float) {
        gameSettings.soundEffectsVolume = max(0.0, min(1.0, volume))
        audioManager.playButtonSound() // Test the new volume
    }
    
    // MARK: - Player Settings
    func setPlayerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        gameSettings.playerName = trimmedName.isEmpty ? "Player" : trimmedName
    }
    
    func getPlayerName() -> String {
        return gameSettings.playerName
    }
    
    // MARK: - Game Difficulty Settings (Future)
    func setDifficulty(_ difficulty: GameDifficulty) {
        // TODO: Implement when difficulty levels are added
        print("🎯 Difficulty set to: \(difficulty)")
    }
    
    // MARK: - Multiplayer Settings
    func getMultiplayerSettings() -> MultiplayerSettings {
        return MultiplayerSettings(
            playerName: gameSettings.playerName,
            preferredPlayerType: .mapMover, // Default preference
            autoReady: false
        )
    }
    
    func updateMultiplayerSettings(_ settings: MultiplayerSettings) {
        gameSettings.playerName = settings.playerName
        // Save additional multiplayer preferences if needed
    }
    
    // MARK: - Reset Settings
    func resetToDefaults() {
        gameSettings = GameSettings()
        audioManager.playButtonSound()
        print("⚙️ Settings reset to defaults")
    }
    
    // MARK: - Settings Presets
    func applyPreset(_ preset: SettingsPreset) {
        switch preset {
        case .silent:
            gameSettings.musicEnabled = false
            gameSettings.soundEffectsEnabled = false
            
        case .musicOnly:
            gameSettings.musicEnabled = true
            gameSettings.soundEffectsEnabled = false
            gameSettings.musicVolume = 0.5
            
        case .soundEffectsOnly:
            gameSettings.musicEnabled = false
            gameSettings.soundEffectsEnabled = true
            gameSettings.soundEffectsVolume = 0.8
            
        case .fullAudio:
            gameSettings.musicEnabled = true
            gameSettings.soundEffectsEnabled = true
            gameSettings.musicVolume = 0.7
            gameSettings.soundEffectsVolume = 0.8
        }
        
        audioManager.playButtonSound()
    }
    
    // MARK: - Validation
    func validateSettings() -> Bool {
        // Validate player name
        if gameSettings.playerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            gameSettings.playerName = "Player"
        }
        
        // Validate audio levels
        gameSettings.musicVolume = max(0.0, min(1.0, gameSettings.musicVolume))
        gameSettings.soundEffectsVolume = max(0.0, min(1.0, gameSettings.soundEffectsVolume))
        
        return true
    }
    
    // MARK: - Import/Export Settings (Future Feature)
    func exportSettings() -> Data? {
        return try? JSONEncoder().encode(gameSettings)
    }
    
    func importSettings(from data: Data) -> Bool {
        guard let importedSettings = try? JSONDecoder().decode(GameSettings.self, from: data) else {
            return false
        }
        
        gameSettings = importedSettings
        return validateSettings()
    }
}

// MARK: - Supporting Enums and Structs
enum GameDifficulty: String, CaseIterable {
    case easy = "Easy"
    case normal = "Normal"
    case hard = "Hard"
    case expert = "Expert"
}

enum SettingsPreset: String, CaseIterable {
    case silent = "Silent"
    case musicOnly = "Music Only"
    case soundEffectsOnly = "Sound Effects Only"
    case fullAudio = "Full Audio"
}

struct MultiplayerSettings {
    var playerName: String
    var preferredPlayerType: PlayerType
    var autoReady: Bool
    
    init(playerName: String = "Player", preferredPlayerType: PlayerType = .mapMover, autoReady: Bool = false) {
        self.playerName = playerName
        self.preferredPlayerType = preferredPlayerType
        self.autoReady = autoReady
    }
}

// MARK: - Settings Categories for UI
enum SettingsCategory: String, CaseIterable {
    case audio = "Audio"
    case player = "Player"
    case multiplayer = "Multiplayer"
    case game = "Game"
    case about = "About"
    
    var icon: String {
        switch self {
        case .audio: return "speaker.wave.2"
        case .player: return "person"
        case .multiplayer: return "person.2"
        case .game: return "gamecontroller"
        case .about: return "info.circle"
        }
    }
}
