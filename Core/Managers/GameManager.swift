//
//  GameManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import Combine
import SwiftUI
import SpriteKit

enum GameAlert {
    case none
    case gameOver
    case respawn
}

/// Main game state manager. Handles global game status, level flow, lives, score, and checkpoint progression.
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // MARK: - Published Properties
    @Published var currentLevel: Int = 1
    @Published var maxLevel: Int = 2
    @Published var currentPlanet: Int = 1
    @Published var section: Int = 1 // checkpoint section 1...4
    @Published var totalSections: Int = 4
    @Published var teamLives: Int = 5
    @Published var scoreText: String = "Planet 1 Section 1/4"
    @Published var isGameOver: Bool = false
    @Published var isMissionAccomplished: Bool = false
    @Published var isPaused: Bool = false
    @Published var pausedByPlayerID: String? = nil
    @Published var resumeCountdownActive: Bool = false
    @Published var resumeCountdownValue: Int = 3
    @Published var missionClue: String = ""
    @Published var lastCheckpoint: CGPoint? = nil
    @Published var mapMoverPlayerID: String? = nil // player id of mapMover
    @Published var playersFinished: Set<String> = [] // ids of players in spaceship
    @Published var currentAlert: GameAlert = .none
    @Published var showSettings = false
    @Published private(set) var scene: GameScene?
    
    // For checkpoint tracking
    @Published var reachedCheckpoints: Set<Int> = []
    
    // GameCode Generator
    public let gameCode = GameCodeManager.shared
    
    // Reference to current GameScene for camera control
    private weak var currentGameScene: GameScene?
    
    private init() {
        // Initialize with basic properties only
        updateScoreText()
        updateMissionClue()
    }
    
    // MARK: - Scene Management
    func setupScene() {
        // Only create scene if it doesn't exist
        guard scene == nil else { return }
        
        // Create scene with safe screen size
        let screenSize = UIScreen.main.bounds.size
        let scene = GameScene(size: screenSize)
        scene.scaleMode = .aspectFill
        self.scene = scene
        self.currentGameScene = scene
    }
    
    func setCurrentGameScene(_ scene: GameScene) {
        currentGameScene = scene
        self.scene = scene
    }
    
    // MARK: - Level/Section Management
    func startGame() {
        print("[GameManager] Starting game...")
        resetGame()
        print("[GameManager] Loading level 1...")
        loadLevel(1)
        assignMapMoverRoles()
        print("[GameManager] Game start complete")
    }
    
    func loadLevel(_ level: Int) {
        print("[GameManager] Loading level \(level)...")
        currentLevel = level
        currentPlanet = level // 1-to-1 mapping for now
        section = 1
        teamLives = 5
        reachedCheckpoints = []
        playersFinished = []
        isGameOver = false
        isMissionAccomplished = false
        isPaused = false
        updateScoreText()
        updateMissionClue()
        
        // Reset scene
        setupScene()
        
        // Load level data
        print("[GameManager] Calling LevelManager to load level data...")
        LevelManager.shared.loadLevel(level)
        
        // Verify level data was loaded
        guard let levelData = LevelManager.shared.currentLevelData else {
            print("[GameManager] ERROR: Failed to load level data")
            return
        }
        print("[GameManager] Level data loaded successfully: \(String(describing: levelData))")
        
        // Initialize lastCheckpoint with spawn point
        lastCheckpoint = levelData.spawn
        print("[GameManager] Initialized lastCheckpoint with spawn point: \(levelData.spawn)")
    }
    
    func reachCheckpoint(_ sectionIdx: Int) {
        reachedCheckpoints.insert(sectionIdx)
        section = max(section, sectionIdx)
        updateScoreText()
        
        print("[GameManager] Checkpoint \(sectionIdx) reached. Current section: \(section)")
    }
    
    func playerFinished(playerID: String) {
        playersFinished.insert(playerID)
        let totalPlayers = MultipeerManager.shared.players.count
        
        print("[GameManager] Player finished: \(playersFinished.count)/\(totalPlayers)")
        
        if playersFinished.count == totalPlayers {
            missionAccomplished()
        }
    }
    
    /// Lose a team life and broadcast to all players
    func loseLifeAndSync() {
        teamLives = max(0, teamLives - 1)
        PlayerSyncManager.shared.broadcastTeamLives(teamLives)
        
        if teamLives == 0 {
            isGameOver = true
            print("[GameManager] Game Over - No lives remaining")
        } else {
            print("[GameManager] Team lives remaining: \(teamLives)")
        }
    }
    
    /// Set team lives directly (for multiplayer sync)
    func setTeamLives(_ lives: Int) {
        teamLives = max(0, lives)
        if teamLives == 0 {
            isGameOver = true
        }
    }
    
    func missionAccomplished() {
        isMissionAccomplished = true
        
        // Save high score
        StorageManager.shared.saveHighScoreIfNeeded(currentLevel, section: section)
        
        print("[GameManager] Mission Accomplished! Level \(currentLevel) completed")
    }
    
    func pauseGame(_ pause: Bool) {
        isPaused = pause
    }
    
    func resetGame() {
        currentLevel = 1
        currentPlanet = 1
        section = 1
        teamLives = 5
        reachedCheckpoints = []
        playersFinished = []
        isGameOver = false
        isMissionAccomplished = false
        isPaused = false
        pausedByPlayerID = nil
        resumeCountdownActive = false
        lastCheckpoint = nil
        updateScoreText()
        updateMissionClue()
        currentAlert = .none
        showSettings = false
    }
    
    func updateScoreText() {
        scoreText = "Planet \(currentPlanet) Section \(section)/\(totalSections)"
    }
    
    func updateMissionClue() {
        switch currentLevel {
        case 1:
            missionClue = "Find the space station!"
        case 2:
            missionClue = "Navigate the asteroid field!"
        default:
            missionClue = "Reach the destination!"
        }
    }
    
    // MARK: - Pause/Resume System
    func pauseGame(by playerID: String) {
        isPaused = true
        pausedByPlayerID = playerID
        resumeCountdownActive = false
        
        print("[GameManager] Game paused by player: \(playerID)")
    }
    
    func resumeGameWithCountdown(by playerID: String) {
        guard pausedByPlayerID == playerID else { return }
        resumeCountdownActive = true
        resumeCountdownValue = 3
        countdownResume()
        
        print("[GameManager] Resume countdown started by player: \(playerID)")
    }
    
    private func countdownResume() {
        if resumeCountdownValue > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                guard let self = self else { return }
                self.resumeCountdownValue -= 1
                self.countdownResume()
            }
        } else {
            isPaused = false
            pausedByPlayerID = nil
            resumeCountdownActive = false
            print("[GameManager] Game resumed")
        }
    }
    
    // MARK: - Event Handling
    func handleGameEvent(_ event: GameEvent) {
        switch event.type {
        case .checkpointReached:
            if let section = event.section {
                reachCheckpoint(section)
            }
        case .missionAccomplished:
            missionAccomplished()
        case .missionFailed:
            isGameOver = true
        case .playerDeath:
            if let lives = event.section {
                setTeamLives(lives)
            }
        default:
            break // pause/resume handled in PlayerSyncManager
        }
    }
    
    // MARK: - Map Mover Role Assignment
    func assignMapMoverRoles() {
        var players = MultipeerManager.shared.players
        let playerCount = players.count
        let allEdges: [EdgeRole] = [.top, .left, .bottom, .right]
        
        // Clear all assignments
        for player in players {
            player.assignedEdge = nil
        }
        
        if playerCount == 1 {
            players[0].assignedEdge = allEdges.randomElement()
        }
        
        if playerCount == 2 {
            // Only one mapMover, one normal
            let randomIdx = Int.random(in: 0..<2)
            players[randomIdx].assignedEdge = allEdges.randomElement()
            // other player remains nil (normal)
        } else if playerCount >= 3 && playerCount <= 5 {
            // Assign up to 4 edges (as available, shuffled)
            let edgeAssignments = Array(allEdges.shuffled().prefix(playerCount))
            for (idx, player) in players.enumerated() {
                if idx < edgeAssignments.count {
                    player.assignedEdge = edgeAssignments[idx]
                }
            }
            // If 5 players, the fifth gets nil (normal)
            if playerCount == 5 {
                players[4].assignedEdge = nil
            }
        } else if playerCount > 5 {
            // Assign only 4 mapMovers (one per edge), others normal
            let moverIndices = Array(0..<playerCount).shuffled().prefix(4)
            let edgeAssignments = allEdges.shuffled()
            for (edgeIdx, playerIdx) in moverIndices.enumerated() {
                players[playerIdx].assignedEdge = edgeAssignments[edgeIdx]
            }
            // Others remain nil (normal)
        }
        
        // Broadcast role assignments
        PlayerSyncManager.shared.broadcastAllPlayerUpdates(players)
        
        print("[GameManager] Map mover roles assigned for \(playerCount) players")
    }
    
    // MARK: - Camera Control (Fixed Implementation)
    func setCameraPosition(_ position: CGPoint) {
        // Use the GameScene reference instead of deprecated UIApplication.shared.windows
        currentGameScene?.setCameraPosition(position)
    }
    
    // Alert handling
    func showRespawnAlert() {
        print("⚠️ [GameManager] Showing respawn alert")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("🎯 [GameManager] Setting alert to respawn")
            withAnimation {
                self.currentAlert = .respawn
            }
            self.objectWillChange.send()
            print("🎯 [GameManager] Alert state updated to: \(self.currentAlert)")
        }
    }
    
    func showGameOverAlert() {
        print("⚠️ [GameManager] Showing game over alert")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("🎯 [GameManager] Setting alert to game over")
            withAnimation {
                self.currentAlert = .gameOver
            }
            self.objectWillChange.send()
            print("🎯 [GameManager] Alert state updated to: \(self.currentAlert)")
        }
    }
    
    func dismissAlert() {
        print("✅ [GameManager] Dismissing alert")
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            print("🎯 [GameManager] Setting alert to none")
            withAnimation {
                self.currentAlert = .none
            }
            self.objectWillChange.send()
            print("🎯 [GameManager] Alert state updated to: \(self.currentAlert)")
        }
    }
    
    func quitToHome() {
        // Clean up game state
        teamLives = Constants.defaultPlayerLives
        reachedCheckpoints.removeAll()
        playersFinished.removeAll()
        currentLevel = 1
        scoreText = "Planet 1 Section 1/4"
        dismissAlert()
        // Additional cleanup as needed
    }
    
    func respawnPlayer() {
        print("🔄 [GameManager] Respawning player")
        CollisionManager.shared.respawnAllPlayers()
        dismissAlert()
    }
    
    // MARK: - Settings Methods
    func toggleSettings() {
        showSettings.toggle()
    }
}
