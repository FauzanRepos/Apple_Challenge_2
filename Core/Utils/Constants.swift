//
//  Constants.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

struct Constants {
    
    // MARK: - Game Configuration
    static let gameTitle = "SpaceMaze"
    static let gameVersion = "1.0.0"
    static let maxPlayersPerRoom = 8
    static let minPlayersToStart = 2
    static let defaultPlayerLives = 3
    static let checkpointScore = 10
    static let starCollectionScore = 5
    
    // MARK: - Level Configuration
    static let defaultCellSize: CGFloat = 64
    static let levelFileExtension = "txt"
    static let maxLevelsPerWorld = 10
    static let defaultRespawnDelay: TimeInterval = 2.0
    
    // MARK: - Physics Configuration
    static let defaultGravity: CGFloat = 9.8
    static let playerLinearDamping: CGFloat = 0.5
    static let playerMaxVelocity: CGFloat = 500.0
    static let accelerometerSensitivity: CGFloat = 50.0
    static let touchSensitivity: CGFloat = 100.0
    
    // MARK: - Multiplayer Configuration
    static let maxGameCodeLength = 6
    static let gameCodeExpirationMinutes = 30
    static let maxConnectionTimeout: TimeInterval = 30.0
    static let heartbeatInterval: TimeInterval = 1.0
    static let syncRate: TimeInterval = 1.0 / 30.0 // 30 FPS
    static let maxLatency: TimeInterval = 0.5 // 500ms
    
    // MARK: - Network Configuration
    static let serviceType = "spacemaze-game"
    static let maxMessageSize = 1024 * 10 // 10KB
    static let messageTimeout: TimeInterval = 10.0
    static let reconnectAttempts = 3
    static let reconnectDelay: TimeInterval = 2.0
    
    // MARK: - Audio Configuration
    static let defaultMusicVolume: Float = 0.7
    static let defaultSFXVolume: Float = 0.8
    static let audioFadeInDuration: TimeInterval = 0.5
    static let audioFadeOutDuration: TimeInterval = 0.3
    
    // MARK: - UI Configuration
    static let animationDuration: TimeInterval = 0.3
    static let longAnimationDuration: TimeInterval = 0.6
    static let buttonTapDelay: TimeInterval = 0.1
    static let autoHideDelay: TimeInterval = 3.0
    static let toastDisplayDuration: TimeInterval = 2.0
    
    // MARK: - Screen Edge Detection
    static let defaultEdgeMarginRatio: CGFloat = 0.15
    static let mapMoverEdgeMarginRatio: CGFloat = 0.15
    static let regularPlayerEdgeMarginRatio: CGFloat = 0.075
    static let mapScrollSpeed: CGFloat = 10.0
    
    // MARK: - Power-Up Configuration
    static let powerUpDuration: TimeInterval = 5.0
    static let oilSpeedMultiplier: CGFloat = 1.5
    static let grassSpeedMultiplier: CGFloat = 0.5
    static let powerUpRespawnDelay: TimeInterval = 10.0
    
    // MARK: - Visual Effects
    static let checkpointPulseScale: CGFloat = 1.1
    static let checkpointPulseDuration: TimeInterval = 0.5
    static let vortexRotationDuration: TimeInterval = 1.0
    static let playerInvulnerabilityFlashes = 5
    static let explosionDuration: TimeInterval = 0.25
    
    // MARK: - File Paths
    static let levelsDirectory = "Levels"
    static let soundsDirectory = "Sounds"
    static let musicDirectory = "Music"
    static let configDirectory = "Configurations"
    
    // MARK: - Asset Names
    struct AssetNames {
        static let playerSprite = "player"
        static let wallSprite = "block"
        static let checkpointSprite = "checkpoint"
        static let starSprite = "star"
        static let vortexSprite = "vortex"
        static let finishSprite = "finish"
        static let compassSprite = "Compass"
        static let backgroundSprite = "background"
        
        // Power-ups
        static let oilPowerUp = "oil"
        static let grassPowerUp = "grass"
        
        // UI Elements
        static let readyButton = "ready_button"
        static let startButton = "start_button"
        static let backButton = "back_button"
    }
    
    // MARK: - Sound Names
    struct SoundNames {
        static let backgroundMusic = "game_theme"
        static let menuMusic = "menu_theme"
        static let checkpointSound = "checkpoint"
        static let collisionSound = "collision"
        static let powerUpSound = "powerup"
        static let victorySound = "victory"
        static let deathSound = "death"
        static let buttonSound = "button"
        static let connectSound = "connect"
        static let disconnectSound = "disconnect"
    }
    
    // MARK: - Color Configuration
    struct Colors {
        static let primaryColor = "PrimaryColor"
        static let secondaryColor = "SecondaryColor"
        static let accentColor = "AccentColor"
        static let backgroundColor = "BackgroundColor"
        static let textColor = "TextColor"
        static let errorColor = "ErrorColor"
        static let successColor = "SuccessColor"
        static let warningColor = "WarningColor"
    }
    
    // MARK: - Player Types Distribution
    static func getMapMoverCount(for totalPlayers: Int) -> Int {
        return max(1, totalPlayers / 3)
    }
    
    static func getRegularPlayerCount(for totalPlayers: Int) -> Int {
        return totalPlayers - getMapMoverCount(for: totalPlayers)
    }
    
    // MARK: - Level Configuration
    static func getCellSize(for screenWidth: CGFloat) -> CGFloat {
        return screenWidth / 16 // Adjust divisor based on desired level scale
    }
    
    static func getEdgeMargin(for screenSize: CGSize, playerType: PlayerType) -> CGFloat {
        let ratio = playerType == .mapMover ? mapMoverEdgeMarginRatio : regularPlayerEdgeMarginRatio
        return min(screenSize.width, screenSize.height) * ratio
    }
    
    // MARK: - Network Validation
    static func isValidPlayerCount(_ count: Int) -> Bool {
        return count >= minPlayersToStart && count <= maxPlayersPerRoom
    }
    
    static func isValidGameCode(_ code: String) -> Bool {
        return code.count == maxGameCodeLength &&
               code.allSatisfy { "ABCDEFGHJKLMNPQRSTUVWXYZ23456789".contains($0) }
    }
    
    // MARK: - Debug Configuration
    #if DEBUG
    static let showDebugInfo = true
    static let showFPS = true
    static let showNodeCount = true
    static let enableLogging = true
    static let simulateNetworkDelay = false
    static let networkDelayRange: ClosedRange<TimeInterval> = 0.1...0.3
    #else
    static let showDebugInfo = false
    static let showFPS = false
    static let showNodeCount = false
    static let enableLogging = false
    static let simulateNetworkDelay = false
    static let networkDelayRange: ClosedRange<TimeInterval> = 0.0...0.0
    #endif
    
    // MARK: - Performance Configuration
    static let maxConcurrentConnections = 8
    static let backgroundTaskTimeout: TimeInterval = 30.0
    static let memoryWarningThreshold = 50 // MB
    static let maxCachedLevels = 5
    static let maxCachedSounds = 10
    
    // MARK: - Error Messages
    struct ErrorMessages {
        static let connectionFailed = "Failed to connect to game"
        static let invalidGameCode = "Invalid game code"
        static let gameFull = "Game is full"
        static let hostDisconnected = "Host disconnected"
        static let networkError = "Network error occurred"
        static let gameNotFound = "Game not found"
        static let playerNotReady = "Not all players are ready"
        static let levelLoadFailed = "Failed to load level"
        static let audioInitFailed = "Failed to initialize audio"
    }
    
    // MARK: - Success Messages
    struct SuccessMessages {
        static let gameCreated = "Game created successfully"
        static let playerJoined = "Player joined the game"
        static let gameStarted = "Game started"
        static let levelCompleted = "Level completed!"
        static let checkpointReached = "Checkpoint reached"
        static let powerUpCollected = "Power-up collected"
    }
    
    // MARK: - Notification Names
    struct NotificationNames {
        static let gameStateChanged = "GameStateChanged"
        static let playerJoined = "PlayerJoined"
        static let playerLeft = "PlayerLeft"
        static let gameStarted = "GameStarted"
        static let gameEnded = "GameEnded"
        static let levelCompleted = "LevelCompleted"
        static let checkpointReached = "CheckpointReached"
        static let powerUpCollected = "PowerUpCollected"
        static let connectionStateChanged = "ConnectionStateChanged"
        static let audioSettingsChanged = "AudioSettingsChanged"
    }
    
    // MARK: - UserDefaults Keys
    struct UserDefaultsKeys {
        static let playerName = "PlayerName"
        static let highScore = "HighScore"
        static let currentLevel = "CurrentLevel"
        static let musicEnabled = "MusicEnabled"
        static let soundEffectsEnabled = "SoundEffectsEnabled"
        static let musicVolume = "MusicVolume"
        static let soundEffectsVolume = "SoundEffectsVolume"
        static let gamesPlayed = "GamesPlayed"
        static let totalScore = "TotalScore"
        static let lastPlayedDate = "LastPlayedDate"
    }
}

// MARK: - Enums
enum PlayerType: String, Codable, CaseIterable {
    case mapMover = "mapMover"
    case regular = "regular"
    
    var displayName: String {
        switch self {
        case .mapMover: return "Map Mover"
        case .regular: return "Regular"
        }
    }
    
    var description: String {
        switch self {
        case .mapMover: return "Can move the map when reaching screen edges"
        case .regular: return "Dies when reaching screen edges (spikes)"
        }
    }
}

enum PowerUpType: String, Codable, CaseIterable {
    case oil = "oil"
    case grass = "grass"
    
    var displayName: String {
        switch self {
        case .oil: return "Oil"
        case .grass: return "Grass"
        }
    }
    
    var description: String {
        switch self {
        case .oil: return "Increases movement speed"
        case .grass: return "Decreases movement speed"
        }
    }
    
    var duration: TimeInterval {
        return Constants.powerUpDuration
    }
    
    var speedMultiplier: CGFloat {
        switch self {
        case .oil: return Constants.oilSpeedMultiplier
        case .grass: return Constants.grassSpeedMultiplier
        }
    }
}

enum GameEndReason: String, Codable {
    case playerQuit = "playerQuit"
    case gameCompleted = "gameCompleted"
    case allPlayersEliminated = "allPlayersEliminated"
    case connectionLost = "connectionLost"
    case hostDisconnected = "hostDisconnected"
    case timeout = "timeout"
    case error = "error"
    
    var displayMessage: String {
        switch self {
        case .playerQuit: return "A player quit the game"
        case .gameCompleted: return "Congratulations! Game completed!"
        case .allPlayersEliminated: return "All players were eliminated"
        case .connectionLost: return "Connection lost"
        case .hostDisconnected: return "Host disconnected"
        case .timeout: return "Game timed out"
        case .error: return "An error occurred"
        }
    }
}
