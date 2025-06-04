//
//  CollisionManager.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SpriteKit

/// Centralized collision detection and response management
final class CollisionManager {
    static let shared = CollisionManager()
    
    private weak var gameScene: GameScene?
    private let audioManager = AudioManager.shared
    private let gameManager = GameManager.shared
    private let syncManager = PlayerSyncManager.shared
    
    private init() {}
    
    // MARK: - Setup
    func setupCollisionManager(scene: GameScene) {
        self.gameScene = scene
    }
    
    // MARK: - Collision Detection
    func handleCollision(between bodyA: SKPhysicsBody, and bodyB: SKPhysicsBody) {
        guard let nodeA = bodyA.node, let nodeB = bodyB.node else { return }
        
        // Debug print for collision
//        print("[CollisionManager] Collision detected between:")
//        print("- Node A: \(nodeA.name ?? "unknown"), Category: \(bodyA.categoryBitMask)")
//        print("- Node B: \(nodeB.name ?? "unknown"), Category: \(bodyB.categoryBitMask)")
        
        // Determine collision participants
        let collision = identifyCollision(bodyA: bodyA, bodyB: bodyB, nodeA: nodeA, nodeB: nodeB)
        
        guard let playerNode = collision.playerNode,
              let otherNode = collision.otherNode,
              let playerID = collision.playerID else { return }
        
        // Route to appropriate handler
        switch collision.category {
        case CollisionHelper.Category.checkpoint:
            handleCheckpointCollision(playerID: playerID, playerNode: playerNode, checkpointNode: otherNode)
            
        case CollisionHelper.Category.vortex:
            print("[CollisionManager] Vortex collision detected for player: \(playerID)")
            print("[CollisionManager] Vortex node: \(otherNode.name ?? "unknown")")
            handleVortexCollision(playerID: playerID, playerNode: playerNode)
            
        case CollisionHelper.Category.spike:
            handleSpikeCollision(playerID: playerID, playerNode: playerNode)
            
        case CollisionHelper.Category.oil:
            handleOilCollision(playerID: playerID, powerUpNode: otherNode)
            
        case CollisionHelper.Category.grass:
            handleGrassCollision(playerID: playerID, powerUpNode: otherNode)
            
        case CollisionHelper.Category.finish:
            handleFinishCollision(playerID: playerID, playerNode: playerNode)
            
        case CollisionHelper.Category.player:
            handlePlayerCollision(playerID: playerID, otherPlayerNode: otherNode)
            
        default:
            break
        }
    }
    
    // MARK: - Collision Identification
    private func identifyCollision(bodyA: SKPhysicsBody, bodyB: SKPhysicsBody, nodeA: SKNode, nodeB: SKNode) -> CollisionInfo {
        var playerNode: SKSpriteNode?
        var otherNode: SKSpriteNode?
        var playerID: String?
        var category: UInt32 = 0
        
        if bodyA.categoryBitMask == CollisionHelper.Category.player {
            playerNode = nodeA as? SKSpriteNode
            otherNode = nodeB as? SKSpriteNode
            playerID = nodeA.name
            category = bodyB.categoryBitMask
//            print("[CollisionManager] Player collision identified - Player: \(playerID ?? "unknown"), Other category: \(category), Other node: \(nodeB.name ?? "unknown")")
        } else if bodyB.categoryBitMask == CollisionHelper.Category.player {
            playerNode = nodeB as? SKSpriteNode
            otherNode = nodeA as? SKSpriteNode
            playerID = nodeB.name
            category = bodyA.categoryBitMask
//            print("[CollisionManager] Player collision identified - Player: \(playerID ?? "unknown"), Other category: \(category), Other node: \(nodeA.name ?? "unknown")")
        }
        
        return CollisionInfo(
            playerNode: playerNode,
            otherNode: otherNode,
            playerID: playerID,
            category: category
        )
    }
    
    // MARK: - Specific Collision Handlers
    private func handleCheckpointCollision(playerID: String, playerNode: SKSpriteNode, checkpointNode: SKSpriteNode) {
        guard let checkpointName = checkpointNode.name,
              checkpointName.hasPrefix("checkpoint_"),
              let sectionString = checkpointName.components(separatedBy: "_").last,
              let sectionIndex = Int(sectionString) else {
            print("[CollisionManager] Invalid checkpoint node configuration")
            return
        }
        
        // Check if already collected
        guard !gameManager.reachedCheckpoints.contains(sectionIndex) else { return }
        
        // Update game state
        gameManager.reachCheckpoint(sectionIndex)
        
        // Set checkpoint position
        let checkpointPosition = checkpointNode.position
        gameManager.lastCheckpoint = checkpointPosition
        print("[CollisionManager] Setting checkpoint \(sectionIndex) position: \(checkpointPosition)")
        
        // Visual and audio feedback
        animateCheckpointCollection(checkpointNode)
        audioManager.playSFX("sfx_checkpoint", xtension: "mp3")
        
        // Remove checkpoint from scene
        checkpointNode.removeFromParent()
        
        // Remove from checkpoint nodes array
        if let scene = gameScene {
            scene.checkpointNodes.removeAll { $0 == checkpointNode }
        }
        
        // Network sync
        let event = GameEvent(type: .checkpointReached, section: sectionIndex)
        syncManager.broadcastGameEvent(event)
        
        print("[CollisionManager] Checkpoint \(sectionIndex) collected by \(playerID)")
    }
    
    private func handleVortexCollision(playerID: String, playerNode: SKSpriteNode) {
        print("[CollisionManager] Vortex collision detected for player: \(playerID)")
        
        // Play death sound and shake camera
        audioManager.playSFX("sfx_death", xtension: "mp3")
        CameraManager.shared.shakeCamera(intensity: 15.0, duration: 0.6)
        
        // Handle player death
        handlePlayerDeath(playerID: playerID, cause: "vortex")
    }
    
    private func handleSpikeCollision(playerID: String, playerNode: SKSpriteNode) {
        guard let player = MultipeerManager.shared.players.first(where: { $0.id == playerID }) else {
            print("[CollisionManager] Player not found for ID: \(playerID)")
            return
        }
        
        // Check if player is at screen edge
        if isAtScreenEdge(playerNode.position) {
            if let assignedEdge = player.assignedEdge,
               isAtSpecificEdge(playerNode.position, edge: assignedEdge) {
                // Map mover can scroll the camera
                CameraManager.shared.scrollCamera(direction: assignedEdge)
                print("[CollisionManager] Player \(playerID) scrolled map via \(assignedEdge)")
            } else {
                // Non-map mover hits border - death
                audioManager.playSFX("sfx_death", xtension: "mp3")
                handlePlayerDeath(playerID: playerID, cause: "border spike")
                
                // Show respawn alert if lives remain, game over if no lives
                if gameManager.teamLives > 0 {
                    gameManager.showRespawnAlert()
                } else {
                    gameManager.showGameOverAlert()
                }
                
                print("[CollisionManager] Player \(playerID) died at border")
            }
        }
    }
    
    private func handleOilCollision(playerID: String, powerUpNode: SKSpriteNode) {
        // Remove power-up
        removePowerUp(powerUpNode)
        
        // Apply effect
        applyPowerUpEffect(playerID: playerID, type: .oil)
        
        // Feedback
        audioManager.playSFX("sfx_powerup", xtension: "mp3")
        animatePowerUpCollection(powerUpNode, color: .blue)
        
        print("[CollisionManager] Player \(playerID) collected oil power-up")
    }
    
    private func handleGrassCollision(playerID: String, powerUpNode: SKSpriteNode) {
        // Remove power-up
        removePowerUp(powerUpNode)
        
        // Apply effect
        applyPowerUpEffect(playerID: playerID, type: .grass)
        
        // Feedback
        audioManager.playSFX("sfx_powerup", xtension: "mp3")
        animatePowerUpCollection(powerUpNode, color: .green)
        
        print("[CollisionManager] Player \(playerID) collected grass power-up")
    }
    
    private func handleFinishCollision(playerID: String, playerNode: SKSpriteNode) {
        gameManager.playerFinished(playerID: playerID)
        
        // Visual feedback
        animatePlayerFinish(playerNode)
        audioManager.playSFX("sfx_finish", xtension: "mp3")
        
        print("[CollisionManager] Player \(playerID) reached finish")
        
        // Check if all players finished
        let totalPlayers = MultipeerManager.shared.players.count
        if gameManager.playersFinished.count == totalPlayers {
            audioManager.playSFX("sfx_checkpoint", xtension: "mp3")
            
            let event = GameEvent(type: .missionAccomplished)
            syncManager.broadcastGameEvent(event)
        }
    }
    
    private func handlePlayerCollision(playerID: String, otherPlayerNode: SKSpriteNode) {
        // Simple physics collision - let SpriteKit handle the bounce
        // Add collision sound effect
        audioManager.playSFX("sfx_collision", xtension: "mp3")
        
        print("[CollisionManager] Player collision: \(playerID) <-> \(otherPlayerNode.name ?? "unknown")")
    }
    
    // MARK: - Death Handling
    private func handlePlayerDeath(playerID: String, cause: String) {
        print("💀 [CollisionManager] Player death: \(playerID), cause: \(cause)")
        
        // Reduce team lives
        gameManager.loseLifeAndSync()
        
        // Show appropriate alert for both local and remote players
        if gameManager.teamLives > 0 {
            print("⚠️ [CollisionManager] Showing respawn alert - Lives remaining: \(gameManager.teamLives)")
            gameManager.showRespawnAlert()
        } else {
            print("⚠️ [CollisionManager] Showing game over alert - No lives remaining")
            gameManager.showGameOverAlert()
        }
        
        // Broadcast death event
        let event = GameEvent(type: .playerDeath, playerID: playerID)
        syncManager.broadcastGameEvent(event)
    }
    
    func respawnAllPlayers() {
        guard let scene = gameScene,
              let levelData = LevelManager.shared.currentLevelData else {
            print("❌ [CollisionManager] Cannot respawn: Missing scene or level data")
            return
        }
        
        // Get the last checkpoint or initial spawn point
        let respawnPoint = gameManager.lastCheckpoint ?? levelData.spawn
        print("📍 [CollisionManager] Respawn point: \(respawnPoint)")
        
        // Move all player nodes to the respawn point
        for (playerId, playerNode) in scene.playerNodes {
            print("🔄 [CollisionManager] Respawn player: \(playerId)")
            playerNode.position = respawnPoint
            playerNode.physicsBody?.velocity = .zero
            playerNode.physicsBody?.angularVelocity = 0
        }
    }
    
    // MARK: - Power-Up System
    private func removePowerUp(_ node: SKSpriteNode) {
        guard let scene = gameScene,
              let nodeName = node.name else { return }
        
        // Remove from scene's power-up tracking
        scene.powerUpNodes.removeValue(forKey: nodeName)
        
        // Remove visual node
        node.removeFromParent()
    }
    
    private func applyPowerUpEffect(playerID: String, type: PowerUpType) {
        guard let scene = gameScene else { return }
        
        let effect = PowerUpEffect(type: type, startTime: CACurrentMediaTime())
        scene.activeEffects[playerID] = effect
        
        // Schedule effect removal
        DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) { [weak scene] in
            scene?.activeEffects.removeValue(forKey: playerID)
            print("[CollisionManager] Power-up effect ended for \(playerID)")
        }
    }
    
    // MARK: - Visual Effects
    private func animateCheckpointCollection(_ node: SKSpriteNode) {
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.2)
        let sequence = SKAction.sequence([scaleUp, scaleDown, fadeOut])
        node.run(sequence)
    }
    
    private func animatePowerUpCollection(_ node: SKSpriteNode, color: UIColor) {
        let colorize = SKAction.colorize(with: color, colorBlendFactor: 0.8, duration: 0.1)
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.15)
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        let group = SKAction.group([colorize, scaleUp, fadeOut])
        node.run(group)
    }
    
    private func animatePlayerFinish(_ node: SKSpriteNode) {
        let pulse = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.3)
        ])
        let repeat_pulse = SKAction.repeatForever(pulse)
        node.run(repeat_pulse, withKey: "finishPulse")
    }
    
    // MARK: - Edge Detection Helpers
    private func isAtScreenEdge(_ position: CGPoint, tolerance: CGFloat = 32) -> Bool {
        guard let levelData = LevelManager.shared.currentLevelData else { return false }
        
        let mapWidth = CGFloat(levelData.width) * levelData.tileSize
        let mapHeight = CGFloat(levelData.height) * levelData.tileSize
        
        return position.x <= tolerance ||
        position.x >= mapWidth - tolerance ||
        position.y <= tolerance ||
        position.y >= mapHeight - tolerance
    }
    
    private func isAtSpecificEdge(_ position: CGPoint, edge: EdgeRole, tolerance: CGFloat = 32) -> Bool {
        guard let levelData = LevelManager.shared.currentLevelData else { return false }
        
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
}

// MARK: - Supporting Structures
struct CollisionInfo {
    let playerNode: SKSpriteNode?
    let otherNode: SKSpriteNode?
    let playerID: String?
    let category: UInt32
}
