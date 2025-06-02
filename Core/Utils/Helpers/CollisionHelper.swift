//
//  CollisionHelper.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit

/// Utility for SpriteKit collision bitmasks and contact handling.
struct CollisionHelper {
    // Collision categories
    struct Category {
        static let none: UInt32        = 0
        static let player: UInt32      = 0b1
        static let wall: UInt32        = 0b10
        static let checkpoint: UInt32  = 0b100
        static let spike: UInt32       = 0b1000
        static let oil: UInt32         = 0b10000
        static let grass: UInt32       = 0b100000
        static let vortex: UInt32      = 0b1000000
        static let finish: UInt32      = 0b10000000
    }
    
    static func setPhysics(node: SKNode, category: UInt32, contact: UInt32, collision: UInt32, dynamic: Bool = true, allowsRotation: Bool = true) {
        let body = SKPhysicsBody(circleOfRadius: (node.frame.size.width + node.frame.size.height) / 4)
        body.isDynamic = dynamic
        body.affectedByGravity = false
        body.allowsRotation = allowsRotation
        body.categoryBitMask = category
        body.contactTestBitMask = contact
        body.collisionBitMask = collision
        node.physicsBody = body
    }
}
