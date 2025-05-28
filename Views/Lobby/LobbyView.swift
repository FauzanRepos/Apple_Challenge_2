//
//  LobbyView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct LobbyView: View {
    
    @StateObject private var multipeerManager = MultipeerManager.shared
    @StateObject private var sessionState = SessionState()
    @StateObject private var audioManager = AudioManager.shared

    @State private var gameCode: String = ""
    @State private var players: [NetworkPlayer] = []
    @State private var isHost: Bool = false
    @State private var navigateToGame: Bool = false
    @State private var showCodeInput: Bool = false
    @State private var animateCode: Bool = false
    @State private var showConnectionStatus: Bool = false

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()

                // Animated background stars
                backgroundStars

                VStack(spacing: 24) {

                    Spacer(minLength: 20)

                    // Header Section
                    headerSection

                    // Ship Code Section
                    shipCodeSection

                    // Players List Section
                    PlayerListView(players: $players)

                    // Action Section
                    actionSection

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 20)

                // Connection Status Overlay
                if showConnectionStatus {
                    ConnectionStatusView(
                        sessionState: sessionState,
                        onDismiss: { showConnectionStatus = false }
                    )
                    .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationBarBackButtonHidden(true)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                setupLobby()
            }
            .navigationDestination(isPresented: $navigateToGame) {
                GameViewWrapper()
                    .ignoresSafeArea()
                    .navigationBarBackButtonHidden(true)
            }
            .sheet(isPresented: $showCodeInput) {
                CodeInputView()
            }
        }
    }

    // MARK: - Background Stars
    private var backgroundStars: some View {
        ZStack {
            ForEach(0..<30, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.3...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(animateCode ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateCode
                    )
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Spaceship icon with glow
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.yellow.opacity(0.3), Color.clear],
                            center: .center,
                            startRadius: 10,
                            endRadius: 40
                        )
                    )
                    .frame(width: 80, height: 80)
                    .scaleEffect(animateCode ? 1.2 : 0.8)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateCode)

                Image(systemName: "airplane.departure")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.yellow)
            }

            Text("SwiftFun")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.yellow)
                .scaleEffect(animateCode ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateCode)
        }
    }

    // MARK: - Ship Code Section
    private var shipCodeSection: some View {
        VStack(spacing: 16) {
            Text("Ship Code")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)

            // Code Display
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    )
                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)

                VStack(spacing: 12) {
                    Text(gameCode.isEmpty ? "LOADING..." : gameCode)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .tracking(8)
                        .scaleEffect(animateCode ? 1.1 : 0.9)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateCode)

                    Text(isHost ? "Share the code with fellow space crew" : "Enter the code given by your commander")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .frame(height: 100)
        }
    }

    // MARK: - Action Section
    private var actionSection: some View {
        VStack(spacing: 16) {
            if isHost {
                // Host Actions
                ReadyButtonView(
                    isReady: players.areAllReady(),
                    canStart: players.count >= 2 && players.areAllReady(),
                    playerCount: players.count,
                    onStart: startGame
                )
            } else {
                // Join Game Button
                Button(action: { showCodeInput = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Join Different Room")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue.opacity(0.8))
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }

            // Connection Status Button
            Button(action: { showConnectionStatus = true }) {
                HStack {
                    Circle()
                        .fill(sessionState.overallNetworkQuality.color == "#00FF00" ? .green : .red)
                        .frame(width: 8, height: 8)

                    Text("Connection Status")
                        .font(.callout)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Toolbar
    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: { dismiss() }) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showConnectionStatus = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Methods
    private func setupLobby() {
        gameCode = generateGameCode()
        isHost = true

        // Add local player
        let localPlayer = NetworkPlayerFactory.createLocalPlayer(name: "Commander")
        localPlayer.isHost = true
        localPlayer.isLocal = true
        localPlayer.playerType = .mapMover
        players.append(localPlayer)

        sessionState.createGame(with: gameCode)
        sessionState.addPlayer(localPlayer)

        animateCode = true

        // Start advertising game
        multipeerManager.startHosting(gameCode: gameCode)
    }

    private func generateGameCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<6).map{ _ in characters.randomElement()! })
    }

    private func startGame() {
        guard players.count >= 2 && players.areAllReady() else { return }

        audioManager.playButtonSound()
        sessionState.startGame()

        // Navigate to game
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToGame = true
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    LobbyView()
        .preferredColorScheme(.dark)
}
