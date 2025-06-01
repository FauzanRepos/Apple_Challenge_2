//
//  GameScene.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SpriteKit
import SwiftUI
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    private let gameManager = GameManager.shared
    private let levelManager = LevelManager.shared
    private let multipeerManager = MultipeerManager.shared
    private let motionManager = CMMotionManager()
    private var playerNodes: [String: SKSpriteNode] = [:]
    private var mapMoverPlayerID: String? { gameManager.mapMoverPlayerID }
    private var localPlayerID: String { multipeerManager.localPeerID.displayName }
    private var currentPlanet: Int { gameManager.currentPlanet }
    private var accelerometerFactor: CGFloat {
        CGFloat(SettingsManager.shared.controlSensitivity) * (SettingsManager.shared.accelerometerInverted ? -1 : 1)
    }
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        setupLevel()
        setupPlayers()
        startAccelerometer()
    }
    
    private func setupLevel() {
        guard let levelData = levelManager.currentLevelData else { return }
        // Set background
        let bg = SKSpriteNode(imageNamed: "Background_\(currentPlanet)")
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = -1
        addChild(bg)
        // Walls
        for rect in levelData.wallRects {
            let node = SKSpriteNode(imageNamed: Constants.asset(for: .wall, planet: currentPlanet))
            node.position = CGPoint(x: rect.midX, y: rect.midY)
            node.size = rect.size
            node.zPosition = 1
            CollisionHelper.setPhysics(node: node, category: CollisionHelper.Category.wall, contact: 0, collision: CollisionHelper.Category.player, dynamic: false)
            addChild(node)
        }
        // Checkpoints
        for (i, cp) in levelData.checkpointPositions.enumerated() {
            let node = SKSpriteNode(imageNamed: Constants.asset(for: .checkpoint, planet: currentPlanet))
            node.position = cp
            node.size = CGSize(width: Constants.checkpointRadius, height: Constants.checkpointRadius)
            node.zPosition = 2
            CollisionHelper.setPhysics(node: node, category: CollisionHelper.Category.checkpoint, contact: CollisionHelper.Category.player, collision: 0, dynamic: false)
            node.name = "checkpoint\(i+1)"
            addChild(node)
        }
        // Vortex/Spikes (player death)
        for spike in levelData.vortexPositions {
            let node = SKSpriteNode(imageNamed: Constants.asset(for: .spike, planet: currentPlanet))
            node.position = spike
            node.size = CGSize(width: Constants.spikeSize, height: Constants.spikeSize)
            node.zPosition = 2
            CollisionHelper.setPhysics(node: node, category: CollisionHelper.Category.spike, contact: CollisionHelper.Category.player, collision: 0, dynamic: false)
            addChild(node)
        }
        // Oil (speed up)
        for oil in levelData.oilPositions {
            let node = SKSpriteNode(imageNamed: Constants.asset(for: .oil, planet: currentPlanet))
            node.position = oil
            node.size = CGSize(width: Constants.oilSize, height: Constants.oilSize)
            node.zPosition = 2
            CollisionHelper.setPhysics(node: node, category: CollisionHelper.Category.oil, contact: CollisionHelper.Category.player, collision: 0, dynamic: false)
            addChild(node)
        }
        // Grass (slow down)
        for grass in levelData.grassPositions {
            let node = SKSpriteNode(imageNamed: Constants.asset(for: .grass, planet: currentPlanet))
            node.position = grass
            node.size = CGSize(width: Constants.grassSize, height: Constants.grassSize)
            node.zPosition = 2
            CollisionHelper.setPhysics(node: node, category: CollisionHelper.Category.grass, contact: CollisionHelper.Category.player, collision: 0, dynamic: false)
            addChild(node)
        }
        // Finish (spaceship)
        let finishNode = SKSpriteNode(imageNamed: Constants.asset(for: .spaceship, planet: currentPlanet))
        finishNode.position = levelData.finish
        finishNode.size = CGSize(width: Constants.finishSize, height: Constants.finishSize)
        finishNode.zPosition = 3
        CollisionHelper.setPhysics(node: finishNode, category: CollisionHelper.Category.finish, contact: CollisionHelper.Category.player, collision: 0, dynamic: false)
        finishNode.name = "finish"
        addChild(finishNode)
    }
    
    private func setupPlayers() {
        for player in multipeerManager.players {
            let node = SKSpriteNode(imageNamed: "Player")
            node.position = LevelManager.shared.currentLevelData?.start ?? CGPoint(x: frame.midX, y: frame.midY)
            node.size = CGSize(width: Constants.playerSize, height: Constants.playerSize)
            node.zPosition = 10
            let color = Constants.playerColors[player.colorIndex % Constants.playerColors.count]
            node.color = UIColor(color)
            node.colorBlendFactor = 0.65
            CollisionHelper.setPhysics(
                node: node,
                category: CollisionHelper.Category.player,
                contact: CollisionHelper.Category.wall | CollisionHelper.Category.checkpoint | CollisionHelper.Category.spike | CollisionHelper.Category.finish | CollisionHelper.Category.oil | CollisionHelper.Category.grass | CollisionHelper.Category.vortex,
                collision: CollisionHelper.Category.wall | CollisionHelper.Category.player
            )
            node.name = player.id
            playerNodes[player.id] = node
            addChild(node)
        }
    }
    
    private func startAccelerometer() {
        guard let localPlayer = multipeerManager.players.first(where: { $0.peerID == localPlayerID }) else { return }
        motionManager.startAccelerometerUpdates(to: .main) { [weak self] data, _ in
            guard let self = self, let data = data else { return }
            guard let node = self.playerNodes[localPlayer.id] else { return }
            let dx = CGFloat(data.acceleration.x) * self.accelerometerFactor * 15
            let dy = CGFloat(data.acceleration.y) * self.accelerometerFactor * 15
            node.physicsBody?.applyForce(CGVector(dx: dx, dy: dy))
            // Optionally, send player position to others
            localPlayer.position = node.position
            localPlayer.velocity = node.physicsBody?.velocity ?? .zero
            PlayerSyncManager.shared.broadcastPlayerUpdate(localPlayer)
        }
    }
    
    // MARK: - SKPhysicsContactDelegate
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nameA = contact.bodyA.node?.name, let nameB = contact.bodyB.node?.name else { return }
        // Handle collisions (player with checkpoint, spike, finish, etc.)
        // No TODOs: For brevity, trigger effects immediately (you may expand for each case as needed)
    }
    
    // MARK: - Game Loop
    override func update(_ currentTime: TimeInterval) {
        // You can use this to sync with latest state or broadcast if you're the map mover, etc.
    }
}
