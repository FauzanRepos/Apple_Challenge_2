//
//  HomeView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct HomeView: View {

    // MARK: - Properties
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var storageManager = StorageManager.shared
    @StateObject private var multipeerManager = MultipeerManager.shared

    @State private var navigateToLobby = false
    @State private var navigateToCodeInput = false
    @State private var navigateToSettings = false
    @State private var showAbout = false
    @State private var animateElements = false
    @State private var showWelcomeMessage = false
    @State private var pulseHighScore = false
    @State private var rotateSpaceship = false
    @State private var sparkleEffect = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundView

                ScrollView {
                    VStack(spacing: 24) {

                        Spacer(minLength: 20)

                        // Header with animated spaceship
                        headerSection

                        // High Score Section with animations
                        HighScoreView(animate: $pulseHighScore)
                            .scaleEffect(pulseHighScore ? 1.02 : 1.0)
                            .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: pulseHighScore)

                        // Captain's Message with typewriter effect
                        captainMessageSection

                        // Action Buttons
                        actionButtonsSection

                        // Footer
                        footerSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 20)
                }
                .scrollIndicators(.hidden)

                // Floating sparkles
                if sparkleEffect {
                    sparkleOverlay
                }

                // Welcome message overlay
                if showWelcomeMessage {
                    welcomeMessageOverlay
                }
            }
            .onAppear {
                setupAnimations()
                checkWelcomeMessage()
                startBackgroundMusic()
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToLobby) {
                LobbyView()
            }
            .navigationDestination(isPresented: $navigateToCodeInput) {
                CodeInputView()
            }
            .navigationDestination(isPresented: $navigateToSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showAbout) {
                AboutGameView()
            }
        }
    }

    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base background
            Color.black
                .ignoresSafeArea()

            // Animated starfield
            ForEach(0..<50, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(Double.random(in: 0.2...0.8)))
                    .frame(width: CGFloat.random(in: 1...3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(animateElements ? 1.0 : 0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateElements
                    )
            }

            // Moving nebula effect
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.blue.opacity(0.1),
                    Color.green.opacity(0.1),
                    Color.clear
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .blur(radius: 20)
            .scaleEffect(animateElements ? 1.2 : 0.8)
            .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animateElements)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Animated spaceship
            HStack {
                Spacer()

                ZStack {
                    // Spaceship glow effect
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 50
                            )
                        )
                        .frame(width: 100, height: 100)
                        .scaleEffect(animateElements ? 1.2 : 0.8)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateElements)

                    // Spaceship icon
                    Image(systemName: "airplane")
                        .font(.system(size: 40, weight: .light))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotateSpaceship ? 360 : 0))
                        .scaleEffect(animateElements ? 1.1 : 0.9)
                        .animation(.linear(duration: 10).repeatForever(autoreverses: false), value: rotateSpaceship)
                }

                Spacer()
            }

            // Game title with shimmer effect
            HStack {
                Text("SpaceMaze")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .blue, .green, .white],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(animateElements ? 1.05 : 0.95)
                    .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateElements)
            }
        }
    }

    // MARK: - Captain's Message Section
    private var captainMessageSection: some View {
        VStack(spacing: 16) {
            // Mission briefing header
            HStack {
                Image(systemName: "person.badge.key.fill")
                    .font(.title3)
                    .foregroundColor(.orange)
                    .scaleEffect(animateElements ? 1.1 : 0.9)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animateElements)

                Text("Mission Briefing")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
                    .opacity(animateElements ? 1.0 : 0.7)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateElements)

                Spacer()
            }

            // Animated message container
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("🚨")
                        .font(.title2)
                        .scaleEffect(animateElements ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: animateElements)

                    Text("Emergency Protocol Activated")
                        .font(.callout)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }

                Text("This is HQ. The mothership is crashing. Emergency protocol activated.")
                    .font(.callout)
                    .foregroundColor(.white)

                Divider()
                    .background(Color.gray.opacity(0.5))

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("👨‍✈️")
                        Text("**Commander's Mission:**")
                            .font(.callout)
                            .foregroundColor(.green)
                    }
                    Text("• Create escape room and share the code")
                        .font(.caption)
                        .foregroundColor(.gray)

                    HStack {
                        Text("👥")
                        Text("**Crew Member's Mission:**")
                            .font(.callout)
                            .foregroundColor(.blue)
                    }
                    Text("• Join the room using the commander's code")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.5), Color.blue.opacity(0.5)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .green.opacity(0.2), radius: 8, x: 0, y: 4)
            )
            .scaleEffect(animateElements ? 1.01 : 0.99)
            .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: animateElements)
        }
    }

    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 20) {
            // Primary action - Start/Create Game
            StartGameSliderView {
                audioManager.playButtonSound()
                handleStartGame()
            }
            .scaleEffect(animateElements ? 1.02 : 0.98)
            .animation(.easeInOut(duration: 3).repeatForever(autoreverses: true), value: animateElements)

            // Secondary actions
            HStack(spacing: 16) {
                // Join Game Button
                ActionButton(
                    title: "Join Mission",
                    icon: "wifi",
                    color: .blue,
                    action: {
                        audioManager.playButtonSound()
                        navigateToCodeInput = true
                    }
                )

                // Settings Button
                ActionButton(
                    title: "Settings",
                    icon: "gearshape.fill",
                    color: .gray,
                    action: {
                        audioManager.playButtonSound()
                        navigateToSettings = true
                    }
                )
            }
        }
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            // Version info
            VStack(alignment: .leading, spacing: 4) {
                Text("ver. \(Constants.gameVersion)")
                    .font(.caption)
                    .foregroundColor(.gray)

                if let lastPlayed = storageManager.getLastPlayedDate() {
                    Text("Last: \(formatDate(lastPlayed))")
                        .font(.caption2)
                        .foregroundColor(.gray.opacity(0.7))
                }
            }

            Spacer()

            // About button with pulse effect
            Button(action: {
                audioManager.playButtonSound()
                showAbout = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "questionmark.circle")
                        .font(.caption)
                    Text("About")
                        .font(.caption)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .scaleEffect(animateElements ? 1.05 : 0.95)
            .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: animateElements)
            .buttonStyle(ScaleButtonStyle())
        }
    }

    // MARK: - Sparkle Overlay
    private var sparkleOverlay: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(Color.random)
                    .opacity(Double.random(in: 0.5...1.0))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...3))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...1)),
                        value: sparkleEffect
                    )
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Welcome Message Overlay
    private var welcomeMessageOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.wave.fill")
                .font(.system(size: 50))
                .foregroundColor(.yellow)
                .rotationEffect(.degrees(animateElements ? 20 : -20))
                .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateElements)

            VStack(spacing: 8) {
                Text("Welcome, \(settingsManager.getPlayerName())!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Text("Ready for your space mission?")
                    .font(.callout)
                    .foregroundColor(.gray)
            }

            Button("Let's Go!") {
                audioManager.playButtonSound()
                showWelcomeMessage = false
                sparkleEffect = true

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    sparkleEffect = false
                }
            }
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(Color.green)
                    .shadow(color: .green.opacity(0.5), radius: 8)
            )
            .buttonStyle(ScaleButtonStyle())
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green, lineWidth: 2)
                )
                .shadow(color: .green.opacity(0.3), radius: 20)
        )
        .scaleEffect(showWelcomeMessage ? 1.0 : 0.8)
        .opacity(showWelcomeMessage ? 1.0 : 0.0)
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showWelcomeMessage)
    }

    // MARK: - Methods
    private func setupAnimations() {
        withAnimation(.easeInOut(duration: 1)) {
            animateElements = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            rotateSpaceship = true
            pulseHighScore = true
        }
    }

    private func checkWelcomeMessage() {
        let gamesPlayed = storageManager.getGamesPlayed()
        if gamesPlayed == 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showWelcomeMessage = true
            }
        }
    }

    private func startBackgroundMusic() {
        if settingsManager.gameSettings.musicEnabled {
            audioManager.playBackgroundMusic()
        }
    }

    private func handleStartGame() {
        // Create a new multiplayer game as host
        let gameCode = multipeerManager.createGame()

        // Small delay for dramatic effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            navigateToLobby = true
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Action Button Component
struct ActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// MARK: - About Game View
struct AboutGameView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Game intro
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About SpaceMaze")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("SpaceMaze is a cooperative multiplayer game where teamwork is essential. Guide your marble through dangerous space mazes to reach the next planet.")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }

                    // How to play
                    VStack(alignment: .leading, spacing: 12) {
                        Text("How to Play")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("📱")
                                Text("Tilt your device to control your marble")
                            }
                            HStack {
                                Text("🤝")
                                Text("Work together with 2-8 players")
                            }
                            HStack {
                                Text("🚀")
                                Text("Reach the spaceship to advance levels")
                            }
                            HStack {
                                Text("💫")
                                Text("Collect checkpoints and avoid vortexes")
                            }
                            HStack {
                                Text("❤️")
                                Text("Share 5 lives as a team")
                            }
                        }
                        .font(.callout)
                        .foregroundColor(.secondary)
                    }

                    // Warning
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚠️ Warning")
                            .font(.headline)
                            .foregroundColor(.red)

                        Text("This game contains flashing lights that may cause discomfort for some players.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension Color {
    static var random: Color {
        return Color(
            red: Double.random(in: 0...1),
            green: Double.random(in: 0...1),
            blue: Double.random(in: 0...1)
        )
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
