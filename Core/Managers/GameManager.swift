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

/// Main game state manager. Handles global game status, level flow, lives, score, and checkpoint progression.
final class GameManager: ObservableObject {
    static let shared = GameManager()
    
    // MARK: - Published State
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
    
    // For checkpoint tracking
    @Published var reachedCheckpoints: Set<Int> = []
    
    private init() {}
    
    // MARK: - Level/Section Management
    func startGame() {
        resetGame()
        loadLevel(1)
    }
    
    func loadLevel(_ level: Int) {
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
        // Additional setup will be triggered by LevelManager
    }
    
    func reachCheckpoint(_ sectionIdx: Int) {
        reachedCheckpoints.insert(sectionIdx)
        section = max(section, sectionIdx)
        updateScoreText()
    }
    
    func playerFinished(playerID: String) {
        playersFinished.insert(playerID)
        if playersFinished.count == MultipeerManager.shared.players.count {
            missionAccomplished()
        }
    }
    
    func loseLife() {
        teamLives = max(0, teamLives - 1)
        if teamLives == 0 {
            isGameOver = true
        }
    }
    
    func missionAccomplished() {
        isMissionAccomplished = true
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
        updateScoreText()
    }
    
    func updateScoreText() {
        scoreText = "Planet \(currentPlanet) Section \(section)/\(totalSections)"
    }
    
    func pauseGame(by playerID: String) {
        isPaused = true
        pausedByPlayerID = playerID
        resumeCountdownActive = false
    }
    
    func resumeGameWithCountdown(by playerID: String) {
        guard pausedByPlayerID == playerID else { return }
        resumeCountdownActive = true
        resumeCountdownValue = 3
        countdownResume()
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
        }
    }
    
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
        default:
            break // already handled pause/resume in PlayerSyncManager
        }
    }
    
    // Randomly assigns mapMover roles according to the rules
    func assignMapMoverRoles() {
        var players = MultipeerManager.shared.players
        let playerCount = players.count
        let allEdges: [EdgeRole] = [.top, .left, .bottom, .right]
        
        // Clear all assignments
        for player in players { player.assignedEdge = nil }
        
        if playerCount == 2 {
            // Only one mapMover, one normal
            let randomIdx = Int.random(in: 0..<2)
            players[randomIdx].assignedEdge = allEdges.randomElement()
            // other player remains nil (normal)
        } else if playerCount >= 3 && playerCount <= 5 {
            // Assign up to 4 edges (as available, shuffled)
            let edgeAssignments = Array(allEdges.shuffled().prefix(playerCount))
            for (idx, player) in players.enumerated() {
                player.assignedEdge = edgeAssignments[idx]
            }
            // If 5 players, the fifth gets nil (normal)
            if playerCount == 5 {
                players[4].assignedEdge = nil
            }
        } else if playerCount > 5 {
            // Assign only 4 mapMovers (one per edge), others normal
            let moverIdxs = Array(0..<playerCount).shuffled().prefix(4)
            let edgeAssignments = allEdges.shuffled()
            for (edgeIdx, playerIdx) in moverIdxs.enumerated() {
                players[playerIdx].assignedEdge = edgeAssignments[edgeIdx]
            }
            // Others remain nil (normal)
        }
        // Save back
        MultipeerManager.shared.players = players
        // Sync roles
        PlayerSyncManager.shared.broadcastAllPlayerUpdates(players)
    }
}
