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
    
    // Returns true if the position is near any edge (within tolerance)
    func isAtScreenEdge(_ position: CGPoint, tolerance: CGFloat = 16) -> Bool {
        guard let levelData = LevelManager.shared.currentLevelData else { return false }
        let minX: CGFloat = 0
        let minY: CGFloat = 0
        let maxX: CGFloat = CGFloat(levelData.width) * levelData.tileSize
        let maxY: CGFloat = CGFloat(levelData.height) * levelData.tileSize
        return abs(position.x - minX) < tolerance ||
        abs(position.x - maxX) < tolerance ||
        abs(position.y - minY) < tolerance ||
        abs(position.y - maxY) < tolerance
    }
    
    // Returns true if the position is at a specific edge
    func isAtSpecificEdge(_ position: CGPoint, edge: EdgeRole, tolerance: CGFloat = 16) -> Bool {
        guard let levelData = LevelManager.shared.currentLevelData else { return false }
        let minX: CGFloat = 0
        let minY: CGFloat = 0
        let maxX: CGFloat = CGFloat(levelData.width) * levelData.tileSize
        let maxY: CGFloat = CGFloat(levelData.height) * levelData.tileSize
        switch edge {
        case .left:
            return abs(position.x - minX) < tolerance
        case .right:
            return abs(position.x - maxX) < tolerance
        case .top:
            return abs(position.y - maxY) < tolerance
        case .bottom:
            return abs(position.y - minY) < tolerance
        }
    }
    
    func moveCamera(for edge: EdgeRole) {
        guard let camera = self.camera, let levelData = LevelManager.shared.currentLevelData else { return }
        let moveAmount: CGFloat = levelData.tileSize * 2 // Move 2 tiles per camera scroll
        var newPosition = camera.position
        
        switch edge {
        case .left:
            newPosition.x = max(newPosition.x - moveAmount, size.width / 2)
        case .right:
            newPosition.x = min(newPosition.x + moveAmount, CGFloat(levelData.width) * levelData.tileSize - size.width / 2)
        case .top:
            newPosition.y = min(newPosition.y + moveAmount, CGFloat(levelData.height) * levelData.tileSize - size.height / 2)
        case .bottom:
            newPosition.y = max(newPosition.y - moveAmount, size.height / 2)
        }
        
        let action = SKAction.move(to: newPosition, duration: 0.2)
        camera.run(action)
        // After moving, broadcast the position
        PlayerSyncManager.shared.broadcastCameraPosition(newPosition)
    }
    
    func centerCamera(on position: CGPoint) {
        camera?.run(SKAction.move(to: position, duration: 0.2))
    }
    
    func handlePlayerDeath(_ playerID: String) {
        // Example: show popup, decrease lives, respawn at last checkpoint, etc.
        // You can expand this based on your full game logic
        print("Player \(playerID) died!")
        // Play sound, show popup, decrement lives, etc.
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nameA = contact.bodyA.node?.name, let nameB = contact.bodyB.node?.name else { return }
        
        // Determine which player, which edge
        for (playerID, node) in playerNodes {
            if isAtScreenEdge(node.position) {
                guard let player = MultipeerManager.shared.players.first(where: { $0.id == playerID }) else { continue }
                if let assignedEdge = player.assignedEdge,
                   isAtSpecificEdge(node.position, edge: assignedEdge) {
                    // This player is the mapMover for this edge → move map/camera!
                    moveCamera(for: assignedEdge)
                    // Sync camera movement as needed
                } else {
                    // Not mapMover for this edge (or normal) → player dies
                    handlePlayerDeath(playerID)
                }
            }
        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Game sync logic if needed
    }
}
