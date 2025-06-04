import SwiftUI

struct PixelAlertView: View {
    let title: String
    let backgroundColor: Color
    let lives: Int
    let primaryButtonText: String
    let secondaryButtonText: String
    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    let message: String?
    
    init(
        title: String,
        backgroundColor: Color,
        lives: Int = 5,
        primaryButtonText: String = "QUIT",
        secondaryButtonText: String = "CONTINUE",
        message: String? = nil,
        onPrimaryAction: @escaping () -> Void,
        onSecondaryAction: @escaping () -> Void
    ) {
        self.title = title
        self.backgroundColor = backgroundColor
        self.lives = lives
        self.primaryButtonText = primaryButtonText
        self.secondaryButtonText = secondaryButtonText
        self.message = message
        self.onPrimaryAction = onPrimaryAction
        self.onSecondaryAction = onSecondaryAction
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)
            
            // Alert box
            VStack(spacing: 16) {
                // Title
                Text(title)
                    .font(.custom("PressStart2P-Regular", size: 24))
                    .foregroundColor(backgroundColor)
                    .multilineTextAlignment(.center)
                    .padding(.top, 32)
                
                // Optional message
                if let message = message {
                    Text(message)
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundColor(backgroundColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                }
                
                // Hearts
                HStack(spacing: 4) {
                    ForEach(0..<5) { index in
                        Image("Heart_Icon")
                            .resizable()
                            .renderingMode(.template)
                            .foregroundColor(index < lives ? .red : .gray)
                            .frame(width: 20, height: 20)
                    }
                }
                .padding(.top, message == nil ? 32 : 16)
                .padding(.bottom, 16)
                
                // Buttons
                HStack(spacing: 16) {
                    // Quit button
                    Button(action: onPrimaryAction) {
                        Text(primaryButtonText)
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.red)
                            .cornerRadius(4)
                    }
                    .frame(width: 100)
                    
                    // Continue/Retry button
                    Button(action: onSecondaryAction) {
                        Text(secondaryButtonText)
                            .font(.custom("PressStart2P-Regular", size: 14))
                            .foregroundColor(.green)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color(white: 0.2))
                            .cornerRadius(4)
                    }
                    .frame(width: 100)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .frame(width: 280)
            .background(
                ZStack {
                    // Main background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(white: 0.15))
                    
                    // Border
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color(white: 0.4), lineWidth: 2)
                        .padding(4)
                    
                    // Outer border
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(white: 0.3), lineWidth: 4)
                }
            )
        }
        .interactiveDismissDisabled()
    }
} 