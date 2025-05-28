//
//  GameViewController.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import UIKit
import SpriteKit
import MultipeerConnectivity

class GameViewController: UIViewController {
    
    // MARK: - Properties
    private var gameScene: GameScene!
    private var skView: SKView!
    
    // Game Configuration
    private var gameMode: GameMode = .singlePlayer
    private var players: [NetworkPlayer] = []
    private var isHost: Bool = false
    private var gameCode: String?
    private var playerType: PlayerType = .mapMover
    
    // Managers
    private let gameManager = GameManager.shared
    private let multipeerManager = MultipeerManager.shared
    private let audioManager = AudioManager.shared
    private let levelManager = LevelManager.shared
    
    // MARK: - Lifecycle
    override func loadView() {
        self.view = SKView()
        self.skView = self.view as? SKView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DispatchQueue.main.async {
            self.setupGame()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupMultipeerDelegate()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cleanupGame()
    }
    
    // MARK: - Game Setup
    func setupGame(
        mode: GameMode = .singlePlayer,
        players: [NetworkPlayer] = [],
        isHost: Bool = false,
        gameCode: String? = nil,
        playerType: PlayerType = .mapMover
    ) {
        self.gameMode = mode
        self.players = players
        self.isHost = isHost
        self.gameCode = gameCode
        self.playerType = playerType
        
        setupSKView()
        createGameScene()
        startGame()
    }
    
    private func setupSKView() {
        guard let skView = skView else { return }
        
        let sceneWidth = skView.bounds.width
        let sceneHeight = sceneWidth * (16.0/9.0)
        
        skView.ignoresSiblingOrder = true
        skView.showsFPS = Constants.showFPS
        skView.showsNodeCount = Constants.showNodeCount
        skView.preferredFramesPerSecond = 60
    }
    
    private func createGameScene() {
        guard let skView = skView else { return }
        
        let sceneSize = CGSize(width: skView.bounds.width, height: skView.bounds.width * (16.0/9.0))
        gameScene = GameScene(size: sceneSize)
        gameScene.scaleMode = .aspectFit
        
        // Configure game scene for multiplayer
        gameScene.setupMultiplayer(
            mode: gameMode,
            players: players,
            isHost: isHost,
            playerType: playerType
        )
        
        // Set delegates
        gameScene.gameDelegate = self
        
        skView.presentScene(gameScene)
    }
    
    private func startGame() {
        // Start the appropriate game mode
        switch gameMode {
        case .singlePlayer:
            startSinglePlayerGame()
        case .multiplayerHost:
            startMultiplayerHost()
        case .multiplayerClient:
            startMultiplayerClient()
        }
    }
    
    private func startSinglePlayerGame() {
        gameManager.startNewGame(mode: .singlePlayer)
        levelManager.loadLevel(1)
        gameScene.startLevel()
    }
    
    private func startMultiplayerHost() {
        gameManager.startNewGame(mode: .multiplayerHost)
        levelManager.loadLevel(1)
        
        // Wait for all players to be ready
        if players.allSatisfy({ $0.isReady }) {
            gameScene.startLevel()
            multipeerManager.startGame()
        }
    }
    
    private func startMultiplayerClient() {
        gameManager.startNewGame(mode: .multiplayerClient)
        // Client waits for host to start
    }
    
    // MARK: - Multiplayer Updates
    func updateMultiplayerState(players: [NetworkPlayer], isHost: Bool) {
        self.players = players
        self.isHost = isHost
        
        gameScene?.updatePlayers(players)
    }
    
    private func setupMultipeerDelegate() {
        multipeerManager.gameDelegate = self
    }
    
    // MARK: - Cleanup
    private func cleanupGame() {
        gameScene?.removeFromParent()
        gameScene = nil
        
        if gameMode != .singlePlayer {
            multipeerManager.gameDelegate = nil
        }
    }
    
    // MARK: - Device Orientation
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait]
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
}

// MARK: - GameSceneDelegate
extension GameViewController: GameSceneDelegate {
    
    func gameScene(_ scene: GameScene, didCompleteLevel level: Int) {
        DispatchQueue.main.async {
            if self.gameMode != .singlePlayer {
                self.multipeerManager.sendLevelCompleted()
            }
            
            // Advance to next level
            self.levelManager.loadLevel(level + 1)
            scene.startLevel()
        }
    }
    
    func gameScene(_ scene: GameScene, didFailLevel level: Int) {
        DispatchQueue.main.async {
            // Handle level failure
            if self.gameMode != .singlePlayer {
                self.multipeerManager.sendGameEnded(reason: .allPlayersEliminated)
            }
        }
    }
    
    func gameScene(_ scene: GameScene, playerDidReachCheckpoint checkpointId: String, playerId: String) {
        if gameMode != .singlePlayer {
            multipeerManager.sendCheckpointReached(checkpointId, playerId: playerId)
        }
    }
    
    func gameScene(_ scene: GameScene, playerDidDie playerId: String) {
        if gameMode != .singlePlayer {
            multipeerManager.sendPlayerDied(playerId)
        }
    }
    
    func gameScene(_ scene: GameScene, playerDidMove playerId: String, position: CGPoint, velocity: CGVector) {
        if gameMode != .singlePlayer && playerId == multipeerManager.getLocalPlayer().id {
            multipeerManager.sendPlayerMovement(position, velocity: velocity)
        }
    }
}

// MARK: - MultipeerGameDelegate
extension GameViewController: MultipeerGameDelegate {
    
    func gameDidStart(with players: [NetworkPlayer]) {
        DispatchQueue.main.async {
            self.players = players
            self.gameScene?.updatePlayers(players)
            self.gameScene?.startLevel()
        }
    }
    
    func gameDidEnd(reason: GameEndReason) {
        DispatchQueue.main.async {
            self.gameScene?.endGame(reason: reason)
        }
    }
    
    func gameDidPause() {
        DispatchQueue.main.async {
            self.gameScene?.pauseGame()
        }
    }
    
    func gameDidResume() {
        DispatchQueue.main.async {
            self.gameScene?.resumeGame()
        }
    }
    
    func playerDidMove(playerId: String, position: CGPoint, velocity: CGVector, timestamp: TimeInterval) {
        DispatchQueue.main.async {
            self.gameScene?.updatePlayerPosition(playerId: playerId, position: position, velocity: velocity, timestamp: timestamp)
        }
    }
    
    func checkpointReached(_ checkpointId: String, by playerId: String) {
        DispatchQueue.main.async {
            self.gameScene?.handleCheckpointReached(checkpointId, by: playerId)
        }
    }
    
    func playerDied(_ playerId: String) {
        DispatchQueue.main.async {
            self.gameScene?.handlePlayerDied(playerId)
        }
    }
}

// MARK: - GameSceneDelegate Protocol
protocol GameSceneDelegate: AnyObject {
    func gameScene(_ scene: GameScene, didCompleteLevel level: Int)
    func gameScene(_ scene: GameScene, didFailLevel level: Int)
    func gameScene(_ scene: GameScene, playerDidReachCheckpoint checkpointId: String, playerId: String)
    func gameScene(_ scene: GameScene, playerDidDie playerId: String)
    func gameScene(_ scene: GameScene, playerDidMove playerId: String, position: CGPoint, velocity: CGVector)
}
