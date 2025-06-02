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
    private var gameCamera: SKCameraNode!
    
    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        setupPhysics()
        setupCamera()
        setupCollisionSystem()
        setupLevel()
        setupPlayers()
        startAccelerometer()
        
        print("[GameScene] Scene initialized with \(multipeerManager.players.count) players")
    }
    
    deinit {
        motionManager.stopAccelerometerUpdates()
    }
    
    // MARK: - Setup Methods
    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }
    
    private func setupCamera() {
        gameCamera = SKCameraNode()
        camera = gameCamera
        addChild(gameCamera)
        
        guard let levelData = levelManager.currentLevelData else { return }
        
        // Position camera at spawn point initially
        gameCamera.position = levelData.spawn
        
        // Setup CameraManager with this scene and camera
        cameraManager.setupCamera(scene: self, camera: gameCamera)
        
        print("[GameScene] Camera setup at spawn: \(levelData.spawn)")
    }
    
    private func setupLevel() {
        guard let levelData = levelManager.currentLevelData else {
            print("[GameScene] ERROR: No level data available")
            return
        }
        
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
        let bg = SKSpriteNode(imageNamed: "Background_\(currentPlanet)")
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
        for pos in levelData.wallPositions {
            let wall = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .wall, planet: currentPlanet),
                size: tileSize,
                category: CollisionHelper.Category.wall,
                contact: 0,
                collision: CollisionHelper.Category.player,
                zPosition: 1
            )
            addChild(wall)
        }
    }
    
    private func setupCheckpoints(levelData: LevelData, tileSize: CGFloat) {
        checkpointNodes.removeAll()
        
        for (index, pos) in levelData.checkpointPositions.enumerated() {
            let checkpoint = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .checkpoint, planet: currentPlanet),
                size: Constants.checkpointRadius * 2,
                category: CollisionHelper.Category.checkpoint,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            checkpoint.name = "checkpoint_\(index + 1)"
            checkpointNodes.append(checkpoint)
            addChild(checkpoint)
        }
    }
    
    private func setupHazards(levelData: LevelData, tileSize: CGFloat) {
        // Vortexes
        for pos in levelData.vortexPositions {
            let vortex = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .vortex, planet: currentPlanet),
                size: Constants.vortexSize,
                category: CollisionHelper.Category.vortex,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            vortex.name = "vortex"
            addChild(vortex)
        }
        
        // Spikes (border hazards)
        for pos in levelData.spikePositions {
            let spike = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .spike, planet: currentPlanet),
                size: Constants.spikeSize,
                category: CollisionHelper.Category.spike,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            spike.name = "spike"
            addChild(spike)
        }
    }
    
    private func setupPowerUps(levelData: LevelData, tileSize: CGFloat) {
        powerUpNodes.removeAll()
        
        // Oil power-ups
        for (index, pos) in levelData.oilPositions.enumerated() {
            let oil = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .oil, planet: currentPlanet),
                size: Constants.oilSize,
                category: CollisionHelper.Category.oil,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            let nodeID = "oil_\(index)"
            oil.name = nodeID
            powerUpNodes[nodeID] = oil
            addChild(oil)
        }
        
        // Grass power-ups
        for (index, pos) in levelData.grassPositions.enumerated() {
            let grass = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .grass, planet: currentPlanet),
                size: Constants.grassSize,
                category: CollisionHelper.Category.grass,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 2
            )
            let nodeID = "grass_\(index)"
            grass.name = nodeID
            powerUpNodes[nodeID] = grass
            addChild(grass)
        }
    }
    
    private func setupFinish(levelData: LevelData, tileSize: CGFloat) {
        for pos in levelData.finishPositions {
            let finish = createTileNode(
                at: pos,
                imageName: Constants.asset(for: .spaceship, planet: currentPlanet),
                size: Constants.finishSize,
                category: CollisionHelper.Category.finish,
                contact: CollisionHelper.Category.player,
                collision: 0,
                zPosition: 3
            )
            finish.name = "finish"
            addChild(finish)
        }
    }
    
    private func setupPlayers() {
        guard let levelData = levelManager.currentLevelData else { return }
        
        playerNodes.removeAll()
        
        for (index, player) in multipeerManager.players.enumerated() {
            let playerNode = SKSpriteNode(imageNamed: "Player")
            playerNode.position = levelData.spawn
            playerNode.size = CGSize(width: Constants.playerSize, height: Constants.playerSize)
            playerNode.zPosition = 10
            
            // Apply player color
            let colorIndex = index % Constants.playerColors.count
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
            
            playerNode.name = player.id
            playerNodes[player.id] = playerNode
            addChild(playerNode)
        }
        
        print("[GameScene] \(multipeerManager.players.count) players created")
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
