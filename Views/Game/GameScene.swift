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
        let tileSize = levelData.tileSize
        
        // Set background
        let bg = SKSpriteNode(imageNamed: "Background_\(currentPlanet)")
        bg.position = CGPoint(x: frame.midX, y: frame.midY)
        bg.zPosition = -1
        bg.size = CGSize(width: CGFloat(levelData.width) * tileSize, height: CGFloat(levelData.height) * tileSize)
        addChild(bg)
        
        func addTile(at pos: CGPoint, imageName: String, size: CGFloat, category: UInt32, contact: UInt32, collision: UInt32, z: CGFloat, name: String? = nil) {
            let node = SKSpriteNode(imageNamed: imageName)
            node.position = pos
            node.size = CGSize(width: size, height: size)
            node.zPosition = z
            CollisionHelper.setPhysics(node: node, category: category, contact: contact, collision: collision, dynamic: false)
            if let name = name { node.name = name }
            addChild(node)
        }
        
        // Walls
        for pos in levelData.wallPositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .wall, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.wall,
                    contact: 0,
                    collision: CollisionHelper.Category.player,
                    z: 1)
        }
        // Checkpoints
        for (i, pos) in levelData.checkpointPositions.enumerated() {
            addTile(at: pos,
                    imageName: Constants.asset(for: .checkpoint, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.checkpoint,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 2,
                    name: "checkpoint\(i+1)")
        }
        // Vortexes (spikes)
        for pos in levelData.vortexPositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .vortex, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.vortex,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 2)
        }
        // Oil
        for pos in levelData.oilPositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .oil, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.oil,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 2)
        }
        // Grass
        for pos in levelData.grassPositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .grass, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.grass,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 2)
        }
        // Spikes
        for pos in levelData.spikePositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .spike, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.spike,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 2)
        }
        // Finish
        for pos in levelData.finishPositions {
            addTile(at: pos,
                    imageName: Constants.asset(for: .spaceship, planet: currentPlanet),
                    size: tileSize,
                    category: CollisionHelper.Category.finish,
                    contact: CollisionHelper.Category.player,
                    collision: 0,
                    z: 3,
                    name: "finish")
        }
    }
    
    private func setupPlayers() {
        guard let levelData = levelManager.currentLevelData else { return }
        for player in multipeerManager.players {
            let node = SKSpriteNode(imageNamed: "Player")
            node.position = levelData.spawn
            node.size = CGSize(width: levelData.tileSize, height: levelData.tileSize)
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
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nameA = contact.bodyA.node?.name, let nameB = contact.bodyB.node?.name else { return }
        // Handle collisions (expand as needed)
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Game sync logic if needed
    }
}
