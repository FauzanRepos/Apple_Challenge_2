//
//  ConnectionStatusView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ConnectionStatusView: View {
    
    let sessionState: SessionState
    let onDismiss: () -> Void
    
    @State private var animateStatus: Bool = false
    @State private var refreshTrigger: Bool = false
    @State private var refreshTimer: Timer?
    
    var body: some View {
        ZStack {
            // Background Overlay
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            // Main Content
            VStack(spacing: 24) {
                
                // Header
                headerSection
                
                // Overall Status
                overallStatusSection
                
                // Players Connection Status
                playersStatusSection
                
                // Network Details
                networkDetailsSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.95))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.blue.opacity(0.5), Color.green.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
            .scaleEffect(animateStatus ? 1.0 : 0.8)
            .opacity(animateStatus ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animateStatus)
        }
        .onAppear {
            animateStatus = true
            startRefreshTimer()
        }
        .onDisappear {
            stopRefreshTimer()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "network")
                .font(.title2)
                .foregroundColor(.blue)
                .rotationEffect(.degrees(animateStatus ? 360 : 0))
                .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: animateStatus)
            
            Text("Connection Status")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.gray)
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Overall Status Section
    private var overallStatusSection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Session Status")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                StatusIndicator(
                    status: sessionState.currentState,
                    animate: animateStatus
                )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                StatusRow(
                    title: "Game Code",
                    value: sessionState.gameCode.isEmpty ? "Not Available" : sessionState.gameCode,
                    icon: "number.circle"
                )
                
                StatusRow(
                    title: "Players",
                    value: sessionState.connectionSummary,
                    icon: "person.2"
                )
                
                StatusRow(
                    title: "Network Quality",
                    value: sessionState.overallNetworkQuality.displayName,
                    icon: "wifi",
                    valueColor: networkQualityColor
                )
                
                StatusRow(
                    title: "Average Ping",
                    value: "\(Int(sessionState.averagePing * 1000))ms",
                    icon: "timer",
                    valueColor: pingColor
                )
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - Players Status Section
    private var playersStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Players Connection")
                .font(.headline)
                .foregroundColor(.white)
            
            if sessionState.connectedPlayers.isEmpty {
                Text("No players connected")
                    .font(.callout)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.gray.opacity(0.1))
                    )
            } else {
                ForEach(sessionState.connectedPlayers, id: \.id) { player in
                    PlayerConnectionRow(player: player)
                }
            }
        }
    }
    
    // MARK: - Network Details Section
    private var networkDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Details")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 8) {
                NetworkDetailRow(
                    title: "Sync Status",
                    value: sessionState.syncStatus.displayName,
                    color: syncStatusColor
                )
                
                NetworkDetailRow(
                    title: "Message Queue",
                    value: "\(sessionState.messageQueueSize) messages",
                    color: queueStatusColor
                )
                
                NetworkDetailRow(
                    title: "Session Age",
                    value: formatDuration(sessionState.sessionAge),
                    color: .white
                )
                
                if sessionState.isHost {
                    NetworkDetailRow(
                        title: "Role",
                        value: "Host",
                        color: .yellow
                    )
                } else {
                    NetworkDetailRow(
                        title: "Role",
                        value: "Client",
                        color: .blue
                    )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        HStack(spacing: 16) {
            Button(action: runConnectionTest) {
                HStack {
                    Image(systemName: "checkmark.circle")
                    Text("Test Connection")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.6))
                )
            }
            .buttonStyle(ScaleButtonStyle())
            
            Button(action: onDismiss) {
                HStack {
                    Image(systemName: "checkmark")
                    Text("Done")
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.6))
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Computed Properties
    private var networkQualityColor: Color {
        switch sessionState.overallNetworkQuality {
        case .excellent: return .green
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .orange
        case .terrible: return .red
        }
    }
    
    private var pingColor: Color {
        let pingMs = sessionState.averagePing * 1000
        switch pingMs {
        case 0..<50: return .green
        case 50..<150: return .yellow
        case 150..<300: return .orange
        default: return .red
        }
    }
    
    private var syncStatusColor: Color {
        switch sessionState.syncStatus {
        case .synchronized: return .green
        case .slightDelay: return .yellow
        case .moderate: return .orange
        case .desynchronized: return .red
        }
    }
    
    private var queueStatusColor: Color {
        switch sessionState.messageQueueSize {
        case 0..<10: return .green
        case 10..<25: return .yellow
        case 25..<50: return .orange
        default: return .red
        }
    }
    
    // MARK: - Helper Methods
    private func startRefreshTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            refreshTrigger.toggle()
        }
    }
    
    private func stopRefreshTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    private func runConnectionTest() {
        // Simulate connection test
        print("Running connection test...")
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

// MARK: - Supporting Views
struct StatusIndicator: View {
    let status: StateS
    let animate: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .scaleEffect(animate ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animate)
            
            Text(status.displayName)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(statusColor)
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .connected, .hosting, .gameInProgress: return .green
        case .connecting: return .yellow
        case .error, .connectionLost, .hostDisconnected: return .red
        default: return .gray
        }
    }
}

struct StatusRow: View {
    let title: String
    let value: String
    let icon: String
    var valueColor: Color = .white
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.callout)
                .foregroundColor(.blue)
                .frame(width: 20)
            
            Text(title)
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(valueColor)
        }
    }
}

struct PlayerConnectionRow: View {
    let player: NetworkPlayer
    
    var body: some View {
        HStack {
            Circle()
                .fill(connectionColor)
                .frame(width: 8, height: 8)
            
            Text(player.displayName)
                .font(.callout)
                .foregroundColor(.white)
            
            if player.isHost {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(player.connectionQuality.displayName)
                    .font(.caption)
                    .foregroundColor(connectionColor)
                
                Text("\(Int(player.ping * 1000))ms")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.05))
        )
    }
    
    private var connectionColor: Color {
        switch player.connectionQuality {
        case .excellent: return .green
        case .good: return .green
        case .fair: return .yellow
        case .poor: return .orange
        case .terrible: return .red
        }
    }
}

struct NetworkDetailRow: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    ConnectionStatusView(
        sessionState: SessionStateFactory.createTestSession(),
        onDismiss: {}
    )
    .preferredColorScheme(.dark)
}
