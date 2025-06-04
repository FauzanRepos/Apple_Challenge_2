//
//  GameScene.swift
//  Space Maze
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SpriteKit
import SwiftUI
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    // MARK: - Managers
    public let gameManager = GameManager.shared
    public let levelManager = LevelManager.shared
    public let multipeerManager = MultipeerManager.shared
    public let audioManager = AudioManager.shared
    public let syncManager = PlayerSyncManager.shared
    public let cameraManager = CameraManager.shared
    public let collisionManager = CollisionManager.shared
    
    // MARK: - Motion and Input
    let motionManager = CMMotionManager()
    
    // MARK: - Game Objects (Public for extension access)
    var playerNodes: [String: SKSpriteNode] = [:]
    var powerUpNodes: [String: SKSpriteNode] = [:]
    var activeEffects: [String: PowerUpEffect] = [:]
    var checkpointNodes: [SKSpriteNode] = []
    
    // MARK: - Game State
    var localPlayerID: String {
        multipeerManager.localPeerID.displayName
    }
    
    private var currentPlanet: Int {
        gameManager.currentPlanet
    }
    
    var accelerometerFactor: CGFloat {
        CGFloat(SettingsManager.shared.controlSensitivity) *
        (SettingsManager.shared.accelerometerInverted ? -1 : 1)
    }
    
    // MARK: - Camera
    public var gameCamera: SKCameraNode!
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        print("[GameScene] Scene initialization started")
        setupPhysics()
        setupCamera()
        setupCollisionSystem()
        print("[GameScene] Checking level data before setup: \(String(describing: levelManager.currentLevelData))")
        setupLevel()
        setupPlayers()
        
        // Start accelerometer after a short delay to ensure everything is set up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            print("[GameScene] Starting accelerometer after delay...")
            self?.startAccelerometer()
        }
        
        print("[GameScene] Scene initialization complete with \(multipeerManager.players.count) players")
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
    
    // MARK: - Setup Methods
    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        // Disable physics debug outlines
        view?.showsPhysics = false
    }
    
    private func setupCamera() {
        print("[GameScene] Setting up camera...")
        
        // Create and configure camera
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        
        print("[GameScene] Camera node created and added to scene")
        
        guard let levelData = levelManager.currentLevelData else {
            print("[GameScene] ERROR: No level data available for camera setup")
            return
        }
        
        // Position camera at spawn point initially
        gameCamera.position = levelData.spawn
        print("[GameScene] Initial camera position set to spawn: \(levelData.spawn)")
        
        // Setup CameraManager with this scene and camera
        cameraManager.setupCamera(scene: self, camera: gameCamera)
        
        // Set camera constraints to keep it within level bounds
        let xRange = SKRange(lowerLimit: 0, upperLimit: CGFloat(levelData.width) * levelData.tileSize)
        let yRange = SKRange(lowerLimit: 0, upperLimit: CGFloat(levelData.height) * levelData.tileSize)
        let constraint = SKConstraint.positionX(xRange, y: yRange)
        gameCamera.constraints = [constraint]
        
        print("[GameScene] Camera setup complete with constraints: x(0-\(CGFloat(levelData.width) * levelData.tileSize)), y(0-\(CGFloat(levelData.height) * levelData.tileSize))")
        
        // Verify camera setup
        print("[GameScene] Camera verification - Position: \(gameCamera.position), Parent: \(String(describing: gameCamera.parent))")
        print("[GameScene] Scene size: \(size), Scale: \(scaleMode)")
    }
    
    private func setupLevel() {
        print("[GameScene] Setting up level...")
        guard let levelData = levelManager.currentLevelData else {
            print("[GameScene] ERROR: No level data available")
            print("[GameScene] LevelManager state: \(String(describing: levelManager))")
            return
        }
        
        print("[GameScene] Level data found: \(String(describing: levelData))")
        let tileSize = levelData.tileSize
        
        // Background
        setupBackground(levelData: levelData, tileSize: tileSize)
        
        // Level elements
        setupWalls(levelData: levelData, tileSize: tileSize)
        setupCheckpoints(levelData: levelData, tileSize: tileSize)
        setupHazards(levelData: levelData, tileSize: tileSize)
        setupPowerUps(levelData: levelData, tileSize: tileSize)
        setupFinish(levelData: levelData, tileSize: tileSize)
        
        print("[GameScene] Level setup complete for Planet \(currentPlanet)")
    }
    
    private func setupBackground(levelData: LevelData, tileSize: CGFloat) {
        let bgName = "background"
        print("[GameScene] Loading background: \(bgName)")
        let bg = SKSpriteNode(imageNamed: bgName)
        if bg.texture == nil {
            print("[GameScene] WARNING: Failed to load background texture: \(bgName)")
        }
        bg.position = CGPoint(
            x: CGFloat(levelData.width) * tileSize / 2,
            y: CGFloat(levelData.height) * tileSize / 2
        )
        bg.size = CGSize(
            width: CGFloat(levelData.width) * tileSize,
            height: CGFloat(levelData.height) * tileSize
        )
        bg.zPosition = -1
        addChild(bg)
    }
    
    private func setupWalls(levelData: LevelData, tileSize: CGFloat) {
        let wallAsset = Constants.asset(for: .wall, planet: currentPlanet)
        print("[GameScene] Loading wall asset: \(wallAsset)")
        
        for pos in levelData.wallPositions {
            let wall = createTileNode(
                at: pos,
                imageName: wallAsset,
                size: tileSize,
                category: CollisionHelper.Category.wall,
                contact: 0,
                collision: CollisionHelper.Category.player,
                zPosition: 1
            )
            if wall.texture == nil {
                print("[GameScene] WARNING: Failed to load wall texture: \(wallAsset)")
            }
            addChild(wall)
        }
    }
    
    private func setupCheckpoints(levelData: LevelData, tileSize: CGFloat) {
        checkpointNodes.removeAll()
        let checkpointAsset = Constants.asset(for: .checkpoint, planet: currentPlanet)
        print("[GameScene] Loading checkpoint asset: \(checkpointAsset)")
        
        for (index, pos) in levelData.checkpointPositions.enumerated() {
            let checkpoint = createTileNode(
                at: pos,
                imageName: checkpointAsset,
                size: Constants.checkpointRadius * 2,
                category: CollisionHelper.Category.checkpoint,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            if checkpoint.texture == nil {
                print("[GameScene] WARNING: Failed to load checkpoint texture: \(checkpointAsset)")
            }
            checkpoint.name = "checkpoint_\(index + 1)"
            checkpointNodes.append(checkpoint)
            addChild(checkpoint)
        }
    }
    
    private func setupHazards(levelData: LevelData, tileSize: CGFloat) {
        // Vortexes
        let vortexAsset = Constants.asset(for: .vortex, planet: currentPlanet)
        print("[GameScene] Loading vortex asset: \(vortexAsset)")
        
        for (index, pos) in levelData.vortexPositions.enumerated() {
            let vortex = createTileNode(
                at: pos,
                imageName: vortexAsset,
                size: Constants.vortexSize,
                category: CollisionHelper.Category.vortex,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            if vortex.texture == nil {
                print("[GameScene] WARNING: Failed to load vortex texture: \(vortexAsset)")
            }
            vortex.name = "vortex_\(index)"
            
            // Debug print for vortex physics
            print("[GameScene] Setting up vortex physics:")
            print("- Name: \(vortex.name ?? "unknown")")
            print("- Position: \(pos)")
            print("- Size: \(Constants.vortexSize)")
            print("- Category: \(CollisionHelper.Category.vortex)")
            print("- Contact: \(CollisionHelper.Category.player)")
            
            addChild(vortex)
        }
        
        // Spikes (border hazards)
        let spikeAsset = Constants.asset(for: .spike, planet: currentPlanet)
        print("[GameScene] Loading spike asset: \(spikeAsset)")
        
        for (index, pos) in levelData.spikePositions.enumerated() {
            let spike = createTileNode(
                at: pos,
                imageName: spikeAsset,
                size: Constants.spikeSize,
                category: CollisionHelper.Category.spike,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            if spike.texture == nil {
                print("[GameScene] WARNING: Failed to load spike texture: \(spikeAsset)")
            }
            spike.name = "spike_\(index)"
            addChild(spike)
        }
    }
    
    private func setupPowerUps(levelData: LevelData, tileSize: CGFloat) {
        powerUpNodes.removeAll()
        
        // Oil power-ups
        let oilAsset = Constants.asset(for: .oil, planet: currentPlanet)
        print("[GameScene] Loading oil asset: \(oilAsset)")
        
        for (index, pos) in levelData.oilPositions.enumerated() {
            let oil = createTileNode(
                at: pos,
                imageName: oilAsset,
                size: Constants.oilSize,
                category: CollisionHelper.Category.oil,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            if oil.texture == nil {
                print("[GameScene] WARNING: Failed to load oil texture: \(oilAsset)")
            }
            let nodeID = "oil_\(index)"
            oil.name = nodeID
            powerUpNodes[nodeID] = oil
            addChild(oil)
        }
        
        // Grass power-ups
        let grassAsset = Constants.asset(for: .grass, planet: currentPlanet)
        print("[GameScene] Loading grass asset: \(grassAsset)")
        
        for (index, pos) in levelData.grassPositions.enumerated() {
            let grass = createTileNode(
                at: pos,
                imageName: grassAsset,
                size: Constants.grassSize,
                category: CollisionHelper.Category.grass,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            if grass.texture == nil {
                print("[GameScene] WARNING: Failed to load grass texture: \(grassAsset)")
            }
            let nodeID = "grass_\(index)"
            grass.name = nodeID
            powerUpNodes[nodeID] = grass
            addChild(grass)
        }
    }
    
    private func setupFinish(levelData: LevelData, tileSize: CGFloat) {
        let finishAsset = Constants.asset(for: .spaceship, planet: currentPlanet)
        print("[GameScene] Loading finish asset: \(finishAsset)")
        
        for pos in levelData.finishPositions {
            let finish = createTileNode(
                at: pos,
                imageName: finishAsset,
                size: Constants.finishSize,
                category: CollisionHelper.Category.finish,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 3
            )
            if finish.texture == nil {
                print("[GameScene] WARNING: Failed to load finish texture: \(finishAsset)")
            }
            finish.name = "finish"
            addChild(finish)
        }
    }
    
    private func setupPlayers() {
        guard let levelData = levelManager.currentLevelData else { return }
        
        playerNodes.removeAll()
        print("[GameScene] Loading player asset: player")
        print("[GameScene] Current players in multipeerManager: \(multipeerManager.players.count)")
        print("[GameScene] Local player ID: \(localPlayerID)")
        
        for (index, player) in multipeerManager.players.enumerated() {
            print("[GameScene] Creating player node for: \(player.id)")
            let playerNode = SKSpriteNode(imageNamed: "player")
            if playerNode.texture == nil {
                print("[GameScene] WARNING: Failed to load player texture: player")
            }
            playerNode.position = levelData.spawn
            playerNode.size = CGSize(width: Constants.playerSize / 2, height: Constants.playerSize / 2)
            playerNode.zPosition = 10
            
            // Apply player color
            let colorIndex = player.colorIndex % Constants.playerColors.count
            let color = Constants.playerColors[colorIndex]
            playerNode.color = UIColor(color)
            playerNode.colorBlendFactor = 0.65
            
            // Physics setup
            CollisionHelper.setPhysics(
                node: playerNode,
                category: CollisionHelper.Category.player,
                contact: CollisionHelper.Category.wall |
                CollisionHelper.Category.checkpoint |
                CollisionHelper.Category.spike |
                CollisionHelper.Category.finish |
                CollisionHelper.Category.oil |
                CollisionHelper.Category.grass |
                CollisionHelper.Category.vortex,
                collision: CollisionHelper.Category.wall | CollisionHelper.Category.player
            )
            
            // Debug print for player physics
            print("[GameScene] Setting up player physics for \(player.id):")
            print("- Position: \(levelData.spawn)")
            print("- Size: \(playerNode.size)")
            print("- Category: \(CollisionHelper.Category.player)")
            print("- Contact: \(CollisionHelper.Category.vortex)")
            
            playerNode.name = player.id
            playerNodes[player.id] = playerNode
            addChild(playerNode)
        }
        
        print("[GameScene] \(multipeerManager.players.count) players created")
        print("[GameScene] Player nodes created: \(playerNodes.keys.joined(separator: ", "))")
    }
    
    private func createTileNode(
        at position: CGPoint,
        imageName: String,
        size: CGFloat,
        category: UInt32,
        contact: UInt32,
        collision: UInt32,
        zPosition: CGFloat
    ) -> SKSpriteNode {
        let node = SKSpriteNode(imageNamed: imageName)
        node.position = position
        node.size = CGSize(width: size, height: size)
        node.zPosition = zPosition
        
        // Set a default name if none is provided
        if node.name == nil {
            node.name = "tile_\(imageName)_\(position.x)_\(position.y)"
        }
        
        print("[GameScene] Creating tile node:")
        print("- Name: \(node.name ?? "unknown")")
        print("- Position: \(position)")
        print("- Size: \(size)")
        print("- Category: \(category)")
        
        CollisionHelper.setPhysics(
            node: node,
            category: category,
            contact: contact,
            collision: collision,
            dynamic: false
        )
        
        return node
    }
    
    // MARK: - Public Methods for Network Updates
    func updatePlayerPosition(_ playerID: String, position: CGPoint, velocity: CGVector) {
        guard let playerNode = playerNodes[playerID] else { return }
        
        // Smooth interpolation for network players
        if playerID != localPlayerID {
            let currentPos = playerNode.position
            let newPos = currentPos.interpolated(to: position, factor: 0.1)
            playerNode.position = newPos
            playerNode.physicsBody?.velocity = velocity
        }
    }
    
    // MARK: - Physics Contact Delegate
//    func didBegin(_ contact: SKPhysicsContact) {
//        print("[GameScene] Physics contact began:")
//        print("- Body A: \(contact.bodyA.categoryBitMask)")
//        print("- Body B: \(contact.bodyB.categoryBitMask)")
//        
//        collisionManager.handleCollision(between: contact.bodyA, and: contact.bodyB)
//    }
    
    func didEnd(_ contact: SKPhysicsContact) {
        // Handle contact end if needed
    }
}

// MARK: - Power-Up Effect System
struct PowerUpEffect {
    let type: PowerUpType
    let startTime: TimeInterval
    let duration: TimeInterval = 2.0
    
    var isActive: Bool {
        CACurrentMediaTime() - startTime < duration
    }
}
