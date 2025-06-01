//
//  SKScene+Extensions.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit

extension SKScene {
    /// Center camera on point with optional animation
    func centerCamera(on point: CGPoint, duration: TimeInterval = 0.2) {
        if let skView = UIApplication.shared.windows.first?.rootViewController?.view as? SKView,
           let scene = skView.scene as? GameScene {
            guard let camera = self.camera else { return }
            let action = SKAction.move(to: point, duration: duration)
            camera.run(action)
        }
    }
    
    /// Adds a node with a fade-in effect
    func addNodeWithFade(_ node: SKNode, duration: TimeInterval = 0.25) {
        node.alpha = 0
        addChild(node)
        let fadeIn = SKAction.fadeIn(withDuration: duration)
        node.run(fadeIn)
    }
}
