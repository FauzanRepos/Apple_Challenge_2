import SwiftUI

enum GameAlert {
    case none
    case gameOver
    case respawn
}

struct GameAlertOverlay: View {
    @ObservedObject var gameManager: GameManager
    var onDismiss: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Alert content
            Group {
                switch gameManager.currentAlert {
                case .gameOver:
                    PixelAlertView(
                        title: "Game Over",
                        backgroundColor: .red,
                        lives: 0,
                        primaryButtonText: "QUIT",
                        secondaryButtonText: "NEW GAME",
                        message: "Your journey ends here.\nFinal Score: Level \(gameManager.currentLevel) Section \(gameManager.score)",
                        onPrimaryAction: {
                            gameManager.quitToHome()
                        },
                        onSecondaryAction: {
                            gameManager.resetGame()
                        }
                    )
                    
                case .respawn:
                    PixelAlertView(
                        title: "Mech Damaged",
                        backgroundColor: .orange,
                        lives: gameManager.lives,
                        primaryButtonText: "GIVE UP",
                        secondaryButtonText: "CONTINUE",
                        message: "Lives remaining: \(gameManager.lives)\nCurrent checkpoint: Level \(gameManager.currentLevel) Section \(gameManager.score)",
                        onPrimaryAction: {
                            gameManager.quitToHome()
                        },
                        onSecondaryAction: {
                            gameManager.respawnPlayer()
                        }
                    )
                    
                case .none:
                    EmptyView()
                }
            }
        }
    }
} 