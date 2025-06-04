import SwiftUI
import SpriteKit

struct GameView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var gameManager: GameManager
    @EnvironmentObject var audioManager: AudioManager
    
    var body: some View {
        ZStack {
            // Game Scene Layer
            if let scene = gameManager.scene {
                SpriteView(scene: scene)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
        }
        .overlay(alignment: .top) {
            // UI Overlay - Always on top
            HStack {
                // Lives
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                        .font(.title2)
                    Text("\(gameManager.teamLives)")
                        .foregroundColor(.white)
                        .font(.title2)
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.red.opacity(0.8))
                .cornerRadius(15)
                .shadow(radius: 5)
                
                Spacer()
                
                // Score
                Text(gameManager.scoreText)
                    .foregroundColor(.white)
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding()
                    .background(Color.blue.opacity(0.8))
                    .cornerRadius(15)
                    .shadow(radius: 5)
            }
            .padding()
        }
        .overlay {
            // Settings overlay
            if gameManager.showSettings {
                Color.black.opacity(0.8)
                    .ignoresSafeArea()
                
                SettingsView()
            }
        }
        .overlay {
            // Alert overlay
            if gameManager.currentAlert != .none {
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // Prevent tap-through
                    }
                
                GameAlertOverlay(
                    gameManager: gameManager,
                    onDismiss: {
//                        print("🎯 [GameView] Alert dismissed")
                        gameManager.dismissAlert()
                    }
                )
                .environmentObject(audioManager)
            }
        }
        .onAppear {
//            print("🎯 [GameView] View appeared")
//            print("🎯 [GameView] Current lives: \(gameManager.teamLives)")
//            print("🎯 [GameView] Current score: \(gameManager.scoreText)")
//            print("🎯 [GameView] Current alert: \(gameManager.currentAlert)")
            
            // Load initial level
            gameManager.loadLevel(1)
        }
        .onChange(of: gameManager.currentAlert) { newAlert in
//            print("🎯 [GameView] Alert state changed to: \(newAlert)")
        }
        .onChange(of: gameManager.teamLives) { newLives in
//            print("🎯 [GameView] Lives changed to: \(newLives)")
        }
        .onChange(of: gameManager.scoreText) { newScore in
//            print("🎯 [GameView] Score changed to: \(newScore)")
        }
    }
} 
