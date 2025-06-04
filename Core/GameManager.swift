import SwiftUI
import SpriteKit

class GameManager: ObservableObject {
    @Published var currentAlert: GameAlert = .none
    @Published var lives: Int = 5 {
        didSet {
            scene.updateLives(lives)
        }
    }
    @Published var score: Int = 0 {
        didSet {
            // No need to save score here as it's handled in onScoreUpdate
        }
    }
    @Published var currentLevel: Int = 1
    @Published var shouldReturnToHome = false
    @Published var showSettings = false
    
    let scene: GameScene
    let playerType: PlayerType
    private let audioManager = AudioManager.shared
    private let highScoreManager = HighScoreManager.shared
    
    init(playerType: PlayerType) {
        print("DEBUG: Initializing GameManager")
        self.playerType = playerType
        scene = GameScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .aspectFill
        scene.playerType = playerType
        setupCallbacks()
        scene.updateLives(lives)
        audioManager.playBGM()
        print("DEBUG: GameManager initialization completed")
    }
    
    private func setupCallbacks() {
        print("DEBUG: Setting up GameManager callbacks")
        
        scene.onGameOver = { [weak self] in
            print("DEBUG: Game Over callback received in GameManager")
            DispatchQueue.main.async {
                self?.handleGameOver()
            }
        }
        
        scene.onPlayerDeath = { [weak self] in
            print("DEBUG: Player Death callback received in GameManager")
            DispatchQueue.main.async {
                self?.handlePlayerDeath()
            }
        }
        
        scene.onCheckpoint = { [weak self] in
            self?.audioManager.playSFX(.checkpoint)
        }
        
        scene.onCollision = { [weak self] in
            self?.audioManager.playSFX(.collision)
        }
        
        scene.onPowerup = { [weak self] in
            self?.audioManager.playSFX(.powerup)
        }
        
        scene.onFinish = { [weak self] in
            self?.audioManager.playSFX(.finish)
        }
        
        scene.onLevelComplete = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                // Save the final score for the current level
                self.highScoreManager.saveScore(level: self.currentLevel, score: self.score)
                // Increment the level
                self.currentLevel += 1
                // Update the scene's level
                self.scene.currentLevel = self.currentLevel
            }
        }
        
        scene.onScoreUpdate = { [weak self] newScore in
            DispatchQueue.main.async {
                print("DEBUG: Updating score to: \(newScore)")
                self?.score = newScore
                // Save score with current level
                if let self = self {
                    self.highScoreManager.saveScore(level: self.currentLevel, score: newScore)
                }
            }
        }
    }
    
    private func handleGameOver() {
        print("DEBUG: Handling game over")
        audioManager.playSFX(.death)
        // Save final score before game over
        highScoreManager.saveScore(level: currentLevel, score: score)
        currentAlert = .gameOver
    }
    
    private func handlePlayerDeath() {
        print("DEBUG: Handling player death")
        audioManager.playSFX(.death)
        lives -= 1
        print("DEBUG: Lives remaining: \(lives)")
        
        if lives <= 0 {
            print("DEBUG: No lives remaining, triggering game over")
            currentAlert = .gameOver
        } else {
            print("DEBUG: Showing respawn alert")
            currentAlert = .respawn
        }
    }
    
    func resetGame() {
        print("DEBUG: Resetting game")
        lives = 5
        score = 0
        currentLevel = 1
        currentAlert = .none
        scene.resetGame()
        audioManager.playBGM()
    }
    
    func respawnPlayer() {
        print("DEBUG: Respawning player")
        scene.respawnFromCheckpoint()
        currentAlert = .none
    }
    
    func quitToHome() {
        print("DEBUG: Quitting to home")
        audioManager.stopBGM()
        shouldReturnToHome = true
    }
    
    func dismissAlert() {
        print("DEBUG: Dismissing alert")
        currentAlert = .none
    }
    
    func updateLives(_ newLives: Int) {
        lives = newLives
    }
    
    func openSettings() {
        showSettings = true
        audioManager.pauseBGM()
    }
    
    func closeSettings() {
        showSettings = false
        audioManager.playBGM()
    }
} 