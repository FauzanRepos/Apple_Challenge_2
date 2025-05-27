//
//  SessionState.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - Session State Model
class SessionState: ObservableObject, Codable {
    
    // MARK: - Published Properties
    @Published var currentState: State = .notConnected
    @Published var gameCode: String = ""
    @Published var hostPlayer: NetworkPlayer?
    @Published var connectedPlayers: [NetworkPlayer] = []
    @Published var maxPlayers: Int = Constants.maxPlayersPerRoom
    @Published var isHost: Bool = false
    @Published var isReady: Bool = false
    @Published var gameStarted: Bool = false
    @Published var gamePaused: Bool = false
    @Published var currentLevel: Int = 1
    @Published var errorMessage: String?
    @Published var connectionAttempts: Int = 0
    @Published var lastConnectionAttempt: Date?
    
    // Session Metadata
    let sessionId: String
    let createdAt: Date
    var lastStateChange: Date
    var stateHistory: [StateTransition] = []
    
    // Game Progress
    @Published var teamScore: Int = 0
    @Published var teamLives: Int = 5
    @Published var completedCheckpoints: Set<String> = []
    @Published var activePowerUps: [String: Date] = [:]
    @Published var mapOffset: CGPoint = .zero
    
    // Network Quality
    @Published var overallNetworkQuality: NetworkQuality = .good
    @Published var averagePing: TimeInterval = 0
    @Published var syncStatus: SyncStatus = .synchronized
    @Published var messageQueueSize: Int = 0
    
    // Session Settings
    var allowLateJoin: Bool = true
    var autoStart: Bool = false
    var reconnectEnabled: Bool = true
    var maxReconnectAttempts: Int = 3
    var sessionTimeout: TimeInterval = 300 // 5 minutes
    
    // MARK: - Initialization
    init() {
        self.sessionId = UUID().uuidString
        self.createdAt = Date()
        self.lastStateChange = Date()
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case currentState, gameCode, hostPlayer, connectedPlayers, maxPlayers
        case isHost, isReady, gameStarted, gamePaused, currentLevel
        case errorMessage, connectionAttempts, lastConnectionAttempt
        case sessionId, createdAt, lastStateChange, stateHistory
        case teamScore, teamLives, completedCheckpoints, activePowerUps, mapOffset
        case overallNetworkQuality, averagePing, syncStatus, messageQueueSize
        case allowLateJoin, autoStart, reconnectEnabled, maxReconnectAttempts, sessionTimeout
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        currentState = try container.decode(State.self, forKey: .currentState)
        gameCode = try container.decode(String.self, forKey: .gameCode)
        hostPlayer = try container.decodeIfPresent(NetworkPlayer.self, forKey: .hostPlayer)
        connectedPlayers = try container.decode([NetworkPlayer].self, forKey: .connectedPlayers)
        maxPlayers = try container.decode(Int.self, forKey: .maxPlayers)
        isHost = try container.decode(Bool.self, forKey: .isHost)
        isReady = try container.decode(Bool.self, forKey: .isReady)
        gameStarted = try container.decode(Bool.self, forKey: .gameStarted)
        gamePaused = try container.decode(Bool.self, forKey: .gamePaused)
        currentLevel = try container.decode(Int.self, forKey: .currentLevel)
        errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
        connectionAttempts = try container.decode(Int.self, forKey: .connectionAttempts)
        lastConnectionAttempt = try container.decodeIfPresent(Date.self, forKey: .lastConnectionAttempt)
        sessionId = try container.decode(String.self, forKey: .sessionId)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastStateChange = try container.decode(Date.self, forKey: .lastStateChange)
        stateHistory = try container.decode([StateTransition].self, forKey: .stateHistory)
        teamScore = try container.decode(Int.self, forKey: .teamScore)
        teamLives = try container.decode(Int.self, forKey: .teamLives)
        completedCheckpoints = try container.decode(Set<String>.self, forKey: .completedCheckpoints)
        activePowerUps = try container.decode([String: Date].self, forKey: .activePowerUps)
        mapOffset = try container.decode(CGPoint.self, forKey: .mapOffset)
        overallNetworkQuality = try container.decode(NetworkQuality.self, forKey: .overallNetworkQuality)
        averagePing = try container.decode(TimeInterval.self, forKey: .averagePing)
        syncStatus = try container.decode(SyncStatus.self, forKey: .syncStatus)
        messageQueueSize = try container.decode(Int.self, forKey: .messageQueueSize)
        allowLateJoin = try container.decode(Bool.self, forKey: .allowLateJoin)
        autoStart = try container.decode(Bool.self, forKey: .autoStart)
        reconnectEnabled = try container.decode(Bool.self, forKey: .reconnectEnabled)
        maxReconnectAttempts = try container.decode(Int.self, forKey: .maxReconnectAttempts)
        sessionTimeout = try container.decode(TimeInterval.self, forKey: .sessionTimeout)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(currentState, forKey: .currentState)
        try container.encode(gameCode, forKey: .gameCode)
        try container.encode(hostPlayer, forKey: .hostPlayer)
        try container.encode(connectedPlayers, forKey: .connectedPlayers)
        try container.encode(maxPlayers, forKey: .maxPlayers)
        try container.encode(isHost, forKey: .isHost)
        try container.encode(isReady, forKey: .isReady)
        try container.encode(gameStarted, forKey: .gameStarted)
        try container.encode(gamePaused, forKey: .gamePaused)
        try container.encode(currentLevel, forKey: .currentLevel)
        try container.encode(errorMessage, forKey: .errorMessage)
        try container.encode(connectionAttempts, forKey: .connectionAttempts)
        try container.encode(lastConnectionAttempt, forKey: .lastConnectionAttempt)
        try container.encode(sessionId, forKey: .sessionId)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(lastStateChange, forKey: .lastStateChange)
        try container.encode(stateHistory, forKey: .stateHistory)
        try container.encode(teamScore, forKey: .teamScore)
        try container.encode(teamLives, forKey: .teamLives)
        try container.encode(completedCheckpoints, forKey: .completedCheckpoints)
        try container.encode(activePowerUps, forKey: .activePowerUps)
        try container.encode(mapOffset, forKey: .mapOffset)
        try container.encode(overallNetworkQuality, forKey: .overallNetworkQuality)
        try container.encode(averagePing, forKey: .averagePing)
        try container.encode(syncStatus, forKey: .syncStatus)
        try container.encode(messageQueueSize, forKey: .messageQueueSize)
        try container.encode(allowLateJoin, forKey: .allowLateJoin)
        try container.encode(autoStart, forKey: .autoStart)
        try container.encode(reconnectEnabled, forKey: .reconnectEnabled)
        try container.encode(maxReconnectAttempts, forKey: .maxReconnectAttempts)
        try container.encode(sessionTimeout, forKey: .sessionTimeout)
    }
    
    // MARK: - State Management
    func transitionTo(_ newState: State, reason: String = "") {
        let previousState = currentState
        currentState = newState
        lastStateChange = Date()
        
        // Record state transition
        let transition = StateTransition(
            from: previousState,
            to: newState,
            timestamp: lastStateChange,
            reason: reason
        )
        stateHistory.append(transition)
        
        // Keep only recent history (last 50 transitions)
        if stateHistory.count > 50 {
            stateHistory.removeFirst(stateHistory.count - 50)
        }
        
        print("🔄 Session state: \(previousState.rawValue) → \(newState.rawValue) (\(reason))")
        
        // Handle state-specific logic
        handleStateTransition(from: previousState, to: newState)
    }
    
    private func handleStateTransition(from: State, to: State) {
        switch to {
        case .notConnected:
            reset()
            
        case .searchingForGame:
            errorMessage = nil
            connectionAttempts += 1
            lastConnectionAttempt = Date()
            
        case .connecting:
            errorMessage = nil
            
        case .connected:
            connectionAttempts = 0
            errorMessage = nil
            
        case .hosting:
            isHost = true
            connectionAttempts = 0
            errorMessage = nil
            
        case .gameInProgress:
            gameStarted = true
            errorMessage = nil
            
        case .gameEnded:
            gameStarted = false
            gamePaused = false
            
        case .hostDisconnected:
            errorMessage = Constants.ErrorMessages.hostDisconnected
            
        case .connectionLost:
            errorMessage = Constants.ErrorMessages.networkError
            if reconnectEnabled && connectionAttempts < maxReconnectAttempts {
                scheduleReconnect()
            }
            
        case .error:
            break // Error message should be set separately
        }
    }
    
    func setError(_ message: String) {
        errorMessage = message
        if currentState != .error {
            transitionTo(.error, reason: message)
        }
    }
    
    func clearError() {
        errorMessage = nil
        if currentState == .error {
            transitionTo(.notConnected, reason: "Error cleared")
        }
    }
    
    private func scheduleReconnect() {
        let delay = min(pow(2.0, Double(connectionAttempts)), 30.0) // Exponential backoff, max 30s
        
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            
            if self.currentState == .connectionLost && self.connectionAttempts < self.maxReconnectAttempts {
                self.transitionTo(.connecting, reason: "Automatic reconnect attempt \(self.connectionAttempts + 1)")
            }
        }
    }
    
    // MARK: - Player Management
    func addPlayer(_ player: NetworkPlayer) {
        guard !connectedPlayers.contains(where: { $0.id == player.id }) else { return }
        guard connectedPlayers.count < maxPlayers else { return }
        
        connectedPlayers.append(player)
        updateNetworkQuality()
        
        if player.isHost {
            hostPlayer = player
        }
        
        print("👤 Player added: \(player.displayName) (\(connectedPlayers.count)/\(maxPlayers))")
    }
    
    func removePlayer(_ playerId: String) {
        connectedPlayers.removeAll { $0.id == playerId }
        updateNetworkQuality()
        
        // Check if removed player was host
        if hostPlayer?.id == playerId {
            hostPlayer = nil
            if !isHost {
                transitionTo(.hostDisconnected, reason: "Host left the game")
            }
        }
        
        print("👤 Player removed: \(playerId) (\(connectedPlayers.count)/\(maxPlayers))")
    }
    
    func updatePlayer(_ player: NetworkPlayer) {
        if let index = connectedPlayers.firstIndex(where: { $0.id == player.id }) {
            connectedPlayers[index] = player
            updateNetworkQuality()
        }
    }
    
    func getPlayer(with id: String) -> NetworkPlayer? {
        return connectedPlayers.first { $0.id == id }
    }
    
    func areAllPlayersReady() -> Bool {
        return !connectedPlayers.isEmpty && connectedPlayers.allSatisfy { $0.isReady }
    }
    
    func getReadyPlayerCount() -> Int {
        return connectedPlayers.filter { $0.isReady }.count
    }
    
    func canStartGame() -> Bool {
        return connectedPlayers.count >= Constants.minPlayersToStart && areAllPlayersReady()
    }
    
    // MARK: - Game State Updates
    func updateGameProgress(score: Int, lives: Int, level: Int) {
        teamScore = score
        teamLives = lives
        currentLevel = level
    }
    
    func addCompletedCheckpoint(_ checkpointId: String) {
        completedCheckpoints.insert(checkpointId)
    }
    
    func activatePowerUp(_ powerUpId: String) {
        activePowerUps[powerUpId] = Date()
    }
    
    func updateMapOffset(_ offset: CGPoint) {
        mapOffset = offset
    }
    
    func pauseGame() {
        gamePaused = true
    }
    
    func resumeGame() {
        gamePaused = false
    }
    
    func advanceToNextLevel() {
        currentLevel += 1
        completedCheckpoints.removeAll()
        activePowerUps.removeAll()
        mapOffset = .zero
    }
    
    // MARK: - Network Quality Management
    private func updateNetworkQuality() {
        guard !connectedPlayers.isEmpty else {
            overallNetworkQuality = .good
            averagePing = 0
            return
        }
        
        // Calculate average ping
        let totalPing = connectedPlayers.reduce(0) { $0 + $1.ping }
        averagePing = totalPing / Double(connectedPlayers.count)
        
        // Determine overall quality based on worst connection
        let qualities = connectedPlayers.map { $0.connectionQuality }
        if qualities.contains(.terrible) {
            overallNetworkQuality = .terrible
        } else if qualities.contains(.poor) {
            overallNetworkQuality = .poor
        } else if qualities.contains(.fair) {
            overallNetworkQuality = .fair
        } else if qualities.contains(.good) {
            overallNetworkQuality = .good
        } else {
            overallNetworkQuality = .excellent
        }
        
        // Update sync status
        updateSyncStatus()
    }
    
    private func updateSyncStatus() {
        let maxSyncLag = connectedPlayers.map { $0.syncLag }.max() ?? 0
        
        switch maxSyncLag {
        case 0..<0.1:
            syncStatus = .synchronized
        case 0.1..<0.3:
            syncStatus = .slightDelay
        case 0.3..<0.5:
            syncStatus = .moderate
        default:
            syncStatus = .desynchronized
        }
    }
    
    func updateMessageQueueSize(_ size: Int) {
        messageQueueSize = size
    }
    
    // MARK: - Session Validation
    func isSessionValid() -> Bool {
        let age = Date().timeIntervalSince(createdAt)
        return age < sessionTimeout
    }
    
    func isExpired() -> Bool {
        return !isSessionValid()
    }
    
    func getTimeRemaining() -> TimeInterval {
        let age = Date().timeIntervalSince(createdAt)
        return max(0, sessionTimeout - age)
    }
    
    // MARK: - Reset and Cleanup
    func reset() {
        connectedPlayers.removeAll()
        hostPlayer = nil
        gameCode = ""
        isHost = false
        isReady = false
        gameStarted = false
        gamePaused = false
        currentLevel = 1
        errorMessage = nil
        connectionAttempts = 0
        lastConnectionAttempt = nil
        teamScore = 0
        teamLives = 5
        completedCheckpoints.removeAll()
        activePowerUps.removeAll()
        mapOffset = .zero
        overallNetworkQuality = .good
        averagePing = 0
        syncStatus = .synchronized
        messageQueueSize = 0
    }
    
    // MARK: - Computed Properties
    var sessionAge: TimeInterval {
        return Date().timeIntervalSince(createdAt)
    }
    
    var timeSinceLastStateChange: TimeInterval {
        return Date().timeIntervalSince(lastStateChange)
    }
    
    var playerCount: Int {
        return connectedPlayers.count
    }
    
    var isFull: Bool {
        return connectedPlayers.count >= maxPlayers
    }
    
    var hasSpace: Bool {
        return connectedPlayers.count < maxPlayers
    }
    
    var connectionSummary: String {
        return "\(connectedPlayers.count)/\(maxPlayers) players • \(getReadyPlayerCount()) ready"
    }
    
    var networkSummary: String {
        return "\(overallNetworkQuality.displayName) • \(Int(averagePing * 1000))ms avg • \(syncStatus.displayName)"
    }
    
    var canJoinGame: Bool {
        return hasSpace && (allowLateJoin || !gameStarted) && currentState.canAcceptPlayers
    }
    
    var statusDescription: String {
        switch currentState {
        case .notConnected:
            return "Not connected to any game"
        case .searchingForGame:
            return "Searching for game with code: \(gameCode)"
        case .connecting:
            return "Connecting to game..."
        case .connected:
            return "Connected • \(connectionSummary)"
        case .hosting:
            return "Hosting game • Code: \(gameCode) • \(connectionSummary)"
        case .gameInProgress:
            return "Game in progress • Level \(currentLevel) • \(teamLives) lives"
        case .gameEnded:
            return "Game ended • Final score: \(teamScore)"
        case .hostDisconnected:
            return "Host disconnected from the game"
        case .connectionLost:
            return "Connection lost • Attempting to reconnect..."
        case .error:
            return errorMessage ?? "Unknown error occurred"
        }
    }
    
    // MARK: - Debug Information
    func getDebugInfo() -> String {
        return """
        Session Debug Info:
        - ID: \(sessionId)
        - State: \(currentState.rawValue)
        - Age: \(String.durationString(from: sessionAge))
        - Code: \(gameCode.isEmpty ? "None" : gameCode)
        - Players: \(playerCount)/\(maxPlayers)
        - Host: \(isHost ? "Yes" : "No")
        - Game Started: \(gameStarted)
        - Level: \(currentLevel)
        - Network: \(networkSummary)
        - Last Transition: \(String.durationString(from: timeSinceLastStateChange)) ago
        """
    }
    
    func getStateHistory() -> String {
        let recentTransitions = Array(stateHistory.suffix(10))
        return recentTransitions.map { transition in
            let timeAgo = String.durationString(from: Date().timeIntervalSince(transition.timestamp))
            return "\(transition.from.rawValue) → \(transition.to.rawValue) (\(timeAgo) ago)"
        }.joined(separator: "\n")
    }
}

// MARK: - Supporting Types
enum State: String, Codable, CaseIterable {
    case notConnected = "notConnected"
    case searchingForGame = "searchingForGame"
    case connecting = "connecting"
    case connected = "connected"
    case hosting = "hosting"
    case gameInProgress = "gameInProgress"
    case gameEnded = "gameEnded"
    case hostDisconnected = "hostDisconnected"
    case connectionLost = "connectionLost"
    case error = "error"
    
    var displayName: String {
        switch self {
        case .notConnected: return "Not Connected"
        case .searchingForGame: return "Searching"
        case .connecting: return "Connecting"
        case .connected: return "Connected"
        case .hosting: return "Hosting"
        case .gameInProgress: return "Playing"
        case .gameEnded: return "Game Over"
        case .hostDisconnected: return "Host Disconnected"
        case .connectionLost: return "Connection Lost"
        case .error: return "Error"
        }
    }
    
    var canAcceptPlayers: Bool {
        switch self {
        case .hosting, .connected:
            return true
        default:
            return false
        }
    }
    
    var isConnected: Bool {
        switch self {
        case .connected, .hosting, .gameInProgress:
            return true
        default:
            return false
        }
    }
    
    var isGameActive: Bool {
        return self == .gameInProgress
    }
    
    var allowsStateTransitions: Bool {
        return self != .error
    }
}

enum SyncStatus: String, Codable, CaseIterable {
    case synchronized = "synchronized"
    case slightDelay = "slightDelay"
    case moderate = "moderate"
    case desynchronized = "desynchronized"
    
    var displayName: String {
        switch self {
        case .synchronized: return "Synchronized"
        case .slightDelay: return "Slight Delay"
        case .moderate: return "Moderate Lag"
        case .desynchronized: return "Desynchronized"
        }
    }
    
    var color: String {
        switch self {
        case .synchronized: return "#00FF00"
        case .slightDelay: return "#FFFF00"
        case .moderate: return "#FFA500"
        case .desynchronized: return "#FF0000"
        }
    }
    
    var isGood: Bool {
        return self == .synchronized || self == .slightDelay
    }
}

struct StateTransition: Codable {
    let from: State
    let to: State
    let timestamp: Date
    let reason: String
    
    var duration: TimeInterval {
        return Date().timeIntervalSince(timestamp)
    }
}

// MARK: - SessionState Extensions
extension SessionState {
    
    // MARK: - Convenience Methods
    func createGame(with code: String) {
        gameCode = code
        isHost = true
        transitionTo(.hosting, reason: "Game created with code: \(code)")
    }
    
    func joinGame(with code: String) {
        gameCode = code
        isHost = false
        transitionTo(.searchingForGame, reason: "Searching for game: \(code)")
    }
    
    func startGame() {
        guard canStartGame() else { return }
        transitionTo(.gameInProgress, reason: "Game started with \(playerCount) players")
    }
    
    func endGame(reason: GameEndReason) {
        transitionTo(.gameEnded, reason: "Game ended: \(reason.rawValue)")
    }
    
    func disconnect() {
        transitionTo(.notConnected, reason: "Manual disconnect")
    }
    
    func connectionFailed(error: String) {
        setError(error)
    }
    
    func hostLeft() {
        transitionTo(.hostDisconnected, reason: "Host left the session")
    }
    
    func connectionLost() {
        transitionTo(.connectionLost, reason: "Network connection lost")
    }
}

// MARK: - SessionState Factory
struct SessionStateFactory {
    
    static func createHostSession(gameCode: String, maxPlayers: Int = Constants.maxPlayersPerRoom) -> SessionState {
        let session = SessionState()
        session.gameCode = gameCode
        session.maxPlayers = maxPlayers
        session.isHost = true
        session.transitionTo(.hosting, reason: "Created as host")
        return session
    }
    
    static func createClientSession(gameCode: String) -> SessionState {
        let session = SessionState()
        session.gameCode = gameCode
        session.isHost = false
        session.transitionTo(.searchingForGame, reason: "Created as client")
        return session
    }
    
    static func createTestSession(playerCount: Int = 4) -> SessionState {
        let session = SessionState()
        session.gameCode = "TEST01"
        session.isHost = true
        session.transitionTo(.hosting, reason: "Test session")
        
        // Add test players
        let testPlayers = NetworkPlayerFactory.createTestPlayers(count: playerCount)
        testPlayers.forEach { session.addPlayer($0) }
        
        return session
    }
}
