import SwiftUI

extension Text {
    func pixelTextStyle(color: Color = .white) -> some View {
        self.font(.custom("PressStart2P-Regular", size: 16))
            .foregroundColor(color)
    }
    
    func warningTextStyle() -> some View {
        self.font(.custom("PressStart2P-Regular", size: 16))
            .foregroundColor(Color.yellow)
    }
} 