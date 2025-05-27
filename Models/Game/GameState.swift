//
//  GameState.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine

// MARK: - Game State
class GameState: ObservableObject, Codable {
    
    // MARK: - Published Properties
    @Published var players: [Player] = []
    @Published var currentLevel: Int = 1
    @Published var teamScore: Int = 0
    @Published var teamLives: Int = 5
    @Published var gameStatus: GameStatus = .waiting
    @Published var lastCheckpointId: String?
    @Published var completedCheckpoints: Set<String> = []
    @Published var isMultiplayer: Bool = false
    @Published var sessionId: String = ""
    @Published var gameCode: String = ""
    @Published var isHost: Bool = false
    @Published var mapOffset: CGPoint = .zero
    @Published var elapsedTime: TimeInterval = 0
    @Published var isPaused: Bool = false
    
    // MARK: - Non-Published Properties
    var gameStartTime: Date?
    var levelStartTime: Date?
    var cancellables = Set<AnyCancellable>()
    private var gameTimer: Timer?
    
    // MARK: - Initialization
    init() {
        setupBindings()
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case players, currentLevel, teamScore, teamLives, gameStatus
        case lastCheckpointId, completedCheckpoints, isMultiplayer
        case sessionId, gameCode, isHost, mapOffset, elapsedTime, isPaused
        case gameStartTime, levelStartTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        players = try container.decode([Player].self, forKey: .players)
        currentLevel = try container.decode(Int.self, forKey: .currentLevel)
        teamScore = try container.decode(Int.self, forKey: .teamScore)
        teamLives = try container.decode(Int.self, forKey: .teamLives)
        gameStatus = try container.decode(GameStatus.self, forKey: .gameStatus)
        lastCheckpointId = try container.decodeIfPresent(String.self, forKey: .lastCheckpointId)
        completedCheckpoints = try container.decode(Set<String>.self, forKey: .completedCheckpoints)
        isMultiplayer = try container.decode(Bool.self, forKey: .isMultiplayer)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        gameCode = try container.decode(String.self, forKey: .gameCode)
        isHost = try container.decode(Bool.self, forKey: .isHost)
        mapOffset = try container.decode(CGPoint.self, forKey: .mapOffset)
        elapsedTime = try container.decode(TimeInterval.self, forKey: .elapsedTime)
        isPaused = try container.decode(Bool.self, forKey: .isPaused)
        gameStartTime = try container.decodeIfPresent(Date.self, forKey: .gameStartTime)
        levelStartTime = try container.decodeIfPresent(Date.self, forKey: .levelStartTime)
        
        setupBindings()
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(players, forKey: .players)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(teamScore, forKey: .teamScore)
        try container.encode(teamLives, forKey: .teamLives)
        try container.encode(gameStatus, forKey: .gameStatus)
        try container.encode(lastCheckpointId, forKey: .lastCheckpointId)
        try container.encode(completedCheckpoints, forKey: .completedCheckpoints)
        try container.encode(isMultiplayer, forKey: .isMultiplayer)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(gameCode, forKey: .gameCode)
        try container.encode(isHost, forKey: .isHost)
        try container.encode(mapOffset, forKey: .mapOffset)
        try container.encode(elapsedTime, forKey: .elapsedTime)
        try container.encode(isPaused, forKey: .isPaused)
        try container.encode(gameStartTime, forKey: .gameStartTime)
        try container.encode(levelStartTime, forKey: .levelStartTime)
    }
    
    // MARK: - Setup
    private func setupBindings() {
        // Update team score when individual player scores change
        Publishers.MergeMany(players.map { $0.$score })
            .sink { [weak self] _ in
                self?.updateTeamScore()
            }
            .store(in: &cancellables)
        
        // Monitor team lives
        Publishers.MergeMany(players.map { $0.$lives })
            .sink { [weak self] _ in
                self?.updateTeamStatus()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Game Management
    func startGame(isMultiplayer: Bool = false, gameCode: String = "", isHost: Bool = false) {
        self.isMultiplayer = isMultiplayer
        self.gameCode = gameCode
        self.isHost = isHost
        self.sessionId = UUID().uuidString
        self.gameStartTime = Date()
        self.levelStartTime = Date()
        self.gameStatus = .playing
        self.teamLives = 5
        self.elapsedTime = 0
        
        startGameTimer()
        
        if isMultiplayer {
            print("🎮 Started multiplayer game with code: \(gameCode)")
        } else {
            print("🎮 Started single player game")
        }
    }
    
    func pauseGame() {
        isPaused = true
        gameStatus = .paused
        stopGameTimer()
    }
    
    func resumeGame() {
        isPaused = false
        gameStatus = .playing
        startGameTimer()
    }
    
    func endGame(reason: GameEndReason) {
        gameStatus = .ended
        stopGameTimer()
        
        // Save final score
        StorageManager.shared.addToTotalScore(teamScore)
        
        if teamScore > StorageManager.shared.getHighScore() {
            StorageManager.shared.saveHighScore(teamScore)
        }
        
        print("🏁 Game ended: \(reason.displayMessage)")
    }
    
    func resetGame() {
        players.forEach { $0.reset() }
        currentLevel = 1
        teamScore = 0
        teamLives = 5
        gameStatus = .waiting
        lastCheckpointId = nil
        completedCheckpoints.removeAll()
        mapOffset = .zero
        elapsedTime = 0
        isPaused = false
        gameStartTime = nil
        levelStartTime = nil
        stopGameTimer()
    }
    
    func resetForNewLevel() {
        players.forEach { player in
            player.position = .zero
            player.velocity = .zero
            player.isAlive = true
            player.respawnTimer = nil
            player.activePowerUps.removeAll()
        }
        
        completedCheckpoints.removeAll()
        lastCheckpointId = nil
        mapOffset = .zero
        levelStartTime = Date()
    }
    
    // MARK: - Player Management
    func addPlayer(_ player: Player) {
        guard !players.contains(where: { $0.id == player.id }) else { return }
        players.append(player)
        updateTeamScore()
        print("👤 Player added: \(player.displayName)")
    }
    
    func removePlayer(with id: String) {
        players.removeAll { $0.id == id }
        updateTeamScore()
        print("👤 Player removed: \(id)")
    }
    
    func getPlayer(with id: String) -> Player? {
        return players.first { $0.id == id }
    }
    
    func getLocalPlayer() -> Player? {
        return players.first { $0.isLocal }
    }
    
    func getMapMovers() -> [Player] {
        return players.filter { $0.playerType == .mapMover }
    }
    
    func getRegularPlayers() -> [Player] {
        return players.filter { $0.playerType == .regular }
    }
    
    func areAllPlayersReady() -> Bool {
        return !players.isEmpty && players.allSatisfy { $0.isReady }
    }
    
    func getAlivePlayers() -> [Player] {
        return players.filter { $0.isAlive }
    }
    
    func areAllPlayersDead() -> Bool {
        return !players.isEmpty && players.allSatisfy { !$0.isAlive }
    }
    
    // MARK: - Level Management
    func advanceToNextLevel() {
        currentLevel += 1
        levelStartTime = Date()
        resetForNewLevel()
        
        // Bonus points for completing level
        teamScore += 100 * currentLevel
        
        print("📈 Advanced to level \(currentLevel)")
    }
    
    func reachCheckpoint(_ checkpointId: String, by playerId: String) {
        guard !completedCheckpoints.contains(checkpointId) else { return }
        
        completedCheckpoints.insert(checkpointId)
        lastCheckpointId = checkpointId
        
        if let player = getPlayer(with: playerId) {
            player.reachCheckpoint(checkpointId)
        }
        
        teamScore += Constants.checkpointScore
        
        print("🏁 Checkpoint \(checkpointId) reached by \(playerId)")
    }
    
    func isLevelCompleted() -> Bool {
        // Level is completed when all alive players reach the finish
        let alivePlayers = getAlivePlayers()
        return !alivePlayers.isEmpty && alivePlayers.allSatisfy { player in
            // Check if player reached finish (this would be set by game scene)
            player.lastCheckpointId == "finish"
        }
    }
    
    // MARK: - Team Management
    func loseTeamLife() {
        teamLives = max(0, teamLives - 1)
        
        if teamLives <= 0 {
            endGame(reason: .allPlayersEliminated)
        }
    }
    
    func respawnAllPlayers() {
        guard let checkpointPosition = getLastCheckpointPosition() else { return }
        
        for player in players {
            if !player.isAlive {
                player.respawn(at: checkpointPosition)
            }
        }
    }
    
    func getLastCheckpointPosition() -> CGPoint? {
        // This would be implemented by the game scene to provide actual checkpoint positions
        return CGPoint(x: 96, y: 672)
    }
    
    // MARK: - Map Management
    func updateMapOffset(_ offset: CGPoint) {
        mapOffset = offset
    }
    
    func canMoveMap(for playerId: String) -> Bool {
        guard let player = getPlayer(with: playerId) else { return false }
        return player.playerType == .mapMover && player.isAlive
    }
    
    // MARK: - Private Methods
    private func updateTeamScore() {
        teamScore = players.reduce(0) { $0 + $1.score }
    }
    
    private func updateTeamStatus() {
        if areAllPlayersDead() && teamLives > 0 {
            loseTeamLife()
            if teamLives > 0 {
                // Respawn all players after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + Constants.defaultRespawnDelay) {
                    self.respawnAllPlayers()
                }
            }
        }
    }
    
    private func startGameTimer() {
        stopGameTimer()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPaused else { return }
            self.elapsedTime += 0.1
        }
    }
    
    private func stopGameTimer() {
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    // MARK: - Computed Properties
    var playersCount: Int {
        return players.count
    }
    
    var alivePlayersCount: Int {
        return getAlivePlayers().count
    }
    
    var mapMoversCount: Int {
        return getMapMovers().count
    }
    
    var regularPlayersCount: Int {
        return getRegularPlayers().count
    }
    
    var levelProgress: Double {
        // Simple progress based on completed checkpoints
        let totalCheckpoints = 4 // As mentioned in requirements
        return Double(completedCheckpoints.count) / Double(totalCheckpoints)
    }
    
    var gameTime: String {
        return String.timeString(from: elapsedTime)
    }
    
    var canStartGame: Bool {
        return playersCount >= Constants.minPlayersToStart && areAllPlayersReady()
    }
    
    // MARK: - Debug Info
    func getDebugInfo() -> String {
        return """
        Game State Debug:
        - Level: \(currentLevel)
        - Players: \(playersCount) (\(alivePlayersCount) alive)
        - Status: \(gameStatus)
        - Score: \(teamScore)
        - Lives: \(teamLives)
        - Checkpoints: \(completedCheckpoints.count)/4
        - Multiplayer: \(isMultiplayer)
        - Time: \(gameTime)
        """
    }
}

// MARK: - Game Status Enum
enum GameStatus: String, Codable, CaseIterable {
    case waiting = "waiting"
    case starting = "starting"
    case playing = "playing"
    case paused = "paused"
    case levelCompleted = "levelCompleted"
    case ended = "ended"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .waiting: return "Waiting for Players"
        case .starting: return "Starting Game"
        case .playing: return "Playing"
        case .paused: return "Paused"
        case .levelCompleted: return "Level Completed"
        case .ended: return "Game Over"
        case .error: return "Error"
        }
    }
    
    var isGameActive: Bool {
        return self == .playing
    }
    
    var canPause: Bool {
        return self == .playing
    }
    
    var canResume: Bool {
        return self == .paused
    }
}
