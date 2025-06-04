//
//  StartGameSliderView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct StartGameSliderView: View {
    @EnvironmentObject var audioManager: AudioManager
    
    var onComplete: () -> Void
    
    @State private var offsetX: CGFloat = 0
    @State private var dragComplete: Bool = false
    
    var body: some View {
        
        GeometryReader { geometry in
//            let sliderWidth = geometry.size.width
            let sliderWidth = UIScreen.main.bounds.width * 0.90
            let circleSize: CGFloat = 44
            
            ZStack {
//                Capsule()
//                    .fill(Color(.systemGray5))
//                    .frame(height: 80)
                
                Image("StartGame_Slider")
                    .resizable()
                    .frame(width: sliderWidth, height: 76)
                
                HStack(spacing: 2) {
                    Rectangle()
                        .fill(Color(.systemGray2))
                        .frame(height: 10)
                        .padding(.leading)
                    Text(dragComplete ? "Starting..." : "Swipe to start")
                        .font(.custom("VCROSDMono", size: 12))
                        .fontWeight(.semibold)
                        .foregroundStyle(Color(.systemGray2))
                        .lineLimit(1)
                        .layoutPriority(1)
                    HStack (spacing: 0) {
                        Rectangle()
                            .fill(Color(.systemGray2))
                            .frame(height: 10)
                        Triangle()
                            .fill(Color(.systemGray2))
                            .frame(width: 40, height: 40)
                            .padding(.trailing)
                    }
                }
                .frame(maxWidth: sliderWidth * 0.9)
                
                // Draggable circle, replace with image asset
                HStack {
                    
                    Image("StartGame_SliderBall")
                        .resizable()
                        .frame(width: circleSize, height: circleSize)
                        .offset(x: offsetX + 20)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    if value.translation.width >= 0 && value.translation.width <= sliderWidth - circleSize {
                                        offsetX = value.translation.width
                                    }
                                }
                                .onEnded { value in
                                    if offsetX > sliderWidth - circleSize * 1.5 {
                                        
                                        // Play sound effect for slider completion
                                        audioManager.playSFX("sfx_buttonclick", xtension: "wav")
                                        
                                        // Trigger start
                                        dragComplete = true
                                        
                                        withAnimation {
                                            offsetX = sliderWidth - circleSize
                                        }
                                        
                                        // TO-DO Move to game page
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

//import SwiftUI
//
//struct StartGameSliderView: View {
//    var onSlide: () -> Void
//    @State private var sliderValue: Double = 0.0
//    private let threshold: Double = 1.0
//    
//    var body: some View {
//        VStack {
//            Text("Slide to Start")
//                .font(.headline)
//                .foregroundColor(.white)
//            Slider(
//                value: $sliderValue,
//                in: 0...threshold,
//                onEditingChanged: { editing in
//                    if !editing && sliderValue >= threshold {
//                        sliderValue = 0
//                        onSlide()
//                    }
//                }
//            )
//            .accentColor(.green)
//            .frame(width: 220)
//        }
//    }
//}
