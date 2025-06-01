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
}
