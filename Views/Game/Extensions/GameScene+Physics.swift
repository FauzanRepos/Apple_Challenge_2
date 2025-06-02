//
//  GameScene+Physics.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit

// MARK: - Physics and Collision Handling (Updated to use CollisionManager)
extension GameScene {
    
    // MARK: - Physics Setup
    func setupCollisionSystem() {
        CollisionManager.shared.setupCollisionManager(scene: self)
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        // Delegate all collision handling to CollisionManager
        CollisionManager.shared.handleCollision(between: contact.bodyA, and: contact.bodyB)
    }
    
    // MARK: - Power-Up Effect Helpers (Accessed by CollisionManager)
    func getSpeedMultiplier(for playerID: String) -> CGFloat {
        guard let effect = activeEffects[playerID], effect.isActive else { return 1.0 }
        
        switch effect.type {
        case .oil:
            return 2.0  // 2x speed boost
        case .grass:
            return 0.5  // 0.5x speed reduction
        }
    }
}
