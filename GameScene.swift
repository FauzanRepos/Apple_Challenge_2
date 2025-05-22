//
//  GameScene.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import CoreMotion
import SpriteKit

enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case checkpoint = 4
    case vortex = 8
    case finish = 16
}

enum PlayerType {
    case mapMover   // Player that can move the map
    case regular    // Player that encounters spikes at screen edge
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var playerType: PlayerType = .mapMover  // Default player type (can be set before game starts)
    var lastTouchPosition: CGPoint?
    var worldNode: SKNode!  // Container for all level elements
    
    var motionManager: CMMotionManager!

    var isGameOver = false
    var scoreLabel: SKLabelNode!
    var livesLabel: SKLabelNode!
    var lives = 3 {
        didSet {
            livesLabel.text = "Lives: \(lives)"
        }
    }
    
    var score = 0 {
        didSet  {
            scoreLabel.text = "Score: \(score)"
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
    
    // Last checkpoint position
    /* var lastCheckpoint = CGPoint(x: 10000, y: 20000) */
    var currentLevel = 1
    
    // Direction indicator
    var directionIndicator: SKSpriteNode!
    
    // Initial player spawn point (before any checkpoints)
    var initialSpawnPoint = CGPoint(x: 96, y: 672 - 256)
    var lastCheckpoint: CGPoint {
        didSet {
            // Optional: Update any UI or game state when checkpoint changes
        }
    }
    
    /* override func didMove(to view: SKView) {
        // Get screen dimensions
        screenWidth = view.bounds.width
        screenHeight = view.bounds.height

        // Create a world node that will contain all game elements
        worldNode = SKNode()
        addChild(worldNode)

        // UI elements should be attached to the scene, not the world
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: 16)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)

        livesLabel = SKLabelNode(fontNamed: "Chalkduster")
        livesLabel.text = "Lives: 3"
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: frame.width - 16, y: 16)
        livesLabel.zPosition = 100
        addChild(livesLabel)

        // Add direction indicator (triangle)
        directionIndicator = SKSpriteNode(imageNamed: "star") // Replace with triangle image
        directionIndicator.name = "directionIndicator"
        directionIndicator.position = CGPoint(x: frame.width - 50, y: 50)
        directionIndicator.zPosition = 100
        directionIndicator.size = CGSize(width: 32, height: 32)
        addChild(directionIndicator)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self

        loadLevel()
        createPlayer()

        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    } */
    
    func loadLevel() {
        // Track the maximum level dimensions
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        if let levelPath = Bundle.main.path(forResource: "level1", ofType: "txt") {
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
                        
                        if letter == "x" {
                            // load wall
                            let node = SKSpriteNode(imageNamed: "block")
                            node.position = position
                            node.size = CGSize(width: cellSize, height: cellSize)
                            
                            node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
                            node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
                            node.physicsBody?.isDynamic = false
                            worldNode.addChild(node)
                        } else if letter == "v"  {
                            // load vortex
                            let node = SKSpriteNode(imageNamed: "vortex")
                            node.name = "vortex"
                            node.position = position
                            node.size = CGSize(width: cellSize, height: cellSize)
                            node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            worldNode.addChild(node)
                        } else if letter == "s"  {
                            // Changed: load checkpoint (previously star)
                            let node = SKSpriteNode(imageNamed: "star")  // Keep using the star image for now
                            node.name = "checkpoint"  // Change name to "checkpoint"
                            node.size = CGSize(width: cellSize, height: cellSize)
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.checkpoint.rawValue  // Updated category
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
                            worldNode.addChild(node)
                            
                            // Add a pulsing animation to make checkpoints more visible
                            let scaleUp = SKAction.scale(to: 1.1, duration: 0.5)
                            let scaleDown = SKAction.scale(to: 0.9, duration: 0.5)
                            let pulse = SKAction.sequence([scaleUp, scaleDown])
                            node.run(SKAction.repeatForever(pulse))
                        } else if letter == "f"  {
                            // load finish
                            let node = SKSpriteNode(imageNamed: "finish")
                            node.name = "finish"
                            node.size = CGSize(width: cellSize, height: cellSize)
                            node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
                            node.physicsBody?.isDynamic = false
                            
                            node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
                            node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
                            node.physicsBody?.collisionBitMask = 0
                            node.position = position
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
        player = SKSpriteNode(imageNamed: "player")
        player.size = CGSize(width: 32, height: 32)
        player.position = lastCheckpoint  // Use last checkpoint position
        
//        player.position = CGPoint(x: 96, y: 672+4*64)
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = 0.5
        
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        player.physicsBody?.contactTestBitMask = CollisionTypes.checkpoint.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
        player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
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
        guard let finish = worldNode.childNode(withName: "finish") else { return }
        
        // Calculate vector from player to finish in the world coordinate system
        let playerPositionInWorld = player.position
        let finishPositionInWorld = finish.position
        
        let playerToFinish = CGVector(dx: finishPositionInWorld.x - playerPositionInWorld.x,
                                      dy: finishPositionInWorld.y - playerPositionInWorld.y)
        
        // Calculate angle to the finish point
        let angle = atan2(playerToFinish.dy, playerToFinish.dx)
        
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
            let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
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
            handleVortexCollision()
        }
    }
    
    func scrollMap(dx: CGFloat, dy: CGFloat) {
        // Move the world node to scroll the map
        worldNode.position = CGPoint(x: worldNode.position.x + dx, y: worldNode.position.y + dy)
        
        // Ensure the player stays within the visible area after scrolling
        constrainPlayer()
    }
    
    func constrainPlayer() {
        // Optional: Add logic here to ensure the player doesn't move outside
        // any desired boundaries of the larger level
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        if contact.bodyA.node == player {
            playerCollided(with: contact.bodyB.node!)
        } else if contact.bodyB.node == player {
            playerCollided(with: contact.bodyA.node!)
        }
    }
    
    func playerCollided(with node: SKNode) {
        if node.name == "vortex" {
            handleVortexCollision()
        } else if node.name == "checkpoint" {
            // Changed behavior for checkpoints (previously stars)
            handleCheckpointCollision(at: node.position)
        } else if node.name == "finish" {
            // next level?
            print("Level completed!")
        }
    }
    
    func handleCheckpointCollision(at position: CGPoint) {
        // Don't remove the checkpoint node - it stays in place
        // Just save the position and increment score
        lastCheckpoint = position
        
        // Find the specific checkpoint node at this position
        var targetCheckpoint: SKSpriteNode?
        
        // Search through all checkpoint nodes to find the one at this position
        worldNode.enumerateChildNodes(withName: "checkpoint") { (node, _) in
            if let checkpointNode = node as? SKSpriteNode {
                // Check if this checkpoint is at the collision position (with small tolerance)
                let distance = sqrt(pow(checkpointNode.position.x - position.x, 2) + pow(checkpointNode.position.y - position.y, 2))
                if distance < 5.0 { // Small tolerance for position matching
                    targetCheckpoint = checkpointNode
                }
            }
        }
        
        // Create a brief flash or highlight effect on the correct checkpoint
        if let checkpoint = targetCheckpoint {
            let originalColor = checkpoint.color
            let originalColorBlendFactor = checkpoint.colorBlendFactor
            
            let highlight = SKAction.sequence([
                SKAction.colorize(with: .green, colorBlendFactor: 0.7, duration: 0.1),
                SKAction.wait(forDuration: 0.2),
                SKAction.colorize(with: originalColor, colorBlendFactor: originalColorBlendFactor, duration: 0.1)
            ])
            
            checkpoint.run(highlight)
        }
        
        // Increment score as before
        score += 1
    }
    
    func handleVortexCollision() {
        player.physicsBody?.isDynamic = false
        isGameOver = true
        lives -= 1
        
        if lives <= 0 {
            // Game over logic - show alert with retry option
            let gameOverAction = SKAction.run { [weak self] in
                guard let self = self else { return }
                
                // Pause the game
                self.isPaused = true
                
                // Get the main view controller to present the alert
                if let viewController = self.view?.window?.rootViewController {
                    // Create the alert controller
                    let alertController = UIAlertController(
                        title: "Game Over",
                        message: "You ran out of lives!",
                        preferredStyle: .alert
                    )
                    
                    // Add retry action
                    let retryAction = UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
                        guard let self = self else { return }
                        
                        // Reset the game state
                        self.score = 0
                        self.lives = 3
                        self.lastCheckpoint = self.initialSpawnPoint
                        
                        // Remove the current player
                        self.player.removeFromParent()
                        
                        // Create a new player at the initial spawn point
                        self.createPlayer()
                        
                        // Unpause the game
                        self.isPaused = false
                        self.isGameOver = false
                    }
                    
                    // Add the actions to the alert controller
                    alertController.addAction(retryAction)
                    
                    // Present the alert controller
                    viewController.present(alertController, animated: true)
                }
            }
            
            player.run(gameOverAction)
            return
        }
        
        let move = SKAction.move(to: player.position, duration: 0.25)
        let scale = SKAction.scale(to: 0.0001, duration: 0.25)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([move, scale, remove])
        
        player.run(sequence) { [unowned self] in
            score -= 1
            self.createPlayer()  // Will use lastCheckpoint position
            self.isGameOver = false
        }
    }
        
//    override func didMove(to view: SKView) {
//		let background = SKSpriteNode(imageNamed: "background@2x.jpg")
//		background.position = CGPoint(x: 512 - 128, y: 384 + 128)
//		background.blendMode = .replace
//		background.zPosition = -1
//		addChild(background)
//
//		scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
//		scoreLabel.text = "Score: 0"
//		scoreLabel.horizontalAlignmentMode = .left
//		scoreLabel.position = CGPoint(x: 16, y: 16)
//		addChild(scoreLabel)
//
//		physicsWorld.gravity = CGVector(dx: 0, dy: 0)
//		physicsWorld.contactDelegate = self
//
//		loadLevel()
//		createPlayer()
//
//		motionManager = CMMotionManager()
//		motionManager.startAccelerometerUpdates()
//    }
    
    override func didMove(to view: SKView) {
        // Calculate the actual visible area for the game
        let playableHeight = size.height
        let playableWidth = size.width
        
        // Create a world node that will contain all level elements
        worldNode = SKNode()
        addChild(worldNode)
        
        let levelWidth: CGFloat = 31 * cellSize  // 1550 pixels
        let levelHeight: CGFloat = 23 * cellSize // 1150 pixels
        
        // Create a properly sized background - ensure it fills the playable area
        let background = SKSpriteNode(imageNamed: "background.jpg")
        let backgroundWidth = max(levelWidth, playableWidth) * 1.5
        let backgroundHeight = max(levelHeight, playableHeight) * 1.5
        
        // Center the background in the world coordinate system
        background.size = CGSize(width: backgroundWidth, height: backgroundHeight)
        background.position = CGPoint(x: backgroundWidth/2, y: backgroundHeight/2)
        background.zPosition = -1
        worldNode.addChild(background)
        
        // UI elements adjusted for actual playable area
        scoreLabel = SKLabelNode(fontNamed: "Chalkduster")
        scoreLabel.text = "Score: 0"
        scoreLabel.horizontalAlignmentMode = .left
        scoreLabel.position = CGPoint(x: 16, y: playableHeight - 30)
        scoreLabel.zPosition = 100
        addChild(scoreLabel)
        
        livesLabel = SKLabelNode(fontNamed: "Chalkduster")
        livesLabel.text = "Lives: 3"
        livesLabel.horizontalAlignmentMode = .right
        livesLabel.position = CGPoint(x: playableWidth - 16, y: playableHeight - 30)
        livesLabel.zPosition = 100
        addChild(livesLabel)
        
        // Add direction indicator (triangle)
        directionIndicator = SKSpriteNode(imageNamed: "star")
        directionIndicator.name = "directionIndicator"
        directionIndicator.position = CGPoint(x: playableWidth - 50, y: 50)
        directionIndicator.zPosition = 100
        directionIndicator.size = CGSize(width: 32, height: 32)
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
        // For example, make the cell size proportional to the screen width
        cellSize = CGFloat(playableWidth / 8) // Adjust divisor based on level width
        
        // Initialize lastCheckpoint to the initial spawn point
        lastCheckpoint = initialSpawnPoint
        
        loadLevel()
        
        createPlayer()
        
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }
    
    // Initialize all properties before super.init
    override init(size: CGSize) {
        // Initialize lastCheckpoint
        lastCheckpoint = CGPoint(x: 96, y: 672+4*64)
        
        // Call super.init after initializing all properties
        super.init(size: size)
    }
    
    // Look into this
    required init?(coder aDecoder: NSCoder) {
        // Initialize lastCheckpoint
        lastCheckpoint = CGPoint(x: 96, y: 672+4*64)
        
        // Call super.init after initializing all properties
        super.init(coder: aDecoder)
    }

//    // Map to a 2D visual representation of the game level
//	func loadLevel() {
//        
//        // Find the full file path to resource representing game level stored in app bundle (directory containing resources needed for app to run)
//        if let levelPath = Bundle.main.path(forResource: "level1Portrait", ofType: "txt") {
//            
//			if let levelString = try? String(contentsOfFile: levelPath) {
//				let lines = levelString.components(separatedBy: "\n")
//
//                // Bottom-top reading of lines cuz (0, 0) is bottom-left in SpriteKit's coordinate system
//				for (row, line) in lines.reversed().enumerated() {
//
//                    // Each char is considered a grid cell at (column, letter)
//					for (column, letter) in line.enumerated() {
//                        
//                        // Compute sprite position
//						let position = CGPoint(x: (64 * (column)) + 32, y: (64 * (row)) + 32) // Add 32 to center the sprite in its cell
//
//						if letter == "x" {
//							// load wall, create a sprite node
//							let node = SKSpriteNode(imageNamed: "block")
//                            // Place sprite node on screen using precomputed CGPoint
//							node.position = position
//                            // Gives node physics properties, enable collision, shape being rectangle with size of sprite
//							node.physicsBody = SKPhysicsBody(rectangleOf: node.size)
//							node.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
//							node.physicsBody?.isDynamic = false
//							addChild(node)
//						} else if letter == "v"  {
//							// load vortex, create a sprite node
//							let node = SKSpriteNode(imageNamed: "vortex")
//							node.name = "vortex"
//                            // Place sprite node on screen using precomputed CGPoint
//							node.position = position
//							node.run(SKAction.repeatForever(SKAction.rotate(byAngle: CGFloat.pi, duration: 1)))
//                            
//                            // Gives node physics properties, enable collision, shape being circle with size of sprite
//							node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
//							node.physicsBody?.isDynamic = false
//							node.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
//							node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
//							node.physicsBody?.collisionBitMask = 0
//							addChild(node)
//						} else if letter == "s"  {
//							// load checkpoint, aka star, create a sprite node
//							let node = SKSpriteNode(imageNamed: "star")
//							node.name = "star"
//							node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
//							node.physicsBody?.isDynamic = false
//
//							node.physicsBody?.categoryBitMask = CollisionTypes.checkpoint.rawValue
//							node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
//							node.physicsBody?.collisionBitMask = 0
//							node.position = position
//							addChild(node)
//						} else if letter == "f"  {
//							// load finish, create a sprite node
//							let node = SKSpriteNode(imageNamed: "finish")
//							node.name = "finish"
//							node.physicsBody = SKPhysicsBody(circleOfRadius: node.size.width / 2)
//							node.physicsBody?.isDynamic = false
//
//							node.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
//							node.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
//							node.physicsBody?.collisionBitMask = 0
//                            // Place sprite node on screen using precomputed CGPoint
//                            node.position = position
//							addChild(node)
//						}
//					}
//				}
//			}
//		}
//	}

//	func createPlayer() {
//		player = SKSpriteNode(imageNamed: "player")
//		player.position = CGPoint(x: 96, y: 672+4*64)
//		player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
//		player.physicsBody?.allowsRotation = false
//		player.physicsBody?.linearDamping = 0.5
//
//		player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
//		player.physicsBody?.contactTestBitMask = CollisionTypes.checkpoint.rawValue | CollisionTypes.vortex.rawValue | CollisionTypes.finish.rawValue
//		player.physicsBody?.collisionBitMask = CollisionTypes.wall.rawValue
//		addChild(player)
//	}

//	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//		if let touch = touches.first {
//			let location = touch.location(in: self)
//			lastTouchPosition = location
//		}
//	}
//
//	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//		if let touch = touches.first {
//			let location = touch.location(in: self)
//			lastTouchPosition = location
//		}
//	}
//
//	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//		lastTouchPosition = nil
//	}
//
//	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
//		lastTouchPosition = nil
//	}

//	override func update(_ currentTime: TimeInterval) {
//		guard isGameOver == false else { return }
//		#if targetEnvironment(simulator)
//			if let currentTouch = lastTouchPosition {
//				let diff = CGPoint(x: currentTouch.x - player.position.x, y: currentTouch.y - player.position.y)
//				physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
//			}
////		#else
////			if let accelerometerData = motionManager.accelerometerData {
////				physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.y * -50, dy: accelerometerData.acceleration.x * 50)
////			}
//        #else
//            if let accelerometerData = motionManager.accelerometerData {
//                physicsWorld.gravity = CGVector(dx: accelerometerData.acceleration.x * 10, dy: accelerometerData.acceleration.y * 10)
//            }
//		#endif
//	}

//	func didBegin(_ contact: SKPhysicsContact) {
//		if contact.bodyA.node == player {
//			playerCollided(with: contact.bodyB.node!)
//		} else if contact.bodyB.node == player {
//			playerCollided(with: contact.bodyA.node!)
//		}
//	}

//	func playerCollided(with node: SKNode) {
//		if node.name == "vortex" {
//			player.physicsBody?.isDynamic = false
//			isGameOver = true
//			score -= 1
//
//			let move = SKAction.move(to: node.position, duration: 0.25)
//			let scale = SKAction.scale(to: 0.0001, duration: 0.25)
//			let remove = SKAction.removeFromParent()
//			let sequence = SKAction.sequence([move, scale, remove])
//
//			player.run(sequence) { [unowned self] in
//				self.createPlayer()
//				self.isGameOver = false
//			}
//		} else if node.name == "star" {
//			node.removeFromParent()
//			score += 1
//		} else if node.name == "finish" {
//			// next level?
//		}
//	}
}
