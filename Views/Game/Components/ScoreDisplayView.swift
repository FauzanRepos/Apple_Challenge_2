//
//  ScoreDisplayView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ScoreDisplayView: View {
    let currentScore: Int
    let highScore: Int
    @State private var animateScoreIncrease: Bool = false
    @State private var animateNewHighScore: Bool = false
    @State private var lastScore: Int = 0
    @State private var scoreIncrement: Int = 0
    
    var isNewHighScore: Bool {
        currentScore > highScore && highScore > 0
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Current Score
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.callout)
                    .foregroundColor(.yellow)
                    .rotationEffect(.degrees(animateScoreIncrease ? 360 : 0))
                    .animation(.easeInOut(duration: 0.5), value: animateScoreIncrease)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Score")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text(String.formatScore(currentScore))
                            .font(.callout)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .scaleEffect(animateScoreIncrease ? 1.1 : 1.0)
                            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: animateScoreIncrease)
                        
                        // Score increment indicator
                        if scoreIncrement > 0 {
                            Text("+\(scoreIncrement)")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                
                Spacer()
                
                // New High Score Indicator
                if isNewHighScore {
                    newHighScoreIndicator
                }
            }
            
            // High Score Reference
            if highScore > 0 && !isNewHighScore {
                HStack(spacing: 4) {
                    Text("Best:")
                        .font(.caption2)
                        .foregroundColor(.gray)
                    
                    Text(String.formatScore(highScore))
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.yellow.opacity(0.8))
                        .monospacedDigit()
                    
                    Spacer()
                    
                    // Progress to high score
                    if currentScore > 0 {
                        progressToHighScore
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(
                            isNewHighScore
                            ? Color.yellow.opacity(0.8)
                            : Color.white.opacity(0.2),
                            lineWidth: isNewHighScore ? 2 : 1
                        )
                )
                .shadow(
                    color: isNewHighScore ? .yellow.opacity(0.3) : .black.opacity(0.3),
                    radius: isNewHighScore ? 8 : 4,
                    x: 0,
                    y: 2
                )
        )
        .onChange(of: currentScore) { oldValue, newValue in
            handleScoreChange(from: oldValue, to: newValue)
        }
        .onAppear {
            lastScore = currentScore
        }
    }
    
    // MARK: - New High Score Indicator
    private var newHighScoreIndicator: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.caption)
                .foregroundColor(.yellow)
                .scaleEffect(animateNewHighScore ? 1.3 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateNewHighScore)
            
            Text("NEW HIGH!")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .scaleEffect(animateNewHighScore ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: animateNewHighScore)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.yellow.opacity(0.2))
                .overlay(
                    Capsule()
                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                )
        )
        .onAppear {
            animateNewHighScore = true
        }
    }
    
    // MARK: - Progress to High Score
    private var progressToHighScore: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 3)
                    .cornerRadius(1.5)
                
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .yellow],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * progressPercentage, height: 3)
                    .cornerRadius(1.5)
                    .animation(.easeInOut(duration: 0.5), value: progressPercentage)
            }
        }
        .frame(width: 60, height: 3)
    }
    
    // MARK: - Computed Properties
    private var progressPercentage: CGFloat {
        guard highScore > 0 else { return 0 }
        return min(1.0, CGFloat(currentScore) / CGFloat(highScore))
    }
    
    // MARK: - Methods
    private func handleScoreChange(from oldValue: Int, to newValue: Int) {
        lastScore = oldValue
        
        if newValue > oldValue {
            scoreIncrement = newValue - oldValue
            triggerScoreAnimation()
            
            // Hide increment after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeOut(duration: 0.3)) {
                    scoreIncrement = 0
                }
            }
        }
    }
    
    private func triggerScoreAnimation() {
        animateScoreIncrease = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            animateScoreIncrease = false
        }
    }
}

// MARK: - Team Score Display
struct TeamScoreDisplayView: View {
    
    let teamScore: Int
    let playerScores: [String: Int]
    let highScore: Int
    @State private var showDetailedScores: Bool = false
    @State private var animateTeamScore: Bool = false
    
    var body: some View {
        VStack(spacing: 8) {
            // Team Score Header
            Button(action: { showDetailedScores.toggle() }) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill")
                        .font(.callout)
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Team Score")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text(String.formatScore(teamScore))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    
                    Spacer()
                    
                    Image(systemName: showDetailedScores ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(showDetailedScores ? 180 : 0))
                        .animation(.easeInOut(duration: 0.3), value: showDetailedScores)
                }
            }
            .buttonStyle(PlainButtonStyle())
            
            // Detailed Player Scores
            if showDetailedScores {
                VStack(spacing: 4) {
                    ForEach(Array(playerScores.sorted { $0.value > $1.value }), id: \.key) { playerId, score in
                        HStack {
                            Text(getPlayerName(playerId))
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                            
                            Spacer()
                            
                            Text(String.formatScore(score))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.3), value: showDetailedScores)
    }
    
    private func getPlayerName(_ playerId: String) -> String {
        // This would typically come from a player manager
        return "Player \(playerId.prefix(4))"
    }
}

// MARK: - Score Animation Overlay
struct ScoreAnimationOverlay: View {
    
    let points: Int
    let position: CGPoint
    @State private var offset: CGFloat = 0
    @State private var opacity: Double = 1
    @State private var scale: CGFloat = 1
    
    var body: some View {
        Text("+\(points)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.green)
            .scaleEffect(scale)
            .opacity(opacity)
            .position(x: position.x, y: position.y + offset)
            .onAppear {
                withAnimation(.easeOut(duration: 1.5)) {
                    offset = -50
                    opacity = 0
                    scale = 1.5
                }
            }
    }
}

#Preview {
    VStack(spacing: 30) {
        ScoreDisplayView(currentScore: 1250, highScore: 1000)
        ScoreDisplayView(currentScore: 750, highScore: 1500)
        
        TeamScoreDisplayView(
            teamScore: 2840,
            playerScores: [
                "player1": 1200,
                "player2": 980,
                "player3": 660
            ],
            highScore: 2500
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
