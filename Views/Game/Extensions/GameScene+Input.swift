//
//  GameScene+Input.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit
import CoreMotion

// MARK: - Input Handling (Updated to use CameraManager)
extension GameScene {
    
    // MARK: - Accelerometer Setup
    func startAccelerometer() {
        guard motionManager.isAccelerometerAvailable else {
            print("[GameScene] Accelerometer not available!")
            return
        }
        
        guard let localPlayer = multipeerManager.players.first(where: { $0.peerID == localPlayerID }) else {
            print("[GameScene] Local player not found!")
            return
        }
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0 // 60Hz
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self,
                  let data = data,
                  let playerNode = self.playerNodes[localPlayer.id] else { return }
            
            if let error = error {
                print("[GameScene] Accelerometer error: \(error)")
                return
            }
            
            // Apply accelerometer input
            self.handleAccelerometerInput(data: data, playerNode: playerNode, playerID: localPlayer.id)
        }
        
        print("[GameScene] Accelerometer started for local player")
    }
    
    private func handleAccelerometerInput(data: CMAccelerometerData, playerNode: SKSpriteNode, playerID: String) {
        // Calculate force based on accelerometer data and settings
        let baseForce: CGFloat = 150.0
        let speedMultiplier = getSpeedMultiplier(for: playerID)
        
        let dx = CGFloat(data.acceleration.x) * accelerometerFactor * baseForce * speedMultiplier
        let dy = CGFloat(data.acceleration.y) * accelerometerFactor * baseForce * speedMultiplier
        
        // Apply force to player
        playerNode.physicsBody?.applyForce(CGVector(dx: dx, dy: dy))
        
        // Sync player state
        syncPlayerState(playerID: playerID, position: playerNode.position, velocity: playerNode.physicsBody?.velocity ?? .zero)
    }
    
    private func syncPlayerState(playerID: String, position: CGPoint, velocity: CGVector) {
        // Find the NetworkPlayer and update it
        if let player = multipeerManager.players.first(where: { $0.id == playerID }) {
            // Update the player state
            DispatchQueue.main.async {
                player.position = position
                player.velocity = velocity
                player.lastSeen = Date()
            }
            
            // Broadcast the update
            PlayerSyncManager.shared.broadcastPlayerUpdate(player)
        }
    }
    
    // MARK: - Edge Detection (Moved to CameraManager helper methods)
    func isAtScreenEdge(_ position: CGPoint, tolerance: CGFloat = 32) -> Bool {
        guard let levelData = levelManager.currentLevelData else { return false }
        
        let mapWidth = CGFloat(levelData.width) * levelData.tileSize
        let mapHeight = CGFloat(levelData.height) * levelData.tileSize
        
        return position.x <= tolerance ||
        position.x >= mapWidth - tolerance ||
        position.y <= tolerance ||
        position.y >= mapHeight - tolerance
    }
    
    func isAtSpecificEdge(_ position: CGPoint, edge: EdgeRole, tolerance: CGFloat = 32) -> Bool {
        guard let levelData = levelManager.currentLevelData else { return false }
        
        let mapWidth = CGFloat(levelData.width) * levelData.tileSize
        let mapHeight = CGFloat(levelData.height) * levelData.tileSize
        
        switch edge {
        case .left:
            return position.x <= tolerance
        case .right:
            return position.x >= mapWidth - tolerance
        case .bottom:
            return position.y <= tolerance
        case .top:
            return position.y >= mapHeight - tolerance
        }
    }
    
    // MARK: - Update Loop
    override func update(_ currentTime: TimeInterval) {
        // Clean up expired power-up effects
        cleanupExpiredEffects()
        
        // Update network players with smooth interpolation
        updateNetworkPlayers()
        
        // Check for edge-based camera movement for local player
        checkLocalPlayerEdgeMovement()
    }
    
    private func cleanupExpiredEffects() {
        let currentTime = CACurrentMediaTime()
        
        for (playerID, effect) in activeEffects {
            if !effect.isActive {
                activeEffects.removeValue(forKey: playerID)
            }
        }
    }
    
    private func updateNetworkPlayers() {
        for player in multipeerManager.players {
            if player.peerID != localPlayerID,
               let playerNode = playerNodes[player.id] {
                // Smooth network player movement
                let currentPos = playerNode.position
                let targetPos = player.position
                let smoothedPos = currentPos.interpolated(to: targetPos, factor: 0.15)
                
                playerNode.position = smoothedPos
                playerNode.physicsBody?.velocity = player.velocity
            }
        }
    }
    
    private func checkLocalPlayerEdgeMovement() {
        guard let localPlayer = multipeerManager.players.first(where: { $0.peerID == localPlayerID }),
              let playerNode = playerNodes[localPlayer.id],
              let assignedEdge = localPlayer.assignedEdge else { return }
        
        // Only check edge movement occasionally to avoid spam
        let currentTime = CACurrentMediaTime()
        var lastEdgeCheck: TimeInterval = 0
        
        if currentTime - lastEdgeCheck > 0.5 { // Check every 0.5 seconds
            if isAtSpecificEdge(playerNode.position, edge: assignedEdge, tolerance: 48) {
                // Player is at their assigned edge - they can move the camera
                var lastCameraMove: TimeInterval = 0
                if currentTime - lastCameraMove > 1.0 { // Limit camera moves
                    CameraManager.shared.scrollCamera(direction: assignedEdge)
                    lastCameraMove = currentTime
                }
            }
            lastEdgeCheck = currentTime
        }
    }
    
    // MARK: - Public Camera Control (Delegated to CameraManager)
    func setCameraPosition(_ position: CGPoint) {
        CameraManager.shared.moveCamera(to: position, animated: true)
    }
    
    func centerCamera(on position: CGPoint, animated: Bool = true) {
        CameraManager.shared.moveCamera(to: position, animated: animated)
    }
    
    func stopAccelerometer() {
        motionManager.stopAccelerometerUpdates()
        print("[GameScene] Accelerometer stopped")
    }
    
    // MARK: - Scene Cleanup
    override func willMove(from view: SKView) {
        stopAccelerometer()
        activeEffects.removeAll()
        playerNodes.removeAll()
        powerUpNodes.removeAll()
        checkpointNodes.removeAll()
        
        // Cleanup managers
        CameraManager.shared.cleanup()
        print("[GameScene] Scene cleanup complete")
    }
}
