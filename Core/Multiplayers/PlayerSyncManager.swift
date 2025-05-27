//
//  PlayerSyncManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics
import Combine

class PlayerSyncManager: ObservableObject {
    
    // MARK: - Properties
    @Published var playerStates: [String: PlayerSyncState] = [:]
    @Published var syncLatency: TimeInterval = 0
    @Published var isHost: Bool = false
    
    private let syncQueue = DispatchQueue(label: "playerSync", qos: .userInteractive)
    private var syncTimer: Timer?
    private var heartbeatTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private let syncRate: TimeInterval = 1.0 / 30.0 // 30 FPS
    private let heartbeatInterval: TimeInterval = 1.0 // 1 second
    private let maxLatency: TimeInterval = 0.5 // 500ms max acceptable latency
    private let interpolationDuration: TimeInterval = 0.1 // 100ms interpolation
    private let predictionTime: TimeInterval = 0.033 // ~33ms prediction (1 frame at 30fps)
    
    // MARK: - State Management
    private var localPlayerId: String = ""
    private var playerPositions: [String: PlayerPositionData] = [:]
    private var pendingUpdates: [String: [PlayerUpdate]] = [:]
    private var lastSyncTimestamp: TimeInterval = 0
    
    // MARK: - Initialization
    init() {
        setupSyncTimer()
        setupHeartbeatTimer()
    }
    
    deinit {
        stopSync()
    }
    
    // MARK: - Setup
    func configure(isHost: Bool, localPlayerId: String) {
        self.isHost = isHost
        self.localPlayerId = localPlayerId
        
        print("🔄 PlayerSyncManager configured - Host: \(isHost), Player: \(localPlayerId)")
    }
    
    private func setupSyncTimer() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncRate, repeats: true) { [weak self] _ in
            self?.processSyncUpdate()
        }
    }
    
    private func setupHeartbeatTimer() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: heartbeatInterval, repeats: true) { [weak self] _ in
            self?.sendHeartbeat()
        }
    }
    
    // MARK: - Player State Updates
    func updateLocalPlayerState(position: CGPoint, velocity: CGVector, lives: Int, score: Int) {
        let timestamp = Date().timeIntervalSince1970
        
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            let state = PlayerSyncState(
                playerId: self.localPlayerId,
                position: position,
                velocity: velocity,
                lives: lives,
                score: score,
                isReady: true,
                playerType: .mapMover, // This should come from actual player data
                lastCheckpointId: nil,
                timestamp: timestamp
            )
            
            DispatchQueue.main.async {
                self.playerStates[self.localPlayerId] = state
                
                // Send to other players
                self.sendPlayerUpdate(state)
            }
        }
    }
    
    func receivePlayerUpdate(_ state: PlayerSyncState) {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            // Validate timestamp to prevent old updates
            if let existingState = self.playerStates[state.playerId],
               state.timestamp <= existingState.timestamp {
                return
            }
            
            // Store the update
            let update = PlayerUpdate(
                state: state,
                receivedAt: Date().timeIntervalSince1970
            )
            
            if self.pendingUpdates[state.playerId] == nil {
                self.pendingUpdates[state.playerId] = []
            }
            self.pendingUpdates[state.playerId]?.append(update)
            
            // Keep only recent updates (last 500ms)
            let cutoffTime = Date().timeIntervalSince1970 - 0.5
            self.pendingUpdates[state.playerId]?.removeAll { $0.receivedAt < cutoffTime }
            
            // Update latency calculation
            self.updateLatency(for: state)
        }
    }
    
    // MARK: - Position Prediction and Interpolation
    func getPredictedPlayerPosition(_ playerId: String) -> CGPoint? {
        return syncQueue.sync {
            guard let positionData = playerPositions[playerId] else { return nil }
            
            let now = Date().timeIntervalSince1970
            let timeSinceUpdate = now - positionData.timestamp
            
            // If update is very recent, return exact position
            if timeSinceUpdate < 0.01 {
                return positionData.position
            }
            
            // Predict position based on velocity
            let predictedX = positionData.position.x + positionData.velocity.dx * timeSinceUpdate
            let predictedY = positionData.position.y + positionData.velocity.dy * timeSinceUpdate
            
            return CGPoint(x: predictedX, y: predictedY)
        }
    }
    
    func getInterpolatedPlayerPosition(_ playerId: String, at targetTime: TimeInterval) -> CGPoint? {
        return syncQueue.sync {
            guard let updates = pendingUpdates[playerId], updates.count >= 2 else {
                return playerStates[playerId]?.position
            }
            
            // Find two updates to interpolate between
            let sortedUpdates = updates.sorted { $0.state.timestamp < $1.state.timestamp }
            
            var beforeUpdate: PlayerUpdate?
            var afterUpdate: PlayerUpdate?
            
            for update in sortedUpdates {
                if update.state.timestamp <= targetTime {
                    beforeUpdate = update
                } else {
                    afterUpdate = update
                    break
                }
            }
            
            guard let before = beforeUpdate, let after = afterUpdate else {
                return sortedUpdates.last?.state.position
            }
            
            // Interpolate between the two positions
            let timeDiff = after.state.timestamp - before.state.timestamp
            let factor = (targetTime - before.state.timestamp) / timeDiff
            
            let interpolatedX = before.state.position.x + (after.state.position.x - before.state.position.x) * factor
            let interpolatedY = before.state.position.y + (after.state.position.y - before.state.position.y) * factor
            
            return CGPoint(x: interpolatedX, y: interpolatedY)
        }
    }
    
    // MARK: - Lag Compensation
    func getCompensatedPlayerPosition(_ playerId: String, lagCompensation: TimeInterval = 0) -> CGPoint? {
        let compensationTime = Date().timeIntervalSince1970 - lagCompensation
        return getInterpolatedPlayerPosition(playerId, at: compensationTime)
    }
    
    // MARK: - Sync Processing
    private func processSyncUpdate() {
        syncQueue.async { [weak self] in
            guard let self = self else { return }
            
            let now = Date().timeIntervalSince1970
            
            // Process pending updates for each player
            for (playerId, updates) in self.pendingUpdates {
                guard !updates.isEmpty else { continue }
                
                // Get the most recent update within interpolation window
                let targetTime = now - self.interpolationDuration
                
                if let interpolatedPosition = self.getInterpolatedPlayerPosition(playerId, at: targetTime) {
                    // Update player position data
                    if let latestUpdate = updates.last {
                        self.playerPositions[playerId] = PlayerPositionData(
                            position: interpolatedPosition,
                            velocity: latestUpdate.state.velocity,
                            timestamp: now
                        )
                        
                        // Update main player state
                        DispatchQueue.main.async {
                            var updatedState = latestUpdate.state
                            updatedState = PlayerSyncState(
                                playerId: updatedState.playerId,
                                position: interpolatedPosition,
                                velocity: updatedState.velocity,
                                lives: updatedState.lives,
                                score: updatedState.score,
                                isReady: updatedState.isReady,
                                playerType: updatedState.playerType,
                                lastCheckpointId: updatedState.lastCheckpointId,
                                timestamp: now
                            )
                            self.playerStates[playerId] = updatedState
                        }
                    }
                }
            }
            
            // Clean up old pending updates
            self.cleanupOldUpdates()
        }
    }
    
    private func cleanupOldUpdates() {
        let cutoffTime = Date().timeIntervalSince1970 - 1.0 // Keep last 1 second
        
        for playerId in pendingUpdates.keys {
            pendingUpdates[playerId]?.removeAll { $0.receivedAt < cutoffTime }
            
            if pendingUpdates[playerId]?.isEmpty == true {
                pendingUpdates[playerId] = nil
            }
        }
    }
    
    // MARK: - Network Communication
    private func sendPlayerUpdate(_ state: PlayerSyncState) {
        let message = NetworkMessage.playerMovement(
            playerId: state.playerId,
            position: state.position,
            velocity: state.velocity,
            timestamp: state.timestamp
        )
        
        MultipeerManager.shared.sendMessage(message)
    }
    
    private func sendHeartbeat() {
        let message = NetworkMessage.heartbeat(
            playerId: localPlayerId,
            timestamp: Date().timeIntervalSince1970
        )
        
        MultipeerManager.shared.sendMessage(message)
    }
    
    // MARK: - Latency Management
    private func updateLatency(for state: PlayerSyncState) {
        let now = Date().timeIntervalSince1970
        let messageLatency = now - state.timestamp
        
        DispatchQueue.main.async { [weak self] in
            // Simple moving average for latency
            self?.syncLatency = (self?.syncLatency ?? 0) * 0.9 + messageLatency * 0.1
        }
    }
    
    func getAverageLatency() -> TimeInterval {
        return syncLatency
    }
    
    func isLatencyAcceptable() -> Bool {
        return syncLatency <= maxLatency
    }
    
    // MARK: - Player Management
    func addPlayer(_ playerId: String, initialState: PlayerSyncState) {
        syncQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.playerStates[playerId] = initialState
            }
            
            self?.playerPositions[playerId] = PlayerPositionData(
                position: initialState.position,
                velocity: initialState.velocity,
                timestamp: initialState.timestamp
            )
        }
        
        print("👤 Player added to sync: \(playerId)")
    }
    
    func removePlayer(_ playerId: String) {
        syncQueue.async { [weak self] in
            DispatchQueue.main.async {
                self?.playerStates.removeValue(forKey: playerId)
            }
            
            self?.playerPositions.removeValue(forKey: playerId)
            self?.pendingUpdates.removeValue(forKey: playerId)
        }
        
        print("👤 Player removed from sync: \(playerId)")
    }
    
    func getPlayerState(_ playerId: String) -> PlayerSyncState? {
        return playerStates[playerId]
    }
    
    func getAllPlayerStates() -> [PlayerSyncState] {
        return Array(playerStates.values)
    }
    
    // MARK: - Sync Control
    func startSync() {
        print("▶️ PlayerSync started")
        setupSyncTimer()
        setupHeartbeatTimer()
    }
    
    func stopSync() {
        print("⏹️ PlayerSync stopped")
        syncTimer?.invalidate()
        heartbeatTimer?.invalidate()
        syncTimer = nil
        heartbeatTimer = nil
    }
    
    func pauseSync() {
        syncTimer?.invalidate()
        heartbeatTimer?.invalidate()
    }
    
    func resumeSync() {
        setupSyncTimer()
        setupHeartbeatTimer()
    }
    
    // MARK: - Debug Information
    func getDebugInfo() -> SyncDebugInfo {
        return syncQueue.sync {
            return SyncDebugInfo(
                activePlayersCount: playerStates.count,
                averageLatency: syncLatency,
                pendingUpdatesCount: pendingUpdates.values.reduce(0) { $0 + $1.count },
                syncRate: 1.0 / syncRate,
                isHost: isHost,
                lastSyncTime: lastSyncTimestamp
            )
        }
    }
    
    func logSyncStatistics() {
        let debugInfo = getDebugInfo()
        print("""
        🔄 Sync Statistics:
        - Active Players: \(debugInfo.activePlayersCount)
        - Average Latency: \(Int(debugInfo.averageLatency * 1000))ms
        - Pending Updates: \(debugInfo.pendingUpdatesCount)
        - Sync Rate: \(Int(debugInfo.syncRate)) FPS
        - Is Host: \(debugInfo.isHost)
        """)
    }
}

// MARK: - Supporting Data Types
private struct PlayerPositionData {
    let position: CGPoint
    let velocity: CGVector
    let timestamp: TimeInterval
}

private struct PlayerUpdate {
    let state: PlayerSyncState
    let receivedAt: TimeInterval
}

struct SyncDebugInfo {
    let activePlayersCount: Int
    let averageLatency: TimeInterval
    let pendingUpdatesCount: Int
    let syncRate: Double
    let isHost: Bool
    let lastSyncTime: TimeInterval
}

// MARK: - Extensions
extension PlayerSyncManager {
    // Helper method to send message through MultipeerManager
    private func sendMessage(_ message: NetworkMessage) {
        // This would be called through MultipeerManager
        // MultipeerManager.shared.sendMessage(message)
    }
}

// MARK: - Sync State Extensions
extension PlayerSyncState {
    func isRecent(within timeInterval: TimeInterval = 1.0) -> Bool {
        let now = Date().timeIntervalSince1970
        return (now - timestamp) <= timeInterval
    }
    
    func distanceTo(_ otherState: PlayerSyncState) -> CGFloat {
        let dx = position.x - otherState.position.x
        let dy = position.y - otherState.position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func velocityMagnitude() -> CGFloat {
        return sqrt(velocity.dx * velocity.dx + velocity.dy * velocity.dy)
    }
}
