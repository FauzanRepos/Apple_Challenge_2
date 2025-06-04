//
//  GameScene+Input.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit
import CoreMotion

// MARK: - Associated Keys for extension properties
private struct AssociatedKeys {
    static var lastSyncTime = "lastSyncTime"
}

// MARK: - Input Handling (Updated to use CameraManager)
extension GameScene {
    
    // Rate limiting for network sync
    private var lastSyncTime: TimeInterval {
        get { return objc_getAssociatedObject(self, &AssociatedKeys.lastSyncTime) as? TimeInterval ?? 0 }
        set { objc_setAssociatedObject(self, &AssociatedKeys.lastSyncTime, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
    
    // MARK: - Accelerometer Setup
    func startAccelerometer() {
        print("[GameScene] Starting accelerometer setup...")
        print("[GameScene] Device: \(UIDevice.current.name)")
        print("[GameScene] Local Player ID: \(localPlayerID)")
        print("[GameScene] Accelerometer available: \(motionManager.isAccelerometerAvailable)")
        print("[GameScene] Accelerometer active: \(motionManager.isAccelerometerActive)")
        
        guard motionManager.isAccelerometerAvailable else {
            print("[GameScene] ERROR: Accelerometer not available!")
            return
        }
        
        guard let localPlayer = multipeerManager.players.first(where: { $0.peerID == localPlayerID }) else {
            print("[GameScene] ERROR: Local player not found!")
            print("[GameScene] Available players: \(multipeerManager.players.map { "\($0.peerID) (ID: \($0.id))" })")
            return
        }
        
        print("[GameScene] ✅ Found local player: \(localPlayer.id) for device: \(localPlayer.peerID)")
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
                // Only log this error occasionally to avoid spam
                let currentTime = CACurrentMediaTime()
                if currentTime.truncatingRemainder(dividingBy: 5.0) < 0.1 {
                    print("[GameScene] ERROR: Player node not found for ID: \(localPlayer.id)")
                    print("[GameScene] Available player nodes: \(self.playerNodes.keys.joined(separator: ", "))")
                }
                return
            }
            
            // Apply accelerometer input
            self.handleAccelerometerInput(data: data, playerNode: playerNode, playerID: localPlayer.id)
        }
        
        print("[GameScene] ✅ Accelerometer started successfully for \(localPlayer.peerID)")
    }
    
    private func handleAccelerometerInput(data: CMAccelerometerData, playerNode: SKSpriteNode, playerID: String) {
        // Calculate force based on accelerometer data and settings
        let baseForce: CGFloat = 150.0
        let speedMultiplier = getSpeedMultiplier(for: playerID)
        
        let dx = CGFloat(data.acceleration.x) * accelerometerFactor * baseForce * speedMultiplier
        let dy = CGFloat(data.acceleration.y) * accelerometerFactor * baseForce * speedMultiplier
        
        // Apply force to player
        playerNode.physicsBody?.applyForce(CGVector(dx: dx, dy: dy))
        
        // Only sync player state occasionally to reduce network traffic and conflicts
        let currentTime = CACurrentMediaTime()
        if currentTime - lastSyncTime > 0.1 { // Sync only every 100ms
            syncPlayerState(playerID: playerID, position: playerNode.position, velocity: playerNode.physicsBody?.velocity ?? .zero)
            lastSyncTime = currentTime
        }
    }
    
    private func syncPlayerState(playerID: String, position: CGPoint, velocity: CGVector) {
        // Only sync if this is the local player
        guard playerID == localPlayerID else { return }
        
        // Find the NetworkPlayer and update it
        if let player = multipeerManager.players.first(where: { $0.id == playerID }) {
            // Update the player state
            DispatchQueue.main.async {
                player.position = position
                player.velocity = velocity
                player.lastSeen = Date()
            }
            
            // Broadcast the update with reduced frequency
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
        
        // Handle camera movement based on game mode
        if multipeerManager.players.count <= 1 {
            // Single player mode - camera follows player
            handleSinglePlayerCamera()
        } else {
            // Multiplayer mode - check for edge-based camera movement
            checkLocalPlayerEdgeMovement()
        }
        
        // Debug player status occasionally
        if currentTime.truncatingRemainder(dividingBy: 10.0) < 0.1 { // Every 10 seconds
            print("[GameScene] 🎮 Player Status:")
            print("- Connected players: \(multipeerManager.players.count)")
            print("- Player nodes: \(playerNodes.count)")
            print("- Local player ID: \(localPlayerID)")
            for player in multipeerManager.players {
                let hasNode = playerNodes[player.id] != nil
                let isLocal = player.peerID == localPlayerID
                print("  • \(player.peerID) (ID: \(player.id)) - Node: \(hasNode ? "✅" : "❌"), Local: \(isLocal ? "✅" : "❌")")
            }
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
//        print("[GameScene] Attempting to handle single player camera")
        
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
        
//        print("[GameScene] Current positions - Player: \(playerPos), Camera: \(currentCameraPos)")
        
        // Update camera position to match player position
        gameCamera.position = playerPos
        
        // Force camera update
        gameCamera.setScale(1.0)  // Ensure camera is at default scale
        
        // Verify the update
//        print("[GameScene] Camera position updated to: \(gameCamera.position)")
//        print("[GameScene] Camera parent: \(String(describing: gameCamera.parent))")
//        print("[GameScene] Camera constraints: \(String(describing: gameCamera.constraints))")
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
