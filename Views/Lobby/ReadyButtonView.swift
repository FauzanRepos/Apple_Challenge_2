//
//  ReadyButtonView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ReadyButtonView: View {
    
    let isReady: Bool
    let canStart: Bool
    let playerCount: Int
    let onStart: () -> Void
    
    @State private var animateButton: Bool = false
    @State private var pulseReady: Bool = false
    @State private var showCountdown: Bool = false
    @State private var countdownValue: Int = 3
    @State private var isStarting: Bool = false
    
    private var buttonText: String {
        if isStarting {
            return "Starting Mission..."
        } else if showCountdown {
            return "Starting in \(countdownValue)..."
        } else if canStart {
            return "Launch Mission"
        } else if playerCount < 2 {
            return "Need at least 2 crew members"
        } else {
            return "Waiting for crew to be ready..."
        }
    }
    
    private var buttonColor: Color {
        if canStart && !isStarting {
            return .green
        } else if playerCount >= 2 && !isReady {
            return .orange
        } else {
            return .gray
        }
    }
    
    private var buttonIcon: String {
        if isStarting {
            return "airplane.departure"
        } else if canStart {
            return "rocket.fill"
        } else if playerCount < 2 {
            return "person.2.badge.plus"
        } else {
            return "clock.fill"
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            
            // Status Information
            statusInfo
            
            // Main Action Button
            Button(action: handleButtonTap) {
                HStack(spacing: 12) {
                    if isStarting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: buttonIcon)
                            .font(.title3)
                            .rotationEffect(.degrees(animateButton && canStart ? 360 : 0))
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: animateButton)
                    }
                    
                    Text(buttonText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: canStart && !isStarting
                                ? [buttonColor, buttonColor.opacity(0.8)]
                                : [buttonColor.opacity(0.6), buttonColor.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(
                                    canStart ? Color.white.opacity(0.3) : Color.clear,
                                    lineWidth: 1
                                )
                        )
                        .shadow(
                            color: canStart ? buttonColor.opacity(0.4) : .clear,
                            radius: canStart ? 12 : 0,
                            x: 0,
                            y: 6
                        )
                )
            }
            .disabled(!canStart || isStarting)
            .scaleEffect(canStart && pulseReady ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseReady)
            .buttonStyle(PlainButtonStyle())
            
            // Countdown Overlay
            if showCountdown {
                countdownOverlay
            }
        }
        .onAppear {
            animateButton = true
            if canStart {
                pulseReady = true
            }
        }
        .onChange(of: canStart) { _, newValue in
            pulseReady = newValue
        }
    }
    
    // MARK: - Status Info
    private var statusInfo: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Mission Status")
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Circle()
                    .fill(canStart ? .green : .orange)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseReady ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseReady)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * readinessProgress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.5), value: readinessProgress)
                }
            }
            .frame(height: 4)
            
            HStack {
                Text("Crew Readiness")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Text("\(Int(readinessProgress * 100))%")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(canStart ? .green : .orange)
            }
        }
        .padding(.horizontal, 4)
    }
    
    // MARK: - Countdown Overlay
    private var countdownOverlay: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.8))
                .frame(width: 100, height: 100)
                .overlay(
                    Circle()
                        .stroke(Color.green, lineWidth: 4)
                        .frame(width: 100, height: 100)
                )
            
            Text("\(countdownValue)")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(2.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: countdownValue)
        }
        .transition(.scale.combined(with: .opacity))
    }
    
    // MARK: - Computed Properties
    private var readinessProgress: CGFloat {
        guard playerCount > 0 else { return 0.0 }
        
        if canStart {
            return 1.0
        } else if playerCount >= 2 {
            return 0.7 // Minimum players met, but not all ready
        } else {
            return CGFloat(playerCount) / 2.0 // Progress towards minimum players
        }
    }
    
    // MARK: - Methods
    private func handleButtonTap() {
        guard canStart && !isStarting else { return }
        
        isStarting = true
        showCountdown = true
        countdownValue = 3
        
        startCountdown()
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            countdownValue -= 1
            
            if countdownValue <= 0 {
                timer.invalidate()
                showCountdown = false
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    onStart()
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 30) {
        ReadyButtonView(
            isReady: false,
            canStart: false,
            playerCount: 1,
            onStart: { print("Game starting...") }
        )
        
        ReadyButtonView(
            isReady: false,
            canStart: false,
            playerCount: 3,
            onStart: { print("Game starting...") }
        )
        
        ReadyButtonView(
            isReady: true,
            canStart: true,
            playerCount: 4,
            onStart: { print("Game starting...") }
        )
    }
    .padding()
    .background(Color.black)
    .preferredColorScheme(.dark)
}
