//
//  GameScene.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import CoreMotion
import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Properties
    var worldNode: SKNode!
    var gameHUD: GameHUD!
    var players: [String: PlayerNode] = [:]
    var localPlayerId: String = ""
    var playerType: PlayerType = .mapMover
    var gameMode: GameMode = .singlePlayer
    var isHost: Bool = false

    // Game State
    var isGameOver = false
    var isPaused = false
    var lives = 5
    var score = 0
    var currentLevel = 1

    // Motion
    var motionManager: CMMotionManager!
    var lastTouchPosition: CGPoint?

    // Level Elements
    var checkpoints: [String: SKSpriteNode] = [:]
    var vortexes: [SKSpriteNode] = []
    var powerUps: [String: SKSpriteNode] = [:]
    var walls: [SKSpriteNode] = []
    var finishNode: SKSpriteNode?

    // Map Properties
    var mapWidth: CGFloat = 0
    var mapHeight: CGFloat = 0
    var cellSize: CGFloat = 64

    // Screen Edge Detection
    var leftEdgeMargin: CGFloat = 100
    var rightEdgeMargin: CGFloat = 100
    var topEdgeMargin: CGFloat = 100
    var bottomEdgeMargin: CGFloat = 100

    // Delegates
    weak var gameDelegate: GameSceneDelegate?

    // Managers
    private let levelManager = LevelManager.shared
    private let audioManager = AudioManager.shared
    private let gameManager = GameManager.shared

    // MARK: - Scene Setup
    override func didMove(to view: SKView) {
        setupScene()
        setupPhysics()
        setupHUD()
        setupMotion()
        setupSpikeBorders()
    }

    private func setupScene() {
        backgroundColor = .black

        // Create world node container
        worldNode = SKNode()
        addChild(worldNode)

        // Calculate screen margins based on player type
        let marginRatio = playerType == .mapMover ? Constants.mapMoverEdgeMarginRatio : Constants.regularPlayerEdgeMarginRatio
        let margin = min(size.width, size.height) * marginRatio

        leftEdgeMargin = margin
        rightEdgeMargin = margin
        topEdgeMargin = margin
        bottomEdgeMargin = margin
    }

    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.contactDelegate = self
    }

    private func setupHUD() {
        gameHUD = GameHUD(size: size)
        gameHUD.updateLives(lives)
        gameHUD.updateScore(score)
        gameHUD.updateLevel(currentLevel)
        addChild(gameHUD)
    }

    private func setupMotion() {
        motionManager = CMMotionManager()
        motionManager.startAccelerometerUpdates()
    }

    private func setupSpikeBorders() {
        let spikeTexture = SKTexture(imageNamed: "spike")
        let spikeSize = CGSize(width: 32, height: 32)

        // Top spikes
        let topSpikesCount = Int(size.width / spikeSize.width) + 1
        for i in 0..<topSpikesCount {
            let spike = SKSpriteNode(texture: spikeTexture, size: spikeSize)
            spike.position = CGPoint(x: CGFloat(i) * spikeSize.width, y: size.height - spikeSize.height/2)
            spike.zPosition = 1000
            spike.name = "spike"
            addChild(spike)
        }

        // Bottom spikes
        for i in 0..<topSpikesCount {
            let spike = SKSpriteNode(texture: spikeTexture, size: spikeSize)
            spike.position = CGPoint(x: CGFloat(i) * spikeSize.width, y: spikeSize.height/2)
            spike.zRotation = .pi
            spike.zPosition = 1000
            spike.name = "spike"
            addChild(spike)
        }

        // Left spikes
        let leftSpikesCount = Int(size.height / spikeSize.height) + 1
        for i in 0..<leftSpikesCount {
            let spike = SKSpriteNode(texture: spikeTexture, size: spikeSize)
            spike.position = CGPoint(x: spikeSize.width/2, y: CGFloat(i) * spikeSize.height)
            spike.zRotation = -.pi/2
            spike.zPosition = 1000
            spike.name = "spike"
            addChild(spike)
        }

        // Right spikes
        for i in 0..<leftSpikesCount {
            let spike = SKSpriteNode(texture: spikeTexture, size: spikeSize)
            spike.position = CGPoint(x: size.width - spikeSize.width/2, y: CGFloat(i) * spikeSize.height)
            spike.zRotation = .pi/2
            spike.zPosition = 1000
            spike.name = "spike"
            addChild(spike)
        }
    }

    // MARK: - Multiplayer Setup
    func setupMultiplayer(mode: GameMode, players: [NetworkPlayer], isHost: Bool, playerType: PlayerType) {
        self.gameMode = mode
        self.isHost = isHost
        self.playerType = playerType

        // Create player nodes
        for player in players {
            createPlayerNode(for: player)
            if player.isLocal {
                localPlayerId = player.id
            }
        }
    }

    func updatePlayers(_ players: [NetworkPlayer]) {
        for player in players {
            if self.players[player.id] == nil {
                createPlayerNode(for: player)
            }
        }
    }

    private func createPlayerNode(for player: NetworkPlayer) -> PlayerNode {
        let playerNode = PlayerNode(player: player, cellSize: cellSize)
        players[player.id] = playerNode
        worldNode.addChild(playerNode)

        if player.isLocal {
            playerNode.isLocal = true
        }

        return playerNode
    }

    // MARK: - Level Management
    func startLevel() {
        loadCurrentLevel()
        spawnPlayers()
        isPaused = false
    }

    private func loadCurrentLevel() {
        // Clear existing level elements
        clearLevel()

        // Load level from manager
        guard let level = levelManager.currentLevel else {
            print("❌ No current level loaded")
            return
        }

        mapWidth = level.size.width
        mapHeight = level.size.height
        cellSize = level.cellSize

        // Create background
        createBackground()

        // Create walls
        for wall in level.walls {
            createWall(at: wall.position, size: wall.size)
        }

        // Create checkpoints
        for checkpoint in level.checkpoints {
            createCheckpoint(at: checkpoint.position, id: checkpoint.id)
        }

        // Create vortexes
        for vortex in level.vortexes {
            createVortex(at: vortex.position)
        }

        // Create power-ups
        for powerUp in level.powerUps {
            createPowerUp(powerUp.type, at: powerUp.position, id: powerUp.id)
        }

        // Create finish point
        createFinish(at: level.finishPoint.position)
    }

    private func clearLevel() {
        worldNode.removeAllChildren()
        checkpoints.removeAll()
        vortexes.removeAll()
        powerUps.removeAll()
        walls.removeAll()
        finishNode = nil
    }

    private func createBackground() {
        let backgroundSize = CGSize(
            width: max(mapWidth, size.width) * 1.2,
            height: max(mapHeight, size.height) * 1.2
        )

        let background = SKSpriteNode(imageNamed: "background")
        background.size = backgroundSize
        background.position = CGPoint(x: backgroundSize.width/2, y: backgroundSize.height/2)
        background.zPosition = -100
        worldNode.addChild(background)
    }

    private func createWall(at position: CGPoint, size: CGSize) {
        let wall = SKSpriteNode(imageNamed: "block")
        wall.position = position
        wall.size = size
        wall.name = "wall"

        wall.physicsBody = SKPhysicsBody(rectangleOf: size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue

        walls.append(wall)
        worldNode.addChild(wall)
    }

    private func createCheckpoint(at position: CGPoint, id: String) {
        let checkpoint = createCheckpoint(at: position, id: id)
        checkpoints[id] = checkpoint
        worldNode.addChild(checkpoint)
    }

    private func createVortex(at position: CGPoint) {
        let vortex = createVortex(at: position)
        vortexes.append(vortex)
        worldNode.addChild(vortex)
    }

    private func createPowerUp(_ type: PowerUpType, at position: CGPoint, id: String) {
        let powerUp = createPowerUp(type: type, at: position)
        powerUp.name = "powerup_\(id)"
        powerUps[id] = powerUp
        worldNode.addChild(powerUp)
    }

    private func createFinish(at position: CGPoint) {
        finishNode = createFinish(at: position)
        worldNode.addChild(finishNode!)
    }

    private func spawnPlayers() {
        guard let level = levelManager.currentLevel else { return }

        let startPositions = level.getPlayerStartPositions(for: players.count)

        for (index, (playerId, playerNode)) in players.enumerated() {
            let position = index < startPositions.count ? startPositions[index] : startPositions[0]
            playerNode.position = position
            playerNode.resetPlayer()
        }
    }

    // MARK: - Game Update
    override func update(_ currentTime: TimeInterval) {
        guard !isGameOver && !isPaused else { return }

        handleInput()
        updatePlayers()
        checkScreenEdges()
        updatePowerUps()

        gameHUD.updateLives(lives)
        gameHUD.updateScore(score)
    }

    private func handleInput() {
        guard let localPlayer = players[localPlayerId] else { return }

#if targetEnvironment(simulator)
        if let touchPosition = lastTouchPosition {
            let diff = CGPoint(x: touchPosition.x - localPlayer.position.x, y: touchPosition.y - localPlayer.position.y)
            physicsWorld.gravity = CGVector(dx: diff.x / 100, dy: diff.y / 100)
        }
#else
        if let accelerometerData = motionManager.accelerometerData {
            let gravity = CGVector(
                dx: accelerometerData.acceleration.x * Constants.accelerometerSensitivity,
                dy: accelerometerData.acceleration.y * Constants.accelerometerSensitivity
            )
            physicsWorld.gravity = gravity
        }
#endif
    }

    private func updatePlayers() {
        for (playerId, playerNode) in players {
            playerNode.update()

            // Send position updates for local player
            if playerNode.isLocal && gameMode != .singlePlayer {
                gameDelegate?.gameScene(self, playerDidMove: playerId, position: playerNode.position, velocity: playerNode.physicsBody?.velocity ?? .zero)
            }
        }
    }

    private func checkScreenEdges() {
        guard let localPlayer = players[localPlayerId] else { return }

        let playerPositionInScene = worldNode.convert(localPlayer.position, to: self)

        let nearLeftEdge = playerPositionInScene.x < leftEdgeMargin
        let nearRightEdge = playerPositionInScene.x > size.width - rightEdgeMargin
        let nearTopEdge = playerPositionInScene.y > size.height - topEdgeMargin
        let nearBottomEdge = playerPositionInScene.y < bottomEdgeMargin

        if playerType == .mapMover {
            // Map mover scrolls the map
            var dx: CGFloat = 0
            var dy: CGFloat = 0

            if nearLeftEdge { dx = Constants.mapScrollSpeed }
            else if nearRightEdge { dx = -Constants.mapScrollSpeed }

            if nearTopEdge { dy = -Constants.mapScrollSpeed }
            else if nearBottomEdge { dy = Constants.mapScrollSpeed }

            if dx != 0 || dy != 0 {
                scrollMap(dx: dx, dy: dy)
            }
        } else {
            // Regular player dies at edges
            if nearLeftEdge || nearRightEdge || nearTopEdge || nearBottomEdge {
                handlePlayerDeath(localPlayerId)
            }
        }
    }

    private func scrollMap(dx: CGFloat, dy: CGFloat) {
        worldNode.position = CGPoint(x: worldNode.position.x + dx, y: worldNode.position.y + dy)
    }

    private func updatePowerUps() {
        for (powerUpId, powerUpNode) in powerUps {
            if let activePowerUp = powerUpNode.userData?["powerUp"] as? PowerUp {
                // Update respawn timer if needed
                // This would be handled by the PowerUp model
            }
        }
    }

    // MARK: - Collision Handling
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        var playerNode: PlayerNode?
        var otherNode: SKNode?

        if contact.bodyA.categoryBitMask == CollisionTypes.player.rawValue {
            playerNode = contact.bodyA.node as? PlayerNode
            otherNode = contact.bodyB.node
        } else if contact.bodyB.categoryBitMask == CollisionTypes.player.rawValue {
            playerNode = contact.bodyB.node as? PlayerNode
            otherNode = contact.bodyA.node
        }

        guard let player = playerNode, let other = otherNode else { return }

        handleCollision(player: player, with: other)
    }

    private func handleCollision(player: PlayerNode, with node: SKNode) {
        guard let nodeName = node.name else { return }

        switch nodeName {
        case let name where name.hasPrefix("checkpoint"):
            handleCheckpointCollision(player: player, checkpoint: node)

        case "vortex":
            handleVortexCollision(player: player)

        case "finish":
            handleFinishCollision(player: player)

        case let name where name.hasPrefix("powerup"):
            handlePowerUpCollision(player: player, powerUp: node)

        default:
            break
        }
    }

    private func handleCheckpointCollision(player: PlayerNode, checkpoint: SKNode) {
        guard let checkpointName = checkpoint.name,
              let checkpointId = checkpointName.components(separatedBy: "_").last else { return }

        // Remove checkpoint
        checkpoint.removeFromParent()
        checkpoints.removeValue(forKey: checkpointId)

        // Update score
        score += Constants.checkpointScore

        // Play sound
        audioManager.playCheckpointSound()

        // Create checkpoint effect
        createCheckpointEffect(at: checkpoint.position)

        // Notify delegate
        gameDelegate?.gameScene(self, playerDidReachCheckpoint: checkpointId, playerId: player.playerId)
    }

    private func handleVortexCollision(player: PlayerNode) {
        handlePlayerDeath(player.playerId)
    }

    private func handleFinishCollision(player: PlayerNode) {
        // Check if all alive players reached finish
        let alivePlayers = players.values.filter { $0.isAlive }
        let playersAtFinish = alivePlayers.filter { finishNode?.contains($0.position) == true }

        if playersAtFinish.count == alivePlayers.count {
            handleLevelComplete()
        }
    }

    private func handlePowerUpCollision(player: PlayerNode, powerUp: SKNode) {
        guard let powerUpName = powerUp.name,
              let powerUpId = powerUpName.components(separatedBy: "_").last,
              let powerUpNode = powerUps[powerUpId] else { return }

        // Determine power-up type from sprite name
        var powerUpType: PowerUpType = .oil
        if powerUpName.contains("grass") {
            powerUpType = .grass
        }

        // Apply power-up effect
        player.applyPowerUp(powerUpType)

        // Remove power-up
        powerUpNode.removeFromParent()
        powerUps.removeValue(forKey: powerUpId)

        // Update score
        score += Constants.starCollectionScore

        // Play sound
        audioManager.playPowerUpSound()

        // Create effect
        createPowerUpEffect(at: powerUp.position, type: powerUpType)
    }

    // MARK: - Player Management
    func updatePlayerPosition(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval) {
        guard let playerNode = players[playerId] else { return }
        playerNode.updateNetworkPosition(position: position, velocity: velocity, timestamp: timestamp)
    }

    func handleCheckpointReached(_ checkpointId: String, by playerId: String) {
        if let checkpoint = checkpoints[checkpointId] {
            checkpoint.removeFromParent()
            checkpoints.removeValue(forKey: checkpointId)
            createCheckpointEffect(at: checkpoint.position)
        }
    }

    func handlePlayerDied(_ playerId: String) {
        guard let playerNode = players[playerId] else { return }

        lives -= 1

        if lives <= 0 {
            handleGameOver()
        } else {
            // Respawn player
            respawnPlayer(playerId)
        }

        audioManager.playDeathSound()
        gameDelegate?.gameScene(self, playerDidDie: playerId)
    }

    private func respawnPlayer(_ playerId: String) {
        guard let playerNode = players[playerId],
              let level = levelManager.currentLevel else { return }

        let spawnPosition = level.getPlayerStartPosition(for: 0)
        playerNode.respawn(at: spawnPosition)
    }

    private func handlePlayerDeath(_ playerId: String) {
        handlePlayerDied(playerId)
    }

    // MARK: - Game States
    private func handleLevelComplete() {
        audioManager.playVictorySound()
        gameDelegate?.gameScene(self, didCompleteLevel: currentLevel)

        currentLevel += 1

        // Show level complete alert
        showAlert(title: "Mission Accomplished", message: "Congratulations on completing the mission. There is still a long journey ahead of you", type: .success) {
            // Continue to next level
        }
    }

    private func handleGameOver() {
        isGameOver = true
        audioManager.playDeathSound()

        gameDelegate?.gameScene(self, didFailLevel: currentLevel)

        // Show game over alert
        showAlert(title: "Mission Failed", message: "Long journey ahead but your mech can't make it. Better luck on your next journey", type: .failure) {
            // Return to menu
        }
    }

    func pauseGame() {
        isPaused = true
    }

    func resumeGame() {
        isPaused = false
    }

    func endGame(reason: GameEndReason) {
        isGameOver = true

        let alertType: GameAlertType = (reason == .gameCompleted) ? .success : .failure
        let title = (reason == .gameCompleted) ? "Mission Accomplished" : "Mission Failed"
        let message = reason.displayMessage

        showAlert(title: title, message: message, type: alertType) {
            // Handle end game
        }
    }

    // MARK: - Visual Effects
    private func createCheckpointEffect(at position: CGPoint) {
        createCheckpointEffect(at: position)
    }

    private func createPowerUpEffect(at position: CGPoint, type: PowerUpType) {
        let effectColor: UIColor = (type == .oil) ? .yellow : .green

        for i in 0..<10 {
            let particle = SKSpriteNode(color: effectColor, size: CGSize(width: 4, height: 4))
            particle.position = position
            worldNode.addChild(particle)

            let angle = (Float.pi * 2 / 10) * Float(i)
            let moveAction = SKAction.move(
                by: CGVector(dx: cos(angle) * 30, dy: sin(angle) * 30),
                duration: 0.5
            )
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let removeAction = SKAction.removeFromParent()

            let sequence = SKAction.sequence([
                SKAction.group([moveAction, fadeAction]),
                removeAction
            ])

            particle.run(sequence)
        }
    }

    private func showAlert(title: String, message: String, type: GameAlertType, completion: @escaping () -> Void) {
        let alert = GameAlert(title: title, message: message, type: type, size: size)
        alert.zPosition = 2000
        alert.completion = completion
        addChild(alert)
    }

    // MARK: - Touch Handling
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            lastTouchPosition = touch.location(in: self)
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            lastTouchPosition = touch.location(in: self)
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        lastTouchPosition = nil
    }
}
