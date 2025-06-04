//
//  GameScene.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import CoreMotion
import SpriteKit
import SwiftUI

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case checkpoint = 4
    case vortex = 8
    case finish = 16
    case spike = 32
}

enum PlayerType {
    case mapMover   // Player that can move the map
    case regular    // Player that encounters spikes at screen edge
}

enum GameState {
    case playing
    case gameOver
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var gameState: GameState = .playing
    var playerType: PlayerType = .mapMover  // Default player type (can be set before game starts)
    var lastTouchPosition: CGPoint?
    var worldNode: SKNode!  // Container for all level elements
    
    var motionManager: CMMotionManager!
    
    var isGameOver = false
    var scoreLabel: SKLabelNode!
    var livesLabel: SKLabelNode!
    var lives = 5 {
        didSet {
            livesLabel?.text = "Lives: \(lives)"
        }
    }
    
    var score = 1 {
        didSet {
            updateScoreLabel()
            onScoreUpdate?(score)
        }
    }
    
    // Screen dimensions and boundaries
    var screenWidth: CGFloat = 0
    var screenHeight: CGFloat = 0
    var mapWidth: CGFloat = 0
    var mapHeight: CGFloat = 0
    
    // Screen edge detection areas
    var leftEdgeMargin: CGFloat = 150
    var rightEdgeMargin: CGFloat = 150
    var topEdgeMargin: CGFloat = 150
    var bottomEdgeMargin: CGFloat = 150
    var cellSize: CGFloat = 50
    var currentLevel = 1 {
        didSet {
            updateScoreLabel()
        }
    }
    
    // Direction indicator
    var directionIndicator: SKSpriteNode!
    
    // Initial player spawn point (before any checkpoints)
    var initialSpawnPoint = CGPoint.zero  // Changed to zero as default, will be set when loading level
    var lastCheckpoint: CGPoint {
        didSet {
            // Optional: Update any UI or game state when checkpoint changes
        }
    }
    
    var onGameOver: (() -> Void)?
    var onPlayerDeath: (() -> Void)?
    var onCheckpoint: (() -> Void)?
    var onCollision: (() -> Void)?
    var onPowerup: (() -> Void)?
    var onFinish: (() -> Void)?
    var onScoreUpdate: ((Int) -> Void)?
    var onLevelComplete: (() -> Void)?  // Add new callback
    
    // Add near the top of the class
    private var canTriggerDeath = true
    
    func loadLevel() {
        // Track the maximum level dimensions
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        let levelFile = "level\(currentLevel)"
        
        // Set the appropriate background and wall textures based on current level
        let backgroundName = "background\(currentLevel)"
        let wallName = "wall\(currentLevel)"
        
        // Create a properly sized background
        var textureBG = SKTexture(imageNamed: backgroundName)
        
        if textureBG.size() == .zero {
            print("⚠️ Warning: Background image for level \(currentLevel) not found: \(backgroundName)")
            // Fallback to background1 if other backgrounds are missing
            let fallbackBackground = "background1"
            textureBG = SKTexture(imageNamed: fallbackBackground)
            if textureBG.size() == .zero {
                fatalError("🚨 Both level \(currentLevel) and fallback background images are missing!")
            }
        }
        
        // Remove old background if it exists
        worldNode.enumerateChildNodes(withName: "background") { node, _ in
            node.removeFromParent()
        }
        
        // Calculate the proper background size to ensure full coverage
        let extraCoverage: CGFloat = 2.0 // Increase coverage factor
        
        // First determine the minimum size needed to cover both map and screen
        let minRequiredWidth = max(mapWidth, size.width) * extraCoverage
        let minRequiredHeight = max(mapHeight, size.height) * extraCoverage
        
        // Get the texture size and aspect ratio
        let textureSize = textureBG.size()
        let textureAspectRatio = textureSize.width / textureSize.height
        
        // Calculate the final background dimensions
        var backgroundWidth = minRequiredWidth
        var backgroundHeight = minRequiredHeight
        
        // Adjust dimensions to maintain aspect ratio while ensuring minimum coverage
        if backgroundWidth / backgroundHeight > textureAspectRatio {
            // Width is the constraining factor
            backgroundHeight = backgroundWidth / textureAspectRatio
        } else {
            // Height is the constraining factor
            backgroundWidth = backgroundHeight * textureAspectRatio
        }
        
        // Create the background with calculated size
        let background = SKSpriteNode(
            texture: textureBG,
            size: CGSize(width: backgroundWidth, height: backgroundHeight)
        )
        
        // Center the background in the world coordinate system
        background.position = CGPoint(x: backgroundWidth/2, y: backgroundHeight/2)
        background.zPosition = -1
        background.name = "background"
        
        // Set the blend mode to replace to prevent any transparency issues
        background.blendMode = .replace
        
        worldNode.addChild(background)
        
        if let levelPath = Bundle.main.path(forResource: levelFile, ofType: "txt") {
            if let levelString = try? String(contentsOfFile: levelPath) {
                let lines = levelString.components(separatedBy: "\n")
                
                for (row, line) in lines.reversed().enumerated() {
                    for (column, letter) in line.enumerated() {
                        let position = CGPoint(
                            x: (cellSize * CGFloat(column)) + (cellSize/16),
                            y: (cellSize * CGFloat(row)) + (cellSize/16)
                        )
                        
                        // Update maximum coordinates
                        maxX = max(maxX, position.x + cellSize/2)
                        maxY = max(maxY, position.y + cellSize/2)
                        
                        if letter == "s" {  // Add spawn point handling
                            initialSpawnPoint = position
                            lastCheckpoint = position  // Set initial checkpoint to spawn point
                        } else if letter == "x" {
                            // load wall with level-specific texture
                            var wallTexture = SKTexture(imageNamed: wallName)
                            
                            if wallTexture.size() == .zero {
                                print("⚠️ Warning: Wall texture for level \(currentLevel) not found: \(wallName)")
                                // Fallback to wall1 if other walls are missing
                                let fallbackWall = "wall1"
                                wallTexture = SKTexture(imageNamed: fallbackWall)
                                if wallTexture.size() == .zero {
                                    fatalError("🚨 Both level \(currentLevel) and fallback wall textures are missing!")
                                }
                            }
                            
                            let node = SKSpriteNode(
                                texture: wallTexture,
                                size: CGSize(width: cellSize, height: cellSize)
                            )
                            node.position = position
                            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                            node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                            node.physicsBody?.isDynamic = false
                            guard worldNode.inParentHierarchy(self) else {
                                fatalError("⚠️ worldNode is no longer attached to scene!")
                            }
                            worldNode.addChild(node)
                        } else if letter == "v"  {
                            // load vortex
                            let imageName = "vortex"
                            let texture = SKTexture(imageNamed: imageName)
                            
                            if texture.size() == .zero {
                                fatalError("🚨 Image '\(imageName)' is missing or invalid.")
                            }
                            
                            let node = SKSpriteNode(
                                texture: texture,
                                size: CGSize(width: cellSize, height: cellSize)
                            )
                            node.name = "vortex"
                            node.position = position
                            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            guard worldNode.inParentHierarchy(self) else {
                                fatalError("⚠️ worldNode is no longer attached to scene!")
                            }
                            worldNode.addChild(node)
                        } else if letter == "c"  {
                            // load checkpoint
                            let imageName = "checkpoint"
                            let texture = SKTexture(imageNamed: imageName)
                            
                            if texture.size() == .zero {
                                fatalError("🚨 Image '\(imageName)' is missing or invalid.")
                            }
                            
                            let node = SKSpriteNode(
                                texture: texture,
                                size: CGSize(width: cellSize, height: cellSize)
                            )
                            node.name = "checkpoint"
                            node.size = CGSize(width: cellSize, height: cellSize)
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.checkpoint.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
                            guard worldNode.inParentHierarchy(self) else {
                                fatalError("⚠️ worldNode is no longer attached to scene!")
                            }
                            worldNode.addChild(node)
                            
                            // Add a pulsing animation to make checkpoints more visible
                            let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
                            let scaleDown = SKAction.scale(to: 0.9, duration: 0.5)
                            let pulse = SKAction.sequence([scaleUp, scaleDown])
                            node.run(SKAction.repeatForever(pulse))
                        } else if letter == "f"  {
                            // load animated rocket as finish
                            let texture = SKTexture(imageNamed: "rocket")
                            
                            if texture.size() == .zero {
                                fatalError("🚨 Rocket image is missing or invalid.")
                            }
                            
                            let node = SKSpriteNode(
                                texture: texture,
                                size: CGSize(width: cellSize * 1.2, height: cellSize * 1.2))
                            
                            // Add a hover effect
                            let moveUp = SKAction.moveBy(x: 0, y: 10, duration: 1.0)
                            let moveDown = SKAction.moveBy(x: 0, y: -10, duration: 1.0)
                            let hoverSequence = SKAction.sequence([moveUp, moveDown])
                            
                            // Combine animations
                            let animations = SKAction.group([
                                SKAction.repeatForever(hoverSequence)
                            ])
                            
                            node.run(animations)
                            node.name = "finish"
                            
                            // Use a smaller physics body for better collision
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 3)
                            node.physicsBody?.isDynamic = false
                            node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
                            
                            guard worldNode.inParentHierarchy(self) else {
                                fatalError("⚠️ worldNode is no longer attached to scene!")
                            }
                            worldNode.addChild(node)
                        }
                    }
                }
                
                // Store map dimensions
                mapWidth = maxX
                mapHeight = maxY
            }
        }
    }
    
    func createPlayer() {
        let imageName = "player1"
        let texture = SKTexture(imageNamed: imageName)

        if texture.size() == .zero {
            fatalError("🚨 Image '\(imageName)' is missing or invalid.")
        }

        // Define a base player size
        let basePlayerSize: CGFloat = 32

        // Scale the player size relative to the cellSize.  This makes the player
        // proportional to the level's overall scale.
        let scaledPlayerSize = basePlayerSize * (cellSize / 50)  // Assuming a base cellSize of 50

        player = SKSpriteNode(
            texture: texture,
            size: CGSize(width: scaledPlayerSize, height: scaledPlayerSize)
        )
        player.position = lastCheckpoint  // Use last checkpoint position

        // Scale the physics body radius based on the scaled player size
        let physicsBodyRadius = scaledPlayerSize / 2
        player.physicsBody = SKPhysicsBody(circleOfRadius: physicsBodyRadius)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5

        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.checkpoint.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue | CollisionTypes.spike.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
        guard worldNode.inParentHierarchy(self) else {
            fatalError("⚠️ worldNode is no longer attached to scene!")
        }
        worldNode.addChild(player)

        // Add a brief invulnerability effect when spawning
        let fadeAction = SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.1),
            SKAction.fadeAlpha(to: 1.0, duration: 0.1)
        ])

        player.run(SKAction.repeat(fadeAction, count: 5))
    }
    
    func updateDirectionIndicator() {
        // Find the finish node
        guard worldNode.inParentHierarchy(self) else {
            fatalError("⚠️ worldNode is no longer attached to scene!")
        }
        guard let finish = worldNode.childNode(withName: "finish") else { return }
        
        // Convert finish position from world coordinates to scene coordinates
        let finishPositionInScene = worldNode.convert(finish.position, to: self)
        
        // Use direction indicator's position (which is already in scene coordinates)
        let indicatorPosition = directionIndicator.position
        
        let vectorToFinish = CGVector(dx: finishPositionInScene.x - indicatorPosition.x,
                                    dy: finishPositionInScene.y - indicatorPosition.y)
        
        // Calculate angle to the finish point
        let angle = atan2(vectorToFinish.dy, vectorToFinish.dx) - .pi/2
        
        // Set the angle of the direction indicator
        directionIndicator.zRotation = angle
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            lastTouchPosition = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        guard isGameOver == false else { return }
        
#if targetEnvironment(simulator)
        if let currentTouch = lastTouchPosition {
            // Convert touch position from scene coordinates to world coordinates
            let touchInWorld = worldNode.convert(currentTouch, from: self)
            let diff = CGPoint(x: touchInWorld.x - player.position.x, y: touchInWorld.y - player.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
#else
        if let accelerometerData = motionManager.accelerometerData {
            physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 10, dy: accelerometerData.acceleration.y * 10)
        }
#endif
        
        // Update direction indicator
        updateDirectionIndicator()
        
        // Check if player is near screen edge and scroll map if necessary
        checkAndScrollMap()
    }
    
    func checkAndScrollMap() {
        guard worldNode.inParentHierarchy(self) else {
            fatalError("⚠️ worldNode is no longer attached to scene!")
        }
        // Get player's position in the scene coordinates
        let playerPositionInScene = worldNode.convert(player.position, to: self)
        
        // Determine if player is near any edge of the screen
        let nearLeftEdge = playerPositionInScene.x < leftEdgeMargin
        let nearRightEdge = playerPositionInScene.x > frame.width - rightEdgeMargin
        let nearTopEdge = playerPositionInScene.y > frame.height - topEdgeMargin
        let nearBottomEdge = playerPositionInScene.y < bottomEdgeMargin
        
        // Calculate the amount to scroll
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        
        if playerType == .mapMover {
            // For map movers, move the map when near edge
            if nearLeftEdge {
                dx = 10  // Scroll right (move worldNode right)
            } else if nearRightEdge {
                dx = -10  // Scroll left (move worldNode left)
            }
            
            if nearTopEdge {
                dy = -10  // Scroll down (move worldNode down)
            } else if nearBottomEdge {
                dy = 10  // Scroll up (move worldNode up)
            }
            
            // Apply the scroll if needed
            if dx != 0 || dy != 0 {
                print("Scrolling map dx: \(dx), dy: \(dy)")
                scrollMap(dx: dx, dy: dy)
            }
        } else if (nearLeftEdge || nearRightEdge || nearTopEdge || nearBottomEdge) {
            // For regular players, they "die" when they hit the edge
            if canTriggerDeath {
                handleVortexCollision()
            }
        }
    }
    
    func scrollMap(dx: CGFloat, dy: CGFloat) {
        // Move the world node to scroll the map
        guard worldNode.inParentHierarchy(self) else {
            fatalError("⚠️ worldNode is no longer attached to scene!")
        }
        worldNode.position = CGPoint(x: worldNode.position.x + dx, y: worldNode.position.y + dy)
        
        // Ensure the player stays within the visible area after scrolling
        constrainPlayer()
    }
    
    func constrainPlayer() {
        // Optional: Add logic here to ensure the player doesn't move outside
        // any desired boundaries of the larger level
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        guard let nodeA = contact.bodyA.node,
              let nodeB = contact.bodyB.node else { return }
        
        if nodeA == player {
            handleCollision(between: player, and: nodeB)
        } else if nodeB == player {
            handleCollision(between: player, and: nodeA)
        }
    }
    
    func handleCollision(between player: SKNode, and other: SKNode) {
        switch other.name {
        case "checkpoint":
            handleCheckpointCollision(at: player.position)
            onCheckpoint?()
            other.removeFromParent() // Remove the checkpoint when collected
            
        case "vortex":
            if canTriggerDeath {
                handleVortexCollision()
            }
            
        case "finish":
            onFinish?()
            handleFinishCollision()
            
        case "powerup":
            other.removeFromParent()
            onPowerup?()
            
        case "wall", "spike":
            onCollision?()
            
        default:
            break
        }
    }
    
    func handleCheckpointCollision(at position: CGPoint) {
        // Save the position and increment score
        lastCheckpoint = position
        score += 1
    }
    
    func respawnFromCheckpoint() {
        // Remove the current player with a fade out
        let fadeOut = SKAction.fadeOut(withDuration: 0.2)
        player.run(fadeOut) { [weak self] in
            guard let self = self else { return }
            
            // Remove old player
            self.player.removeFromParent()
            
            // Create a new player at the last checkpoint
            self.createPlayer()
            
            // Add spawn effect with longer invulnerability period
            self.player.alpha = 0
            let fadeIn = SKAction.fadeIn(withDuration: 0.3)
            
            // Create a longer invulnerability period with more visible blinking
            let invulnerabilityBlink = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.2),
                SKAction.fadeAlpha(to: 1.0, duration: 0.2)
            ])
            
            // Increase the number of blinks and add a delay before enabling death
            let blinkSequence = SKAction.repeat(invulnerabilityBlink, count: 5)
            
            // Add a delay after blinking before enabling death trigger
            let enableDeathTrigger = SKAction.run { [weak self] in
                self?.canTriggerDeath = true
            }
            
            let spawnSequence = SKAction.sequence([
                fadeIn,
                blinkSequence,
                SKAction.wait(forDuration: 0.5), // Add a grace period
                enableDeathTrigger
            ])
            
            self.player.run(spawnSequence)
            
            // Re-enable gameplay immediately
            self.isGameOver = false
        }
    }
    
    func handleVortexCollision() {
        // Only handle collision if we're not already in game over state and can trigger death
        guard !isGameOver && canTriggerDeath else { return }
        
        // Prevent multiple death triggers
        canTriggerDeath = false
        isGameOver = true
        
        // Save current score
        onScoreUpdate?(score)
        
        // Disable physics temporarily
        player.physicsBody?.isDynamic = false
        
        // Create death animation
        let fadeOut = SKAction.fadeAlpha(to: 0.2, duration: 0.2)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.2)
        let deathSequence = SKAction.sequence([fadeOut, fadeIn])
        
        player.run(deathSequence) { [weak self] in
            guard let self = self else { return }
            
            // Notify about player death after animation
            self.onPlayerDeath?()
            
            // Respawn the player after a short delay
            let respawnDelay = SKAction.wait(forDuration: 0.5)
            let respawnAction = SKAction.run { [weak self] in
                self?.respawnFromCheckpoint()
            }
            
            self.run(SKAction.sequence([respawnDelay, respawnAction]))
        }
    }
    
    func handleFinishCollision() {
        // Disable player movement
        player.physicsBody?.isDynamic = false
        isGameOver = true
        
        // Create fade out animation
        let fadeOut = SKAction.fadeOut(withDuration: 1.0)
        let fadeIn = SKAction.fadeIn(withDuration: 1.0)
        
        // Run fade out animation
        worldNode.run(fadeOut) { [weak self] in
            guard let self = self else { return }
            
            // Save final score for current level
            self.onScoreUpdate?(self.score)
            
            // Notify about level completion
            self.onLevelComplete?()
            
            // Remove all nodes from worldNode
            self.worldNode.removeAllChildren()
            
            // Load next level
            self.loadLevel()
            
            // Reset checkpoint to initial spawn point
            self.lastCheckpoint = self.initialSpawnPoint
            
            // Create a new player at the initial spawn point
            self.createPlayer()
            
            // Center the world on the spawn point
            let centerX = self.size.width / 2
            let centerY = self.size.height / 2
            self.worldNode.position = CGPoint(
                x: centerX - self.initialSpawnPoint.x,
                y: centerY - self.initialSpawnPoint.y
            )
            
            // Reset score for new level to 1
            self.score = 1
            
            // Run fade in animation
            self.worldNode.run(fadeIn)
            
            // Re-enable gameplay
            self.isGameOver = false
        }
    }
    
    override func didMove(to view: SKView) {
        // Create a world node that will contain all level elements
        worldNode = SKNode()
        addChild(worldNode)
        
        // Calculate the actual visible area for the game
        let playableHeight = size.height
        let playableWidth = size.width
        
        let _ : CGFloat = 31 * cellSize  // 1550 pixels
        let _ : CGFloat = 23 * cellSize // 1150 pixels
        
        // UI elements adjusted for actual playable area
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: playableHeight - 90)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        updateScoreLabel()  // Initialize score label
        
        livesLabel = SKLabelNode(fontNamed: "Chalkduster")
        livesLabel.text = "Lives: 5"
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: playableWidth - 16, y: playableHeight - 90)
        livesLabel.zPosition = 100
        addChild(livesLabel)
        
        // Add direction indicator (triangle)
        let imageName = "Compass"
        let texture = SKTexture(imageNamed: imageName)
        
        if texture.size() == .zero {
            fatalError("🚨 Image '\(imageName)' is missing or invalid.")
        }
        
        directionIndicator = SKSpriteNode(
            texture: texture,
            size: CGSize(width: 32, height: 32)
        )
        directionIndicator.name = "directionIndicator"
        directionIndicator.position = CGPoint(x: playableWidth - 50, y: 50)
        directionIndicator.zPosition = 100
        addChild(directionIndicator)
        
        // Set up screen edge margins based on playable area
        let marginScreen = playerType == .mapMover ? 0.15 : 0.075
        leftEdgeMargin = CGFloat(playableWidth) * marginScreen
        rightEdgeMargin = CGFloat(playableWidth) * marginScreen
        topEdgeMargin = CGFloat(playableHeight) * marginScreen
        bottomEdgeMargin = CGFloat(playableHeight) * marginScreen
        
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
        
        // Calculate a cell size that will fit the level nicely in the playable area
        cellSize = CGFloat(playableWidth / 8) // Adjust divisor based on level width
        
        // Initialize lastCheckpoint to the initial spawn point
        lastCheckpoint = initialSpawnPoint
        
        loadLevel()
        
        // Center the world on the spawn point
        let centerX = size.width / 2
        let centerY = size.height / 2
        worldNode.position = CGPoint(
            x: centerX - initialSpawnPoint.x,
            y: centerY - initialSpawnPoint.y
        )
        
        createPlayer()
        
        // Add spikes if player type is regular
        if playerType == .regular {
            createScreenEdgeSpikes()
        }
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    // Initialize all properties before super.init
    override init(size: CGSize) {
        // Initialize lastCheckpoint with a temporary position
        lastCheckpoint = CGPoint.zero
        
        // Call super.init after initializing all properties
        super.init(size: size)
    }
    
    // Required initializer
    required init?(coder aDecoder: NSCoder) {
        // Initialize lastCheckpoint with a temporary position
        lastCheckpoint = CGPoint.zero
        
        // Call super.init after initializing all properties
        super.init(coder: aDecoder)
    }
    
    func getInwardRotation(for edge: String) -> CGFloat {
        switch edge {
        case "top":
            return 0           // Point downward
        case "bottom":
            return .pi         // Point upward
        case "left":
            return .pi * 0.5   // Point rightward (90 degrees)
        case "right":
            return .pi * 1.5   // Point leftward (270 degrees)
        default:
            return 0
        }
    }

    func createScreenEdgeSpikes() {
        // Remove any existing spikes first
        self.enumerateChildNodes(withName: "spike") { node, _ in
            node.removeFromParent()
        }
        
        let spikeSize = CGSize(width: 32, height: 32)
        let spikeSpacing: CGFloat = spikeSize.width * 1.2 // Slight gap between spikes
        
        // Define UI safe area
        let topSafeArea: CGFloat = 60 // Leave space for score and lives labels
        
        // Load spike texture
        let texture = SKTexture(imageNamed: "spike")
        if texture.size() == .zero {
            print("⚠️ Warning: Spike texture not found")
            return
        }
        
        // Calculate number of spikes needed for each edge
        let horizontalCount = Int(size.width / spikeSpacing)
        let verticalCount = Int((size.height - topSafeArea) / spikeSpacing)
        
        // Create spikes for each edge
        for i in 0..<horizontalCount {
            // Bottom edge - spikes pointing up
            let bottomSpike = SKSpriteNode(texture: texture, size: spikeSize)
            bottomSpike.position = CGPoint(x: CGFloat(i) * spikeSpacing + spikeSize.width/2, y: spikeSize.height/2)
            bottomSpike.zRotation = getInwardRotation(for: "bottom")
            bottomSpike.name = "spike"
            bottomSpike.zPosition = 100
            setupSpikePhysics(for: bottomSpike)
            addChild(bottomSpike)
            
            // Top edge - spikes pointing down (below the UI elements)
            let topSpike = SKSpriteNode(texture: texture, size: spikeSize)
            topSpike.position = CGPoint(x: CGFloat(i) * spikeSpacing + spikeSize.width/2, y: size.height - topSafeArea)
            topSpike.zRotation = getInwardRotation(for: "top")
            topSpike.name = "spike"
            topSpike.zPosition = 100
            setupSpikePhysics(for: topSpike)
            addChild(topSpike)
        }
        
        for i in 0..<verticalCount {
            // Calculate Y position accounting for top safe area
            let yPos = CGFloat(i) * spikeSpacing + spikeSize.height/2 + spikeSize.height
            
            // Left edge - spikes pointing right
            let leftSpike = SKSpriteNode(texture: texture, size: spikeSize)
            leftSpike.position = CGPoint(x: spikeSize.width/2, y: yPos)
            leftSpike.zRotation = getInwardRotation(for: "left")
            leftSpike.name = "spike"
            leftSpike.zPosition = 100
            setupSpikePhysics(for: leftSpike)
            addChild(leftSpike)
            
            // Right edge - spikes pointing left
            let rightSpike = SKSpriteNode(texture: texture, size: spikeSize)
            rightSpike.position = CGPoint(x: size.width - spikeSize.width/2, y: yPos)
            rightSpike.zRotation = getInwardRotation(for: "right")
            rightSpike.name = "spike"
            rightSpike.zPosition = 100
            setupSpikePhysics(for: rightSpike)
            addChild(rightSpike)
        }
    }
    
    func setupSpikePhysics(for spike: SKSpriteNode) {
        spike.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: spike.size.width * 0.8, height: spike.size.height * 0.8))
        spike.physicsBody?.isDynamic = false
        spike.physicsBody?.categoryBitMask = CollisionTypes.spike.rawValue
        spike.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        spike.physicsBody?.collisionBitMask = 0
    }
    
    func resetGame() {
        // Reset the game state
        score = 1
        currentLevel = 1
        canTriggerDeath = true
        
        // Remove all nodes from worldNode
        worldNode.removeAllChildren()
        
        // Load level 1
        loadLevel()
        
        // Reset checkpoint to initial spawn point
        lastCheckpoint = initialSpawnPoint
        
        // Create a new player at the initial spawn point with fade in effect
        createPlayer()
        player.alpha = 0
        let fadeIn = SKAction.fadeIn(withDuration: 0.5)
        player.run(fadeIn)
        
        // Center the world on the spawn point
        let centerX = size.width / 2
        let centerY = size.height / 2
        worldNode.position = CGPoint(
            x: centerX - initialSpawnPoint.x,
            y: centerY - initialSpawnPoint.y
        )
        
        // Re-enable gameplay
        isGameOver = false
    }
    
    // Add the updateLives method
    func updateLives(_ newLives: Int) {
        lives = newLives
    }
    
    private func updateScoreLabel() {
        scoreLabel?.text = "Score \(currentLevel).\(score)"
    }
}

