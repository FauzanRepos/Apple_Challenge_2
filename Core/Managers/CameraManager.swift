//
//  CameraManager.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SpriteKit
import CoreGraphics

/// Centralized camera management for the game
final class CameraManager: ObservableObject {
    static let shared = CameraManager()
    
    @Published var currentPosition: CGPoint = .zero
    @Published var isFollowingPlayer: Bool = false
    @Published var followPlayerID: String? = nil
    
    private weak var gameScene: GameScene?
    private weak var camera: SKCameraNode?
    
    private init() {}
    
    // MARK: - Setup
    func setupCamera(scene: GameScene, camera: SKCameraNode) {
        self.gameScene = scene
        self.camera = camera
        print("[CameraManager] Camera setup complete")
    }
    
    // MARK: - Camera Movement
    func moveCamera(to position: CGPoint, animated: Bool = true, duration: TimeInterval = 0.3) {
        guard let camera = camera else { return }
        
        let clampedPosition = clampCameraPosition(position)
        currentPosition = clampedPosition
        
        if animated {
            let moveAction = SKAction.move(to: clampedPosition, duration: duration)
            moveAction.timingMode = .easeOut
            camera.run(moveAction)
        } else {
            camera.position = clampedPosition
        }
        
        print("[CameraManager] Camera moved to: \(clampedPosition)")
    }
    
    func scrollCamera(direction: EdgeRole, amount: CGFloat? = nil) {
        guard let camera = camera,
              let levelData = LevelManager.shared.currentLevelData else { return }
        
        let scrollAmount = amount ?? (levelData.tileSize * 3)
        let currentPos = camera.position
        var newPosition = currentPos
        
        switch direction {
        case .left:
            newPosition.x -= scrollAmount
        case .right:
            newPosition.x += scrollAmount
        case .top:
            newPosition.y += scrollAmount
        case .bottom:
            newPosition.y -= scrollAmount
        }
        
        moveCamera(to: newPosition, animated: true, duration: 0.25)
        
        // Broadcast to other players
        PlayerSyncManager.shared.broadcastCameraPosition(newPosition)
    }
    
    // MARK: - Camera Constraints
    private func clampCameraPosition(_ position: CGPoint) -> CGPoint {
        guard let scene = gameScene,
              let levelData = LevelManager.shared.currentLevelData else { return position }
        
        let mapWidth = CGFloat(levelData.width) * levelData.tileSize
        let mapHeight = CGFloat(levelData.height) * levelData.tileSize
        let sceneSize = scene.size
        
        let minX = sceneSize.width / 2
        let maxX = mapWidth - sceneSize.width / 2
        let minY = sceneSize.height / 2
        let maxY = mapHeight - sceneSize.height / 2
        
        return CGPoint(
            x: max(minX, min(maxX, position.x)),
            y: max(minY, min(maxY, position.y))
        )
    }
    
    // MARK: - Player Following
    func startFollowingPlayer(_ playerID: String) {
        isFollowingPlayer = true
        followPlayerID = playerID
        print("[CameraManager] Started following player: \(playerID)")
    }
    
    func stopFollowingPlayer() {
        isFollowingPlayer = false
        followPlayerID = nil
        print("[CameraManager] Stopped following player")
    }
    
    func updateFollowedPlayerPosition(_ position: CGPoint) {
        guard isFollowingPlayer else { return }
        moveCamera(to: position, animated: true, duration: 0.1)
    }
    
    // MARK: - Zoom Controls (Future Feature)
    func setZoom(_ scale: CGFloat, animated: Bool = true) {
        guard let camera = camera else { return }
        
        let clampedScale = max(0.5, min(2.0, scale)) // Clamp between 0.5x and 2.0x
        
        if animated {
            let scaleAction = SKAction.scale(to: clampedScale, duration: 0.3)
            camera.run(scaleAction)
        } else {
            camera.setScale(clampedScale)
        }
    }
    
    // MARK: - Camera Shake Effect
    func shakeCamera(intensity: CGFloat = 10.0, duration: TimeInterval = 0.5) {
        guard let camera = camera else { return }
        
        let numberOfShakes = 6
        let shakeDuration = duration / Double(numberOfShakes)
        
        var actions: [SKAction] = []
        
        for i in 0..<numberOfShakes {
            let randomX = CGFloat.random(in: -intensity...intensity)
            let randomY = CGFloat.random(in: -intensity...intensity)
            let shakeVector = CGVector(dx: randomX, dy: randomY)
            
            let shakeAction = SKAction.moveBy(x: shakeVector.dx, y: shakeVector.dy, duration: shakeDuration / 2)
            let returnAction = SKAction.moveBy(x: -shakeVector.dx, y: -shakeVector.dy, duration: shakeDuration / 2)
            
            actions.append(shakeAction)
            actions.append(returnAction)
        }
        
        let shakeSequence = SKAction.sequence(actions)
        camera.run(shakeSequence)
    }
    
    // MARK: - Cleanup
    func cleanup() {
        gameScene = nil
        camera = nil
        isFollowingPlayer = false
        followPlayerID = nil
        currentPosition = .zero
        print("[CameraManager] Cleanup complete")
    }
}
