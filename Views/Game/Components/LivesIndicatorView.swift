//
//  LivesIndicatorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct LivesIndicatorView: View {
    
    let currentLives: Int
    let maxLives: Int = 5
    @State private var animateHeartbeat: Bool = false
    @State private var animateLoss: Bool = false
    @State private var lastLivesCount: Int = 5
    
    var body: some View {
        HStack(spacing: 8) {
            // Lives Label
            Text("Lives:")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
            
            // Hearts Display
            HStack(spacing: 4) {
                ForEach(0..<maxLives, id: \.self) { index in
                    heartView(for: index)
                }
            }
            
            // Lives Counter
            Text("\(currentLives)")
                .font(.callout)
                .fontWeight(.bold)
                .foregroundColor(livesColor)
                .padding(.leading, 4)
                .scaleEffect(animateLoss ? 1.3 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateLoss)
                .shadow(color: .black.opacity(0.7), radius: 2, x: 1, y: 1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.6))
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [livesColor.opacity(0.5), livesColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        )
        .onChange(of: currentLives) { oldValue, newValue in
            handleLivesChange(from: oldValue, to: newValue)
        }
        .onAppear {
            lastLivesCount = currentLives
            if currentLives <= 2 {
                animateHeartbeat = true
            }
        }
    }
    
    // MARK: - Heart View
    private func heartView(for index: Int) -> some View {
        ZStack {
            // Heart Background/Shadow
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundColor(.black.opacity(0.3))
                .offset(x: 1, y: 1)
            
            // Main Heart
            Image(systemName: index < currentLives ? "heart.fill" : "heart")
                .font(.title3)
                .foregroundColor(index < currentLives ? heartColor(for: index) : .gray.opacity(0.4))
                .scaleEffect(heartScale(for: index))
                .animation(heartAnimation(for: index), value: animateHeartbeat)
                .animation(.spring(response: 0.4, dampingFraction: 0.6), value: currentLives)
        }
    }
    
    // MARK: - Heart Properties
    private func heartColor(for index: Int) -> Color {
        switch currentLives {
        case 5: return .green
        case 4: return .green
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .gray
        }
    }
    
    private func heartScale(for index: Int) -> CGFloat {
        if index < currentLives {
            if currentLives <= 2 && animateHeartbeat {
                return index == 0 ? 1.2 : 1.1
            }
            return 1.0
        }
        return 0.8
    }
    
    private func heartAnimation(for index: Int) -> Animation? {
        if index < currentLives && currentLives <= 2 {
            return .easeInOut(duration: 0.8)
                .repeatForever(autoreverses: true)
                .delay(Double(index) * 0.1)
        }
        return nil
    }
    
    // MARK: - Computed Properties
    private var livesColor: Color {
        switch currentLives {
        case 5: return .green
        case 4: return .green
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .gray
        }
    }
    
    private var livesPercentage: Double {
        return Double(currentLives) / Double(maxLives)
    }
    
    // MARK: - Methods
    private func handleLivesChange(from oldValue: Int, to newValue: Int) {
        lastLivesCount = oldValue
        
        if newValue < oldValue {
            // Lives decreased - trigger loss animation
            triggerLossAnimation()
        }
        
        // Update heartbeat animation based on remaining lives
        if newValue <= 2 && newValue > 0 {
            animateHeartbeat = true
        } else {
            animateHeartbeat = false
        }
    }
    
    private func triggerLossAnimation() {
        animateLoss = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateLoss = false
        }
    }
}

// MARK: - Team Lives Indicator
struct TeamLivesIndicatorView: View {
    
    let currentLives: Int
    let maxLives: Int = 5
    let playerCount: Int
    @State private var animateTeamEffect: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Team Lives Header
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text("Team Lives")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            
            // Lives Display
            HStack(spacing: 8) {
                // Progress Bar Style
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: livesGradientColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * livesProgress, height: 8)
                            .cornerRadius(4)
                            .scaleEffect(y: animateTeamEffect ? 1.2 : 1.0)
                            .animation(.easeInOut(duration: 0.3), value: animateTeamEffect)
                    }
                }
                .frame(height: 8)
                
                // Lives Text
                Text("\(currentLives)/\(maxLives)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .onChange(of: currentLives) { _, _ in
            triggerTeamEffect()
        }
    }
    
    private var livesProgress: CGFloat {
        return CGFloat(currentLives) / CGFloat(maxLives)
    }
    
    private var livesGradientColors: [Color] {
        switch currentLives {
        case 5: return [.green, .green]
        case 4: return [.green, .yellow]
        case 3: return [.yellow, .yellow]
        case 2: return [.orange, .orange]
        case 1: return [.red, .red]
        default: return [.gray, .gray]
        }
    }
    
    private func triggerTeamEffect() {
        animateTeamEffect = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            animateTeamEffect = false
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        LivesIndicatorView(currentLives: 5)
        LivesIndicatorView(currentLives: 3)
        LivesIndicatorView(currentLives: 1)
        
        TeamLivesIndicatorView(currentLives: 3, playerCount: 4)
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
