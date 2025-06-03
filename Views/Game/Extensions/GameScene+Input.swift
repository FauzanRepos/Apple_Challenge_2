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
        print("[GameScene] Starting accelerometer setup...")
        print("[GameScene] Accelerometer available: \(motionManager.isAccelerometerAvailable)")
        print("[GameScene] Accelerometer active: \(motionManager.isAccelerometerActive)")
        
        guard motionManager.isAccelerometerAvailable else {
            print("[GameScene] ERROR: Accelerometer not available!")
            return
        }
        
        guard let localPlayer = multipeerManager.players.first(where: { $0.peerID == localPlayerID }) else {
            print("[GameScene] ERROR: Local player not found!")
            return
        }
        
        print("[GameScene] Found local player: \(localPlayer.id)")
        print("[GameScene] Current sensitivity: \(SettingsManager.shared.controlSensitivity)")
        print("[GameScene] Accelerometer inverted: \(SettingsManager.shared.accelerometerInverted)")
        
        motionManager.accelerometerUpdateInterval = 1.0 / 60.0 // 60Hz
        
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, error in
            guard let self = self else {
                print("[GameScene] ERROR: Self was deallocated in accelerometer callback")
                return
            }
            
            if let error = error {
                print("[GameScene] ERROR: Accelerometer error: \(error)")
                return
            }
            
            guard let data = data else {
                print("[GameScene] ERROR: No accelerometer data received")
                return
            }
            
            guard let playerNode = self.playerNodes[localPlayer.id] else {
                print("[GameScene] ERROR: Player node not found for ID: \(localPlayer.id)")
                return
            }
            
            // Apply accelerometer input
            self.handleAccelerometerInput(data: data, playerNode: playerNode, playerID: localPlayer.id)
        }
        
        print("[GameScene] Accelerometer started successfully")
    }
    
    private func handleAccelerometerInput(data: CMAccelerometerData, playerNode: SKSpriteNode, playerID: String) {
        // Calculate force based on accelerometer data and settings
        let baseForce: CGFloat = 150.0
        let speedMultiplier = getSpeedMultiplier(for: playerID)
        
        let dx = CGFloat(data.acceleration.x) * accelerometerFactor * baseForce * speedMultiplier
        let dy = CGFloat(data.acceleration.y) * accelerometerFactor * baseForce * speedMultiplier
        
        // Debug logging
        print("[GameScene] Accelerometer values - x: \(data.acceleration.x), y: \(data.acceleration.y)")
        print("[GameScene] Applied force - dx: \(dx), dy: \(dy)")
        print("[GameScene] Factors - sensitivity: \(SettingsManager.shared.controlSensitivity), multiplier: \(speedMultiplier)")
        
        // Apply force to player
        playerNode.physicsBody?.applyForce(CGVector(dx: dx, dy: dy))
        
        // Log current velocity
        if let velocity = playerNode.physicsBody?.velocity {
            print("[GameScene] Current velocity - dx: \(velocity.dx), dy: \(velocity.dy)")
        }
        
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
        // Debug logging for update loop
        print("[GameScene] Update loop called")
        print("[GameScene] Number of players: \(multipeerManager.players.count)")
        print("[GameScene] Players: \(multipeerManager.players.map { $0.id })")
        
        // Clean up expired power-up effects
        cleanupExpiredEffects()
        
        // Update network players with smooth interpolation
        updateNetworkPlayers()
        
        // Handle camera movement based on game mode
        if multipeerManager.players.count <= 1 {
            print("[GameScene] Single player mode detected")
            // Single player mode - camera follows player
            handleSinglePlayerCamera()
        } else {
            print("[GameScene] Multiplayer mode detected - Player count: \(multipeerManager.players.count)")
            // Multiplayer mode - check for edge-based camera movement
            checkLocalPlayerEdgeMovement()
        }
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
    
    private func handleSinglePlayerCamera() {
        print("[GameScene] Attempting to handle single player camera")
        
        // Get the first (and should be only) player node
        guard let playerNodeID = playerNodes.keys.first,
              let playerNode = playerNodes[playerNodeID] else {
            print("[GameScene] ERROR: No player nodes found")
            print("[GameScene] Available player nodes: \(playerNodes.keys.joined(separator: ", "))")
            return
        }
        
        // Get current positions
        let playerPos = playerNode.position
        let currentCameraPos = gameCamera.position
        
        print("[GameScene] Current positions - Player: \(playerPos), Camera: \(currentCameraPos)")
        
        // Update camera position to match player position
        gameCamera.position = playerPos
        
        // Force camera update
        gameCamera.setScale(1.0)  // Ensure camera is at default scale
        
        // Verify the update
        print("[GameScene] Camera position updated to: \(gameCamera.position)")
        print("[GameScene] Camera parent: \(String(describing: gameCamera.parent))")
        print("[GameScene] Camera constraints: \(String(describing: gameCamera.constraints))")
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
