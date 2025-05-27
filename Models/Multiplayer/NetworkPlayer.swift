//
//  NetworkPlayer.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import MultipeerConnectivity
import CoreGraphics

// MARK: - Network Player Model
class NetworkPlayer: ObservableObject, Identifiable, Codable {
    
    let id: String
    let peerID: MCPeerID
    
    @Published var name: String
    @Published var isHost: Bool
    @Published var isReady: Bool
    @Published var playerType: PlayerType
    @Published var connectionState: PlayerConnectionState
    @Published var score: Int
    @Published var lives: Int
    @Published var position: CGPoint
    @Published var velocity: CGVector
    @Published var lastSeen: Date
    @Published var ping: TimeInterval
    @Published var isLocal: Bool
    
    // Network Statistics
    @Published var messagesSent: Int
    @Published var messagesReceived: Int
    @Published var bytesTransferred: Int64
    @Published var connectionQuality: NetworkQuality
    @Published var syncLag: TimeInterval
    
    // Game State Sync
    var lastPositionUpdate: Date
    var pendingUpdates: [PlayerUpdate]
    var predictedPosition: CGPoint
    var interpolationBuffer: [PositionData]
    
    // Player Metadata
    let deviceInfo: DeviceInfo
    let joinedAt: Date
    var lastActiveAt: Date
    var sessionDuration: TimeInterval {
        return Date().timeIntervalSince(joinedAt)
    }
    
    // MARK: - Initialization
    init(
        id: String,
        name: String,
        peerID: MCPeerID,
        isHost: Bool = false,
        isReady: Bool = false,
        playerType: PlayerType = .regular,
        isLocal: Bool = false
    ) {
        self.id = id
        self.name = name
        self.peerID = peerID
        self.isHost = isHost
        self.isReady = isReady
        self.playerType = playerType
        self.isLocal = isLocal
        
        // Initialize published properties
        self.connectionState = .connecting
        self.score = 0
        self.lives = Constants.defaultPlayerLives
        self.position = CGPoint.zero
        self.velocity = CGVector.zero
        self.lastSeen = Date()
        self.ping = 0
        
        // Network stats
        self.messagesSent = 0
        self.messagesReceived = 0
        self.bytesTransferred = 0
        self.connectionQuality = .good
        self.syncLag = 0
        
        // Sync data
        self.lastPositionUpdate = Date()
        self.pendingUpdates = []
        self.predictedPosition = CGPoint.zero
        self.interpolationBuffer = []
        
        // Metadata
        self.deviceInfo = DeviceInfo()
        self.joinedAt = Date()
        self.lastActiveAt = Date()
    }
    
    // MARK: - Codable Implementation
    enum CodingKeys: String, CodingKey {
        case id, name, isHost, isReady, playerType, connectionState
        case score, lives, position, velocity, lastSeen, ping, isLocal
        case messagesSent, messagesReceived, bytesTransferred
        case connectionQuality, syncLag, deviceInfo, joinedAt, lastActiveAt
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isHost = try container.decode(Bool.self, forKey: .isHost)
        isReady = try container.decode(Bool.self, forKey: .isReady)
        playerType = try container.decode(PlayerType.self, forKey: .playerType)
        connectionState = try container.decode(PlayerConnectionState.self, forKey: .connectionState)
        score = try container.decode(Int.self, forKey: .score)
        lives = try container.decode(Int.self, forKey: .lives)
        position = try container.decode(CGPoint.self, forKey: .position)
        velocity = try container.decode(CGVector.self, forKey: .velocity)
        lastSeen = try container.decode(Date.self, forKey: .lastSeen)
        ping = try container.decode(TimeInterval.self, forKey: .ping)
        isLocal = try container.decode(Bool.self, forKey: .isLocal)
        messagesSent = try container.decode(Int.self, forKey: .messagesSent)
        messagesReceived = try container.decode(Int.self, forKey: .messagesReceived)
        bytesTransferred = try container.decode(Int64.self, forKey: .bytesTransferred)
        connectionQuality = try container.decode(NetworkQuality.self, forKey: .connectionQuality)
        syncLag = try container.decode(TimeInterval.self, forKey: .syncLag)
        deviceInfo = try container.decode(DeviceInfo.self, forKey: .deviceInfo)
        joinedAt = try container.decode(Date.self, forKey: .joinedAt)
        lastActiveAt = try container.decode(Date.self, forKey: .lastActiveAt)
        
        // Initialize non-codable properties
        self.peerID = MCPeerID(displayName: id)
        self.lastPositionUpdate = Date()
        self.pendingUpdates = []
        self.predictedPosition = position
        self.interpolationBuffer = []
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isHost, forKey: .isHost)
        try container.encode(isReady, forKey: .isReady)
        try container.encode(playerType, forKey: .playerType)
        try container.encode(connectionState, forKey: .connectionState)
        try container.encode(score, forKey: .score)
        try container.encode(lives, forKey: .lives)
        try container.encode(position, forKey: .position)
        try container.encode(velocity, forKey: .velocity)
        try container.encode(lastSeen, forKey: .lastSeen)
        try container.encode(ping, forKey: .ping)
        try container.encode(isLocal, forKey: .isLocal)
        try container.encode(messagesSent, forKey: .messagesSent)
        try container.encode(messagesReceived, forKey: .messagesReceived)
        try container.encode(bytesTransferred, forKey: .bytesTransferred)
        try container.encode(connectionQuality, forKey: .connectionQuality)
        try container.encode(syncLag, forKey: .syncLag)
        try container.encode(deviceInfo, forKey: .deviceInfo)
        try container.encode(joinedAt, forKey: .joinedAt)
        try container.encode(lastActiveAt, forKey: .lastActiveAt)
    }
    
    // MARK: - Connection Management
    func updateConnectionState(_ state: PlayerConnectionState) {
        connectionState = state
        lastActiveAt = Date()
    }
    
    func markAsActive() {
        lastSeen = Date()
        lastActiveAt = Date()
    }
    
    func updatePing(_ newPing: TimeInterval) {
        // Smooth ping using exponential moving average
        ping = ping * 0.8 + newPing * 0.2
        updateConnectionQuality()
    }
    
    private func updateConnectionQuality() {
        switch ping {
        case 0..<0.05:      connectionQuality = .excellent
        case 0.05..<0.15:   connectionQuality = .good
        case 0.15..<0.3:    connectionQuality = .fair
        case 0.3..<0.5:     connectionQuality = .poor
        default:            connectionQuality = .terrible
        }
    }
    
    func isConnected() -> Bool {
        return connectionState == .connected
    }
    
    func isActiveRecently(within timeInterval: TimeInterval = 5.0) -> Bool {
        return Date().timeIntervalSince(lastSeen) <= timeInterval
    }
    
    func getTimeSinceLastSeen() -> TimeInterval {
        return Date().timeIntervalSince(lastSeen)
    }
    
    // MARK: - Position and Movement
    func updatePosition(_ newPosition: CGPoint, velocity newVelocity: CGVector, timestamp: Date = Date()) {
        // Add to interpolation buffer
        let positionData = PositionData(
            position: newPosition,
            velocity: newVelocity,
            timestamp: timestamp
        )
        
        interpolationBuffer.append(positionData)
        
        // Keep only recent data (last 1 second)
        let cutoffTime = timestamp.addingTimeInterval(-1.0)
        interpolationBuffer = interpolationBuffer.filter { $0.timestamp >= cutoffTime }
        
        // Update current position
        position = newPosition
        velocity = newVelocity
        lastPositionUpdate = timestamp
        
        // Update predicted position
        updatePredictedPosition()
        
        markAsActive()
    }
    
    private func updatePredictedPosition() {
        let timeSinceUpdate = Date().timeIntervalSince(lastPositionUpdate)
        predictedPosition = CGPoint(
            x: position.x + velocity.dx * timeSinceUpdate,
            y: position.y + velocity.dy * timeSinceUpdate
        )
    }
    
    func getInterpolatedPosition(at targetTime: Date) -> CGPoint {
        guard interpolationBuffer.count >= 2 else { return position }
        
        // Find two positions to interpolate between
        let sortedData = interpolationBuffer.sorted { $0.timestamp < $1.timestamp }
        
        var beforeData: PositionData?
        var afterData: PositionData?
        
        for data in sortedData {
            if data.timestamp <= targetTime {
                beforeData = data
            } else {
                afterData = data
                break
            }
        }
        
        guard let before = beforeData, let after = afterData else {
            return sortedData.last?.position ?? position
        }
        
        // Linear interpolation
        let timeDiff = after.timestamp.timeIntervalSince(before.timestamp)
        let factor = targetTime.timeIntervalSince(before.timestamp) / timeDiff
        
        return before.position.interpolated(to: after.position, factor: CGFloat(factor))
    }
    
    func getPredictedPosition(futureTime: TimeInterval = 0.033) -> CGPoint {
        let futureDate = Date().addingTimeInterval(futureTime)
        return getInterpolatedPosition(at: futureDate)
    }
    
    // MARK: - Game State Updates
    func updateScore(_ newScore: Int) {
        score = newScore
        markAsActive()
    }
    
    func updateLives(_ newLives: Int) {
        lives = newLives
        markAsActive()
    }
    
    func setReady(_ ready: Bool) {
        isReady = ready
        markAsActive()
    }
    
    func assignPlayerType(_ type: PlayerType) {
        playerType = type
        markAsActive()
    }
    
    func loseLife() {
        lives = max(0, lives - 1)
        markAsActive()
    }
    
    func addScore(_ points: Int) {
        score += points
        markAsActive()
    }
    
    func reset() {
        score = 0
        lives = Constants.defaultPlayerLives
        position = CGPoint.zero
        velocity = CGVector.zero
        isReady = false
        pendingUpdates.removeAll()
        interpolationBuffer.removeAll()
    }
    
    // MARK: - Network Statistics
    func recordMessageSent(bytes: Int = 0) {
        messagesSent += 1
        bytesTransferred += Int64(bytes)
    }
    
    func recordMessageReceived(bytes: Int = 0) {
        messagesReceived += 1
        bytesTransferred += Int64(bytes)
        markAsActive()
    }
    
    func updateSyncLag(_ lag: TimeInterval) {
        syncLag = lag
    }
    
    func getNetworkStats() -> NetworkStats {
        return NetworkStats(
            messagesSent: messagesSent,
            messagesReceived: messagesReceived,
            bytesTransferred: bytesTransferred,
            ping: ping,
            connectionQuality: connectionQuality,
            syncLag: syncLag,
            sessionDuration: sessionDuration
        )
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return name.isEmpty ? "Player \(id.prefix(4))" : name
    }
    
    var statusText: String {
        switch connectionState {
        case .disconnected: return "Offline"
        case .connecting: return "Connecting..."
        case .connected: return isReady ? "Ready" : "Connected"
        case .reconnecting: return "Reconnecting..."
        case .timeout: return "Timed Out"
        }
    }
    
    var roleText: String {
        var role = playerType.displayName
        if isHost { role += " (Host)" }
        if isLocal { role += " (You)" }
        return role
    }
    
    var connectionStatusColor: String {
        return connectionQuality.color
    }
    
    var isAlive: Bool {
        return lives > 0
    }
    
    var isTimeout: Bool {
        return connectionState == .timeout || getTimeSinceLastSeen() > 30.0
    }
    
    var shouldShowWarning: Bool {
        return connectionQuality == .poor || connectionQuality == .terrible
    }
    
    // MARK: - Player Comparison
    func isSamePlayer(as other: NetworkPlayer) -> Bool {
        return id == other.id && peerID.displayName == other.peerID.displayName
    }
}

// MARK: - Supporting Types
enum PlayerConnectionState: String, Codable, CaseIterable {
    case disconnected = "disconnected"
    case connecting = "connecting"
    case connected = "connected"
    case reconnecting = "reconnecting"
    case timeout = "timeout"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var isConnected: Bool {
        return self == .connected
    }
    
    var canReceiveMessages: Bool {
        return self == .connected
    }
}

enum NetworkQuality: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"
    case terrible = "terrible"
    
    var displayName: String {
        return rawValue.capitalized
    }
    
    var color: String {
        switch self {
        case .excellent: return "#00FF00"
        case .good: return "#90EE90"
        case .fair: return "#FFFF00"
        case .poor: return "#FFA500"
        case .terrible: return "#FF0000"
        }
    }
    
    var emoji: String {
        switch self {
        case .excellent: return "🟢"
        case .good: return "🟡"
        case .fair: return "🟠"
        case .poor: return "🔴"
        case .terrible: return "⚫"
        }
    }
    
    var description: String {
        switch self {
        case .excellent: return "Perfect connection"
        case .good: return "Good connection"
        case .fair: return "Fair connection"
        case .poor: return "Poor connection"
        case .terrible: return "Very poor connection"
        }
    }
}

struct DeviceInfo: Codable {
    let model: String
    let systemVersion: String
    let appVersion: String
    let deviceId: String
    
    init() {
        self.model = UIDevice.current.model
        self.systemVersion = UIDevice.current.systemVersion
        self.appVersion = Constants.gameVersion
        self.deviceId = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
    }
}

struct PositionData {
    let position: CGPoint
    let velocity: CGVector
    let timestamp: Date
}

struct PlayerUpdate {
    let position: CGPoint
    let velocity: CGVector
    let timestamp: Date
    let receivedAt: Date
    
    init(position: CGPoint, velocity: CGVector, timestamp: Date) {
        self.position = position
        self.velocity = velocity
        self.timestamp = timestamp
        self.receivedAt = Date()
    }
    
    var age: TimeInterval {
        return Date().timeIntervalSince(receivedAt)
    }
    
    var isStale: Bool {
        return age > 1.0 // Stale after 1 second
    }
}

struct NetworkStats {
    let messagesSent: Int
    let messagesReceived: Int
    let bytesTransferred: Int64
    let ping: TimeInterval
    let connectionQuality: NetworkQuality
    let syncLag: TimeInterval
    let sessionDuration: TimeInterval
    
    var formattedBytesTransferred: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB]
        formatter.countStyle = .binary
        return formatter.string(fromByteCount: bytesTransferred)
    }
    
    var formattedPing: String {
        return String(format: "%.0fms", ping * 1000)
    }
    
    var formattedSyncLag: String {
        return String(format: "%.0fms", syncLag * 1000)
    }
    
    var summary: String {
        return """
        Messages: \(messagesSent) sent, \(messagesReceived) received
        Data: \(formattedBytesTransferred)
        Ping: \(formattedPing)
        Quality: \(connectionQuality.displayName)
        Session: \(String.durationString(from: sessionDuration))
        """
    }
}

// MARK: - NetworkPlayer Extensions
extension NetworkPlayer {
    
    // MARK: - Equatable
    static func == (lhs: NetworkPlayer, rhs: NetworkPlayer) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    // MARK: - Comparable (by score, then by connection quality)
    static func < (lhs: NetworkPlayer, rhs: NetworkPlayer) -> Bool {
        if lhs.score != rhs.score {
            return lhs.score > rhs.score
        }
        return lhs.connectionQuality.rawValue < rhs.connectionQuality.rawValue
    }
}

// MARK: - Array Extensions
extension Array where Element == NetworkPlayer {
    
    func connected() -> [NetworkPlayer] {
        return filter { $0.isConnected() }
    }
    
    func ready() -> [NetworkPlayer] {
        return filter { $0.isReady }
    }
    
    func hosts() -> [NetworkPlayer] {
        return filter { $0.isHost }
    }
    
    func mapMovers() -> [NetworkPlayer] {
        return filter { $0.playerType == .mapMover }
    }
    
    func regularPlayers() -> [NetworkPlayer] {
        return filter { $0.playerType == .regular }
    }
    
    func alive() -> [NetworkPlayer] {
        return filter { $0.isAlive }
    }
    
    func localPlayer() -> NetworkPlayer? {
        return first { $0.isLocal }
    }
    
    func remotePlayer() -> [NetworkPlayer] {
        return filter { !$0.isLocal }
    }
    
    func sortedByScore() -> [NetworkPlayer] {
        return sorted { $0.score > $1.score }
    }
    
    func sortedByConnectionQuality() -> [NetworkPlayer] {
        return sorted { $0.connectionQuality.rawValue < $1.connectionQuality.rawValue }
    }
    
    func getAverageScore() -> Double {
        guard !isEmpty else { return 0.0 }
        return Double(reduce(0) { $0 + $1.score }) / Double(count)
    }
    
    func getTotalScore() -> Int {
        return reduce(0) { $0 + $1.score }
    }
    
    func areAllReady() -> Bool {
        return !isEmpty && allSatisfy { $0.isReady }
    }
    
    func areAllConnected() -> Bool {
        return !isEmpty && allSatisfy { $0.isConnected() }
    }
    
    func getConnectionSummary() -> String {
        let connectedCount = connected().count
        let readyCount = ready().count
        let totalCount = count
        
        return "\(connectedCount)/\(totalCount) connected, \(readyCount)/\(totalCount) ready"
    }
}

// MARK: - NetworkPlayer Factory
struct NetworkPlayerFactory {
    
    static func createFromPeer(_ peerID: MCPeerID, isHost: Bool = false) -> NetworkPlayer {
        return NetworkPlayer(
            id: peerID.displayName,
            name: peerID.displayName,
            peerID: peerID,
            isHost: isHost,
            isLocal: false
        )
    }
    
    static func createLocalPlayer(name: String) -> NetworkPlayer {
        let deviceName = UIDevice.current.name
        let peerID = MCPeerID(displayName: deviceName)
        
        return NetworkPlayer(
            id: UUID().uuidString,
            name: name,
            peerID: peerID,
            isHost: false,
            isLocal: true
        )
    }
    
    static func createTestPlayers(count: Int) -> [NetworkPlayer] {
        return (1...count).map { index in
            let peerID = MCPeerID(displayName: "TestPlayer\(index)")
            return NetworkPlayer(
                id: "test_\(index)",
                name: "Test Player \(index)",
                peerID: peerID,
                isHost: index == 1,
                isReady: true,
                playerType: index == 1 ? .mapMover : .regular,
                isLocal: index == 1
            )
        }
    }
}
