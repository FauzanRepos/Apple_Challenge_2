import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var gameManager: GameManager
    
    var body: some View {
        ZStack {
            // Game Layer
            SpriteView(scene: gameManager.scene)
                .ignoresSafeArea()
                .zIndex(0)
            
            // Alert Layer
            if gameManager.currentAlert != .none {
                GameAlertOverlay(
                    gameManager: gameManager,
                    onDismiss: {
                        gameManager.quitToHome()
                    }
                )
                .transition(.opacity)
                .zIndex(2)
            }
        }
        .sheet(isPresented: $gameManager.showSettings, onDismiss: {
            gameManager.closeSettings()
        }) {
            SettingsView()
        }
    }
} 
