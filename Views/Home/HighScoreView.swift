//
//  HighScoreView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct HighScoreView: View {
    
    @StateObject private var storageManager = StorageManager.shared
    @Binding var animate: Bool
    
    init(animate: Binding<Bool> = .constant(false)) {
        self._animate = animate
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Text("High Score")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.white)
                .scaleEffect(animate ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animate)
            
            ZStack {
                Rectangle()
                    .foregroundColor(Color(.systemGray6))
                    .frame(width: UIScreen.main.bounds.width * 0.85, height: 110)
                    .cornerRadius(12)
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 16) {
                    if storageManager.getHighScore() > 0 {
                        Text(String.formatScore(storageManager.getHighScore()))
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    } else {
                        Text("NO RECORD")
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.black)
                    }
                    
                    ZStack {
                        HStack(spacing: 45) {
                            ForEach(0..<6) { index in
                                Circle()
                                    .fill(getCircleColor(for: index))
                                    .frame(width: 15, height: 15)
                                    .scaleEffect(animate && index % 2 == 0 ? 1.2 : 1.0)
                                    .animation(
                                        .easeInOut(duration: 1.5)
                                        .repeatForever(autoreverses: true)
                                        .delay(Double(index) * 0.2),
                                        value: animate
                                    )
                            }
                        }
                        Rectangle()
                            .fill(Color(.systemGray2))
                            .frame(width: 15*6 + 45*5, height: 5)
                            .opacity(0.6)
                    }
                }
            }
            .scaleEffect(animate ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animate)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(.systemGray4), Color(.systemGray5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            storageManager.loadGameData()
        }
    }
    
    private func getCircleColor(for index: Int) -> Color {
        let progress = min(1.0, Double(storageManager.getHighScore()) / 1000.0)
        let filledCircles = Int(progress * 6)
        
        if index < filledCircles {
            return .green
        } else if index == filledCircles && progress > Double(filledCircles) / 6.0 {
            return .yellow
        } else {
            return Color(.systemGray2)
        }
    }
}

#Preview {
    HighScoreView(animate: .constant(true))
        .preferredColorScheme(.dark)
}
