import SwiftUI

struct VolumeSliderView: View {
    let title: String
    @Binding var volume: Double
    @Binding var isMuted: Bool
    let onChanged: (Double) -> Void
    var showMuteButton: Bool = false
    
    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 4)
                            .cornerRadius(2)
                        
                        // Fill track
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: geometry.size.width * CGFloat(volume), height: 4)
                            .cornerRadius(2)
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let percentage = min(max(0, value.location.x / geometry.size.width), 1)
                                volume = Double(percentage)
                                onChanged(Double(percentage))
                            }
                    )
                }
                
                Image(systemName: "speaker.wave.3.fill")
                    .foregroundColor(.white)
                    .font(.system(size: 16))
            }
            .frame(height: 30)
        }
    }
} 