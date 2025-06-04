import SwiftUI

struct GameAlertOverlay: View {
    @EnvironmentObject var audioManager: AudioManager
    @ObservedObject var gameManager: GameManager
    let onDismiss: () -> Void
    
    private var currentLevel: Int { gameManager.currentLevel }
    private var section: Int { gameManager.section }
    private var teamLives: Int { gameManager.teamLives }
    private var currentAlert: GameAlert { gameManager.currentAlert }
    
    var body: some View {
//        GeometryReader { geometry in
            ZStack {
                // Alert content
                Group {
                    switch currentAlert {
                    case .gameOver:
                        PixelAlertView(
                            title: "Game Over",
                            backgroundColor: .red,
                            lives: teamLives,
                            primaryButtonText: "Quit",
                            secondaryButtonText: "New Game",
                            message: "Your journey ends here.\nFinal Score: Level \(currentLevel) Section \(section)",
                            onPrimaryAction: {
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                print("🎯 [GameAlertOverlay] Quit button tapped")
                                onDismiss()
                            },
                            onSecondaryAction: {
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                print("🎯 [GameAlertOverlay] New Game button tapped")
                                gameManager.startGame()
                                onDismiss()
                            }
                        )
                        .onAppear {
                            print("🎯 [GameAlertOverlay] Game over alert appeared")
                        }
                        
                    case .respawn:
                        PixelAlertView(
                            title: "Mech Damaged",
                            backgroundColor: .orange,
                            lives: teamLives,
                            primaryButtonText: "Give Up",
                            secondaryButtonText: "Continue",
                            message: "Lives remaining: \(teamLives)\nCurrent checkpoint: Level \(currentLevel) Section \(section)",
                            onPrimaryAction: {
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                print("🎯 [GameAlertOverlay] Give Up button tapped")
                                onDismiss()
                            },
                            onSecondaryAction: {
                                audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                print("🎯 [GameAlertOverlay] Continue button tapped")
                                gameManager.respawnPlayer()
                            }
                        )
                        .onAppear {
                            print("🎯 [GameAlertOverlay] Respawn alert appeared")
                        }
                        
                    case .none:
                        EmptyView()
                            .onAppear {
                                print("🎯 [GameAlertOverlay] Empty view appeared")
                            }
                    }
                }
//                .frame(width: min(geometry.size.width * 0.8, 400))
//                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
//            }
        }
        .onAppear {
            print("🎯 [GameAlertOverlay] View appeared with alert: \(currentAlert)")
        }
        .onChange(of: currentAlert) { newAlert in
            print("🎯 [GameAlertOverlay] Alert changed to: \(newAlert)")
        }
    }
    
    init(gameManager: GameManager, onDismiss: @escaping () -> Void) {
        self.gameManager = gameManager
        self.onDismiss = onDismiss
        print("🎯 [GameAlertOverlay] Initialized with alert: \(gameManager.currentAlert)")
    }
} 
