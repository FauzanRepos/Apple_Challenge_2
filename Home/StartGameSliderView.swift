//
//  StartGameSliderView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Paul Hudson. All rights reserved.
//

import SwiftUI

struct StartGameSliderView: View {
    
    var onComplete: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var dragComplete: Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
//            let sliderWidth = geometry.size.width
            let sliderWidth = UIScreen.main.bounds.width * 0.88
            let circleSize: CGFloat = 60
            
            ZStack {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 80)
                
                HStack {
                    Rectangle()
                        .fill(Color(.systemGray4))
                        .frame(height: 10)
                    Text(dragComplete ? "Starting..." : "Swipe to start")
                        .foregroundStyle(Color(.systemGray4))
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .layoutPriority(1)
                    HStack (spacing: 0) {
                        Rectangle()
                            .fill(Color(.systemGray4))
                            .frame(height: 10)
                        Triangle()
                            .fill(Color(.systemGray4))
                            .frame(width: 20, height: 20)
                        
                    }
                }
                .frame(maxWidth: sliderWidth * 0.9)
                
                // Draggable circle, replace with image asset
                HStack {
                    Circle()
                        .fill(Color(.systemGray2))
                        .frame(width: circleSize, height: circleSize)
                        .overlay {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.gray)
                                .font(.title)
                        }
                        .offset(x: offsetX + 10)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.width >= 0 && value.translation.width <= sliderWidth - circleSize {
                                        offsetX = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if offsetX > sliderWidth - circleSize * 1.5 {
                                        
                                        // Trigger start
                                        dragComplete = true
                                        
                                        withAnimation {
                                            offsetX = sliderWidth - circleSize
                                        }
                                        
                                        // TO-DO Move to lobby page
                                        onComplete()
                                        
                                        
                                        withAnimation {
                                            offsetX = 0
                                        }
                                    } else {
                                        withAnimation {
                                            offsetX = 0
                                        }
                                    }
                                }
                        )
                    Spacer()
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 60)
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))               // top left
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))            // middle right (tip)
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))            // bottom left
        path.closeSubpath()
        return path
    }
}


#Preview {
    StartGameSliderView {
        print("Slider complete — navigate to LobbyView.")
    }
}

