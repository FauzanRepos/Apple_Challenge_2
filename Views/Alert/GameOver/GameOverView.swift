import SwiftUI

struct GameOverView: View {
    var score: Int
    var onRestart: () -> Void
    var onMainMenu: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Semi-transparent black background
            Color.black.opacity(0.8)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Game Over text
                Text("GAME OVER")
                    .font(.custom("PressStart2P-Regular", size: 32))
                    .foregroundColor(.red)
                    .padding(.top, 50)
                
                // Score
                Text("Score: \(score)")
                    .font(.custom("PressStart2P-Regular", size: 24))
                    .foregroundColor(.white)
                
                // Buttons
                VStack(spacing: 20) {
                    Button(action: {
                        onRestart()
                        dismiss()
                    }) {
                        Text("Retry")
                            .font(.custom("PressStart2P-Regular", size: 20))
                            .foregroundColor(.black)
                            .frame(width: 200, height: 50)
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        onMainMenu()
                        dismiss()
                    }) {
                        Text("Main Menu")
                            .font(.custom("PressStart2P-Regular", size: 20))
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                }
                .padding(.top, 30)
            }
        }
        .interactiveDismissDisabled()
    }
} 