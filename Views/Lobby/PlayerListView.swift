//
//  PlayerListView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct PlayerListView: View {
    
    @Binding var players: [NetworkPlayer]
    @State private var animateList: Bool = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Space Crew")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text("\(players.count)/8")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.gray.opacity(0.3))
                    )
            }
            
            // Players List
            VStack(spacing: 8) {
                ForEach(Array(players.enumerated()), id: \.element.id) { index, player in
                    PlayerRowView(player: player, index: index)
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .scaleEffect(animateList ? 1.0 : 0.8)
                        .opacity(animateList ? 1.0 : 0.0)
                        .animation(
                            .spring(response: 0.6, dampingFraction: 0.8)
                            .delay(Double(index) * 0.1),
                            value: animateList
                        )
                }
                
                // Empty slots
                ForEach(players.count..<8, id: \.self) { index in
                    EmptySlotView(slotNumber: index + 1)
                        .opacity(0.3)
                        .scaleEffect(animateList ? 1.0 : 0.8)
                        .animation(
                            .easeOut(duration: 0.3)
                            .delay(Double(index) * 0.05),
                            value: animateList
                        )
                }
            }
            .padding(.vertical)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            withAnimation {
                animateList = true
            }
        }
        .onChange(of: players.count) { _, _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                animateList = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    animateList = true
                }
            }
        }
    }
}

struct PlayerRowView: View {
    
    let player: NetworkPlayer
    let index: Int
    @State private var pulseReady: Bool = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Player Avatar
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                player.isLocal ? Color.yellow.opacity(0.3) : Color.blue.opacity(0.3),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 5,
                            endRadius: 20
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Circle()
                    .stroke(
                        player.isLocal ? Color.yellow : Color.blue,
                        lineWidth: 2
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(index + 1)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Player Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.displayName)
                        .font(.callout)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    if player.isHost {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                    
                    if player.isLocal {
                        Text("(You)")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                
                Text(player.playerType.displayName)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            // Connection Status
            VStack(spacing: 4) {
                Circle()
                    .fill(connectionStatusColor)
                    .frame(width: 8, height: 8)
                    .scaleEffect(pulseReady && player.isReady ? 1.5 : 1.0)
                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulseReady)
                
                Text(player.statusText)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            // Ready Indicator
            if player.isReady {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.green)
                    .scaleEffect(pulseReady ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulseReady)
            } else {
                Image(systemName: "clock.circle")
                    .font(.title3)
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    player.isLocal
                    ? Color.yellow.opacity(0.1)
                    : Color.clear
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            player.isLocal
                            ? Color.yellow.opacity(0.3)
                            : Color.clear,
                            lineWidth: 1
                        )
                )
        )
        .onAppear {
            pulseReady = true
        }
    }
    
    private var connectionStatusColor: Color {
        switch player.connectionQuality {
        case .excellent: return .green
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .orange
        case .terrible: return .red
        }
    }
}

struct EmptySlotView: View {
    
    let slotNumber: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Empty Avatar
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                    .frame(width: 40, height: 40)
                
                Text("\(slotNumber)")
                    .font(.headline)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            // Placeholder Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Waiting for player...")
                    .font(.callout)
                    .foregroundColor(.gray.opacity(0.7))
                
                Text("Empty slot")
                    .font(.caption)
                    .foregroundColor(.gray.opacity(0.5))
            }
            
            Spacer()
            
            // Empty indicator
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    PlayerListView(players: .constant(NetworkPlayerFactory.createTestPlayers(count: 3)))
        .preferredColorScheme(.dark)
        .padding()
}
