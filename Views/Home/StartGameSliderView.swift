//
//  StartGameSliderView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct StartGameSliderView: View {
    
    var onComplete: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var dragComplete: Bool = false
    @State private var isAnimating: Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
            let sliderWidth = UIScreen.main.bounds.width * 0.88
            let circleSize: CGFloat = 60
            
            ZStack {
                // Background capsule
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray4)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 80)
                    .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                
                // Content
                HStack {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray4), Color(.systemGray3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 10)
                        .opacity(0.6)
                    
                    Text(dragComplete ? "Creating Room..." : "Swipe to create room")
                        .foregroundStyle(
                            LinearGradient(
                                colors: dragComplete ? [.green, .blue] : [Color(.systemGray2), Color(.systemGray3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .fontWeight(.semibold)
                        .lineLimit(1)
                        .layoutPriority(1)
                        .scaleEffect(isAnimating ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isAnimating)
                    
                    HStack(spacing: 0) {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray4), Color(.systemGray3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(height: 10)
                            .opacity(0.6)
                        
                        Triangle()
                            .fill(
                                LinearGradient(
                                    colors: [Color(.systemGray4), Color(.systemGray3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: 20, height: 20)
                            .opacity(0.6)
                    }
                }
                .frame(maxWidth: sliderWidth * 0.9)
                
                // Draggable circle with spaceship icon
                HStack {
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: dragComplete ? [.green, .blue] : [Color(.systemGray2), Color(.systemGray3)],
                                    center: .center,
                                    startRadius: 10,
                                    endRadius: 30
                                )
                            )
                            .frame(width: circleSize, height: circleSize)
                            .shadow(color: dragComplete ? .green.opacity(0.5) : .black.opacity(0.3), radius: 8, x: 0, y: 4)
                        
                        Image(systemName: dragComplete ? "checkmark" : "airplane")
                            .foregroundStyle(dragComplete ? .white : .gray)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .rotationEffect(.degrees(dragComplete ? 360 : 0))
                            .animation(.easeInOut(duration: 0.5), value: dragComplete)
                    }
                    .offset(x: offsetX + 10)
                    .scaleEffect(dragComplete ? 1.1 : 1.0)
                    .animation(.easeOut(duration: 0.3), value: dragComplete)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                if value.translation.width >= 0 && value.translation.width <= sliderWidth - circleSize {
                                    offsetX = value.translation.width
                                }
                            }
                            .onEnded { value in
                                if offsetX > sliderWidth - circleSize * 1.5 {
                                    
                                    // Trigger completion
                                    dragComplete = true
                                    
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        offsetX = sliderWidth - circleSize
                                    }
                                    
                                    // Call completion handler
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                        onComplete()
                                    }
                                    
                                    // Reset after delay
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                        withAnimation(.easeOut(duration: 0.5)) {
                                            offsetX = 0
                                            dragComplete = false
                                        }
                                    }
                                } else {
                                    withAnimation(.easeOut(duration: 0.3)) {
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
        .frame(height: 80)
        .onAppear {
            isAnimating = true
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    StartGameSliderView {
        print("Slider complete — navigate to LobbyView.")
    }
}
