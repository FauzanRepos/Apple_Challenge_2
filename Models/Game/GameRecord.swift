//
//  GameRecord.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import UIKit
import Foundation

// MARK: - Game Record Model
struct GameRecord: Codable, Identifiable {
    
    let id: String
    let playedAt: Date
    let gameMode: GameRecordMode
    let playerCount: Int
    let playerNames: [String]
    let finalScore: Int
    let levelsCompleted: Int
    let totalPlayTime: TimeInterval
    let gameEndReason: GameEndReason
    
    // Detailed Statistics
    let checkpointsReached: Int
    let powerUpsCollected: Int
    let deathCount: Int
    let teamLivesUsed: Int
    
    // Performance Metrics
    let averageTimePerLevel: TimeInterval
    let highestLevelReached: Int
    let perfectLevels: Int // Levels completed without deaths
    let speedRunTime: TimeInterval? // Time to complete if finished
    
    // Multiplayer Specific
    let gameCode: String?
    let wasHost: Bool
    let connectionQuality: ConnectionQuality?
    let syncIssues: Int
    
    // Achievement Data
    let achievementsUnlocked: [String]
    let milestonesReached: [String]
    let personalBests: [PersonalBest]
    
    // Device and Session Info
    let deviceType: String
    let appVersion: String
    let sessionId: String
    
    // MARK: - Initialization
    init(
        gameState: GameState,
        endReason: GameEndReason,
        achievements: [String] = [],
        milestones: [String] = [],
        personalBests: [PersonalBest] = []
    ) {
        self.id = UUID().uuidString
        self.playedAt = Date()
        self.gameMode = gameState.isMultiplayer ? .multiplayer : .singlePlayer
        self.playerCount = gameState.players.count
        self.playerNames = gameState.players.map { $0.name }
        self.finalScore = gameState.teamScore
        self.levelsCompleted = gameState.currentLevel - 1
        self.totalPlayTime = gameState.elapsedTime
        self.gameEndReason = endReason
        
        // Calculate statistics from game state
        self.checkpointsReached = gameState.completedCheckpoints.count
        self.powerUpsCollected = gameState.players.reduce(0) { total, player in
            total + player.activePowerUps.count
        }
        self.deathCount = gameState.players.reduce(0) { total, player in
            total + (Constants.defaultPlayerLives - player.lives)
        }
        self.teamLivesUsed = 5 - gameState.teamLives
        
        // Performance metrics
        self.averageTimePerLevel = gameState.elapsedTime / TimeInterval(max(1, gameState.currentLevel - 1))
        self.highestLevelReached = gameState.currentLevel
        self.perfectLevels = 0 // Would need to track this during gameplay
        self.speedRunTime = endReason == .gameCompleted ? gameState.elapsedTime : nil
        
        // Multiplayer info
        self.gameCode = gameState.isMultiplayer ? gameState.gameCode : nil
        self.wasHost = gameState.isHost
        self.connectionQuality = gameState.isMultiplayer ? .good : nil // Would need actual measurement
        self.syncIssues = 0 // Would need to track during gameplay
        
        // Achievements
        self.achievementsUnlocked = achievements
        self.milestonesReached = milestones
        self.personalBests = personalBests
        
        // Device info
        self.deviceType = UIDevice.current.model
        self.appVersion = Constants.gameVersion
        self.sessionId = gameState.sessionId
    }
    
    // MARK: - Computed Properties
    var isHighScore: Bool {
        return finalScore > StorageManager.shared.getHighScore()
    }
    
    var wasSuccessful: Bool {
        return gameEndReason == .gameCompleted
    }
    
    var completionRate: Double {
        return levelsCompleted > 0 ? Double(levelsCompleted) / Double(highestLevelReached) : 0.0
    }
    
    var survivalRate: Double {
        let totalPossibleLives = playerCount * Constants.defaultPlayerLives
        let livesLost = deathCount
        return Double(totalPossibleLives - livesLost) / Double(totalPossibleLives)
    }
    
    var efficiencyScore: Double {
        guard totalPlayTime > 0 else { return 0.0 }
        let pointsPerSecond = Double(finalScore) / totalPlayTime
        return pointsPerSecond * 100 // Scale for readability
    }
    
    var teamworkScore: Double {
        guard playerCount > 1 else { return 1.0 }
        // Simple teamwork metric based on completion and survival
        return (completionRate + survivalRate) / 2.0
    }
    
    var grade: GameGrade {
        let score = (completionRate * 0.4) + (survivalRate * 0.3) + (min(efficiencyScore / 10.0, 1.0) * 0.3)
        
        switch score {
        case 0.9...1.0: return .S
        case 0.8..<0.9: return .A
        case 0.7..<0.8: return .B
        case 0.6..<0.7: return .C
        case 0.5..<0.6: return .D
        default: return .F
        }
    }
    
    var playTimeFormatted: String {
        return String.durationString(from: totalPlayTime)
    }
    
    var averageLevelTimeFormatted: String {
        return String.durationString(from: averageTimePerLevel)
    }
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: playedAt)
    }
    
    var summary: String {
        let playersText = playerCount == 1 ? "Solo" : "\(playerCount) Players"
        let scoreText = String.formatScore(finalScore)
        let levelsText = levelsCompleted == 1 ? "1 Level" : "\(levelsCompleted) Levels"
        
        return "\(playersText) • \(scoreText) • \(levelsText) • \(playTimeFormatted)"
    }
    
    // MARK: - Comparison Methods
    func isNewPersonalBest(category: PersonalBestCategory) -> Bool {
        switch category {
        case .highScore:
            return finalScore > StorageManager.shared.getHighScore()
        case .fastestCompletion:
            guard let speedTime = speedRunTime else { return false }
            // Would need to check against stored fastest time
            return true
        case .mostLevels:
            // Would need to check against stored record
            return true
        case .perfectRun:
            return deathCount == 0 && wasSuccessful
        case .teamwork:
            return playerCount > 1 && teamworkScore > 0.9
        }
    }
    
    func getNewAchievements() -> [Achievement] {
        var achievements: [Achievement] = []
        
        // Score-based achievements
        if finalScore >= 1000 {
            achievements.append(.scoreThousand)
        }
        if finalScore >= 5000 {
            achievements.append(.scoreFiveThousand)
        }
        
        // Level-based achievements
        if levelsCompleted >= 5 {
            achievements.append(.levelsFive)
        }
        if levelsCompleted >= 10 {
            achievements.append(.levelsTen)
        }
        
        // Perfect play achievements
        if deathCount == 0 && levelsCompleted > 0 {
            achievements.append(.perfectLevel)
        }
        
        // Multiplayer achievements
        if playerCount >= 4 && wasSuccessful {
            achievements.append(.teamPlayer)
        }
        
        // Speed achievements
        if let speedTime = speedRunTime, speedTime < 300 { // Under 5 minutes
            achievements.append(.speedRunner)
        }
        
        return achievements
    }
    
    // MARK: - Statistics Methods
    func getDetailedStats() -> GameRecordStats {
        return GameRecordStats(
            record: self,
            scoringBreakdown: getScoringBreakdown(),
            timeBreakdown: getTimeBreakdown(),
            performanceMetrics: getPerformanceMetrics()
        )
    }
    
    private func getScoringBreakdown() -> ScoringBreakdown {
        let checkpointScore = checkpointsReached * Constants.checkpointScore
        let powerUpScore = powerUpsCollected * Constants.starCollectionScore
        let levelBonus = levelsCompleted * 100
        let survivalBonus = (5 - teamLivesUsed) * 50
        
        return ScoringBreakdown(
            checkpoints: checkpointScore,
            powerUps: powerUpScore,
            levelCompletion: levelBonus,
            survivalBonus: survivalBonus,
            timeBonus: 0, // Would calculate based on speed
            total: finalScore
        )
    }
    
    private func getTimeBreakdown() -> TimeBreakdown {
        return TimeBreakdown(
            total: totalPlayTime,
            averagePerLevel: averageTimePerLevel,
            longestLevel: averageTimePerLevel * 1.5, // Estimate
            shortestLevel: averageTimePerLevel * 0.5, // Estimate
            menuTime: 0, // Would need to track
            playTime: totalPlayTime
        )
    }
    
    private func getPerformanceMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            accuracy: survivalRate,
            efficiency: efficiencyScore,
            consistency: 0.8, // Would calculate from level-to-level performance
            teamwork: teamworkScore,
            adaptability: 0.7, // Would measure how well adapted to different situations
            overall: Double(grade.rawValue) / 5.0
        )
    }
    
    // MARK: - Export Methods
    func exportToJSON() -> Data? {
        return try? JSONEncoder().encode(self)
    }
    
    func exportSummary() -> String {
        return """
        SpaceMaze Game Record
        Date: \(dateFormatted)
        Mode: \(gameMode.displayName)
        Players: \(playerNames.joined(separator: ", "))
        Score: \(String.formatScore(finalScore))
        Levels: \(levelsCompleted)
        Time: \(playTimeFormatted)
        Result: \(gameEndReason.displayMessage)
        Grade: \(grade.displayName)
        """
    }
}

// MARK: - Supporting Types
enum GameRecordMode: String, Codable {
    case singlePlayer = "single"
    case multiplayer = "multiplayer"
    
    var displayName: String {
        switch self {
        case .singlePlayer: return "Single Player"
        case .multiplayer: return "Multiplayer"
        }
    }
}

enum ConnectionQuality: String, Codable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "#00FF00"
        case .good: return "#90EE90"
        case .fair: return "#FFD700"
        case .poor: return "#FF6347"
        }
    }
}

enum GameGrade: Int, CaseIterable, Codable {
    case S = 5
    case A = 4
    case B = 3
    case C = 2
    case D = 1
    case F = 0
    
    var displayName: String {
        return String(describing: self)
    }
    
    var color: String {
        switch self {
        case .S: return "#FFD700" // Gold
        case .A: return "#C0C0C0" // Silver
        case .B: return "#CD7F32" // Bronze
        case .C: return "#90EE90" // Light Green
        case .D: return "#FFD700" // Yellow
        case .F: return "#FF6347" // Red
        }
    }
    
    var emoji: String {
        switch self {
        case .S: return "🏆"
        case .A: return "🥇"
        case .B: return "🥈"
        case .C: return "🥉"
        case .D: return "👍"
        case .F: return "😔"
        }
    }
}

struct PersonalBest: Codable {
    let category: PersonalBestCategory
    let value: Double
    let achievedAt: Date
    let gameRecordId: String
    
    var displayValue: String {
        switch category {
        case .highScore:
            return String.formatScore(Int(value))
        case .fastestCompletion:
            return String.durationString(from: value)
        case .mostLevels:
            return "\(Int(value)) levels"
        case .perfectRun:
            return value == 1.0 ? "Perfect!" : "Not achieved"
        case .teamwork:
            return String.formatPercentage(value)
        }
    }
}

enum PersonalBestCategory: String, CaseIterable, Codable {
    case highScore = "highScore"
    case fastestCompletion = "fastestCompletion"
    case mostLevels = "mostLevels"
    case perfectRun = "perfectRun"
    case teamwork = "teamwork"
    
    var displayName: String {
        switch self {
        case .highScore: return "High Score"
        case .fastestCompletion: return "Fastest Completion"
        case .mostLevels: return "Most Levels"
        case .perfectRun: return "Perfect Run"
        case .teamwork: return "Best Teamwork"
        }
    }
}

enum Achievement: String, CaseIterable, Codable {
    case scoreThousand = "score_1000"
    case scoreFiveThousand = "score_5000"
    case levelsFive = "levels_5"
    case levelsTen = "levels_10"
    case perfectLevel = "perfect_level"
    case teamPlayer = "team_player"
    case speedRunner = "speed_runner"
    
    var displayName: String {
        switch self {
        case .scoreThousand: return "Score Master"
        case .scoreFiveThousand: return "High Roller"
        case .levelsFive: return "Explorer"
        case .levelsTen: return "Adventurer"
        case .perfectLevel: return "Flawless"
        case .teamPlayer: return "Team Player"
        case .speedRunner: return "Speed Demon"
        }
    }
    
    var description: String {
        switch self {
        case .scoreThousand: return "Score 1,000 points in a single game"
        case .scoreFiveThousand: return "Score 5,000 points in a single game"
        case .levelsFive: return "Complete 5 levels in a single game"
        case .levelsTen: return "Complete 10 levels in a single game"
        case .perfectLevel: return "Complete a game without any deaths"
        case .teamPlayer: return "Complete a 4+ player game successfully"
        case .speedRunner: return "Complete a game in under 5 minutes"
        }
    }
    
    var iconName: String {
        return "achievement_\(rawValue)"
    }
}

// MARK: - Detailed Statistics
struct GameRecordStats {
    let record: GameRecord
    let scoringBreakdown: ScoringBreakdown
    let timeBreakdown: TimeBreakdown
    let performanceMetrics: PerformanceMetrics
}

struct ScoringBreakdown {
    let checkpoints: Int
    let powerUps: Int
    let levelCompletion: Int
    let survivalBonus: Int
    let timeBonus: Int
    let total: Int
    
    var breakdown: [(String, Int)] {
        return [
            ("Checkpoints", checkpoints),
            ("Power-ups", powerUps),
            ("Level Completion", levelCompletion),
            ("Survival Bonus", survivalBonus),
            ("Time Bonus", timeBonus)
        ]
    }
}

struct TimeBreakdown {
    let total: TimeInterval
    let averagePerLevel: TimeInterval
    let longestLevel: TimeInterval
    let shortestLevel: TimeInterval
    let menuTime: TimeInterval
    let playTime: TimeInterval
}

struct PerformanceMetrics {
    let accuracy: Double      // Survival rate
    let efficiency: Double    // Points per second
    let consistency: Double   // Performance variation
    let teamwork: Double      // Cooperation score
    let adaptability: Double  // How well handled different situations
    let overall: Double       // Combined metric
    
    var allMetrics: [(String, Double)] {
        return [
            ("Accuracy", accuracy),
            ("Efficiency", efficiency),
            ("Consistency", consistency),
            ("Teamwork", teamwork),
            ("Adaptability", adaptability),
            ("Overall", overall)
        ]
    }
}

// MARK: - GameRecord Extensions
extension GameRecord {
    
    // MARK: - Comparable
    static func < (lhs: GameRecord, rhs: GameRecord) -> Bool {
        // Primary sort by score, secondary by levels, tertiary by time
        if lhs.finalScore != rhs.finalScore {
            return lhs.finalScore > rhs.finalScore
        }
        if lhs.levelsCompleted != rhs.levelsCompleted {
            return lhs.levelsCompleted > rhs.levelsCompleted
        }
        return lhs.totalPlayTime < rhs.totalPlayTime
    }
    
    // MARK: - Equatable
    static func == (lhs: GameRecord, rhs: GameRecord) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - Array Extensions
extension Array where Element == GameRecord {
    
    func topScores(limit: Int = 10) -> [GameRecord] {
        return sorted { $0.finalScore > $1.finalScore }.prefix(limit).map { $0 }
    }
    
    func recentGames(limit: Int = 5) -> [GameRecord] {
        return sorted { $0.playedAt > $1.playedAt }.prefix(limit).map { $0 }
    }
    
    func multiplayerGames() -> [GameRecord] {
        return filter { $0.gameMode == .multiplayer }
    }
    
    func singlePlayerGames() -> [GameRecord] {
        return filter { $0.gameMode == .singlePlayer }
    }
    
    func completedGames() -> [GameRecord] {
        return filter { $0.wasSuccessful }
    }
    
    func getAverageScore() -> Double {
        guard !isEmpty else { return 0.0 }
        return Double(reduce(0) { $0 + $1.finalScore }) / Double(count)
    }
    
    func getAveragePlayTime() -> TimeInterval {
        guard !isEmpty else { return 0.0 }
        return reduce(0) { $0 + $1.totalPlayTime } / TimeInterval(count)
    }
    
    func getCompletionRate() -> Double {
        guard !isEmpty else { return 0.0 }
        let completed = completedGames().count
        return Double(completed) / Double(count)
    }
    
    func getStatsSummary() -> String {
        return """
        Games Played: \(count)
        Average Score: \(String.formatScore(Int(getAverageScore())))
        Average Time: \(String.durationString(from: getAveragePlayTime()))
        Completion Rate: \(String.formatPercentage(getCompletionRate()))
        Best Score: \(String.formatScore(topScores(limit: 1).first?.finalScore ?? 0))
        """
    }
}
