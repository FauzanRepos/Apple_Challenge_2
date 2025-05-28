//
//  LoadingView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    
    // MARK: - Properties
    let title: String
    let message: String
    let style: LoadingStyle
    let showProgress: Bool
    let progress: Double
    let canCancel: Bool
    let onCancel: (() -> Void)?
    
    @State private var animationOffset: CGFloat = 0
    @State private var pulseAnimation = false
    @State private var rotationAngle: Double = 0
    @State private var sparklePhase: Double = 0
    
    // MARK: - Initialization
    init(
        title: String = "Loading",
        message: String = "Please wait...",
        style: LoadingStyle = .connection,
        showProgress: Bool = false,
        progress: Double = 0.0,
        canCancel: Bool = false,
        onCancel: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.style = style
        self.showProgress = showProgress
        self.progress = progress
        self.canCancel = canCancel
        self.onCancel = onCancel
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            backgroundOverlay
            
            // Main loading content
            loadingContent
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Background Overlay
    private var backgroundOverlay: some View {
        Color.black.opacity(0.8)
            .ignoresSafeArea()
            .overlay(
                // Animated background pattern
                backgroundPattern
            )
    }
    
    private var backgroundPattern: some View {
        Group {
            switch style {
            case .connection:
                connectionBackground
            case .levelLoading:
                levelLoadingBackground
            case .gameStart:
                gameStartBackground
            case .simple:
                EmptyView()
            }
        }
    }
    
    // MARK: - Loading Content
    private var loadingContent: some View {
        VStack(spacing: 24) {
            // Main loading indicator
            loadingIndicator
            
            // Title and message
            textContent
            
            // Progress bar
            if showProgress {
                progressBar
            }
            
            // Cancel button
            if canCancel {
                cancelButton
            }
        }
        .padding(32)
        .background(contentBackground)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)
        .scaleEffect(pulseAnimation ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: pulseAnimation)
    }
    
    // MARK: - Loading Indicators
    private var loadingIndicator: some View {
        Group {
            switch style {
            case .connection:
                connectionIndicator
            case .levelLoading:
                levelLoadingIndicator
            case .gameStart:
                gameStartIndicator
            case .simple:
                simpleIndicator
            }
        }
    }
    
    private var connectionIndicator: some View {
        ZStack {
            // Outer ring
            Circle()
                .stroke(Color.blue.opacity(0.3), lineWidth: 4)
                .frame(width: 80, height: 80)
            
            // Animated ring
            Circle()
                .trim(from: 0.0, to: 0.7)
                .stroke(
                    LinearGradient(
                        colors: [Color.blue, Color.cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(.degrees(rotationAngle))
                .animation(.linear(duration: 1.0).repeatForever(autoreverses: false), value: rotationAngle)
            
            // WiFi icon
            Image(systemName: "wifi")
                .font(.title)
                .foregroundColor(.blue)
                .scaleEffect(pulseAnimation ? 1.1 : 0.9)
        }
    }
    
    private var levelLoadingIndicator: some View {
        ZStack {
            // Planet/level icon
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple, Color.blue, Color.black],
                        center: .center,
                        startRadius: 10,
                        endRadius: 40
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
                .rotationEffect(.degrees(rotationAngle * 0.3))
                .animation(.linear(duration: 8.0).repeatForever(autoreverses: false), value: rotationAngle)
            
            // Orbiting elements
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.white)
                    .frame(width: 6, height: 6)
                    .offset(x: 50)
                    .rotationEffect(.degrees(rotationAngle + Double(index * 120)))
                    .animation(.linear(duration: 2.0).repeatForever(autoreverses: false), value: rotationAngle)
            }
        }
    }
    
    private var gameStartIndicator: some View {
        ZStack {
            // Spaceship icon
            Image(systemName: "airplane")
                .font(.system(size: 40))
                .foregroundColor(.white)
                .shadow(color: .blue, radius: 10)
                .offset(y: animationOffset)
                .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: animationOffset)
            
            // Sparkle effects
            ForEach(0..<8, id: \.self) { index in
                Image(systemName: "sparkle")
                    .font(.caption)
                    .foregroundColor(.yellow)
                    .offset(
                        x: cos(sparklePhase + Double(index) * .pi / 4) * 60,
                        y: sin(sparklePhase + Double(index) * .pi / 4) * 60
                    )
                    .opacity(0.7)
                    .scaleEffect(Double.random(in: 0.5...1.0))
                    .animation(.linear(duration: 3.0).repeatForever(autoreverses: false), value: sparklePhase)
            }
        }
    }
    
    private var simpleIndicator: some View {
        ProgressView()
            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
            .scaleEffect(1.5)
    }
    
    // MARK: - Text Content
    private var textContent: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                .frame(height: 8)
                .background(Color.gray.opacity(0.3))
                .cornerRadius(4)
            
            Text("\(Int(progress * 100))%")
                .font(.caption)
                .foregroundColor(.gray)
                .monospacedDigit()
        }
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button(action: {
            onCancel?()
        }) {
            Text("Cancel")
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.red)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(Color.red, lineWidth: 1)
                        .background(Color.clear)
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Styling
    private var contentBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.9))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
    
    // MARK: - Background Patterns
    private var connectionBackground: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...12))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(pulseAnimation ? 0.8 : 0.3)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...3))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...1)),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    private var levelLoadingBackground: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { i in
                Image(systemName: "star.fill")
                    .font(.system(size: CGFloat.random(in: 8...16)))
                    .foregroundColor(.white.opacity(0.2))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .rotationEffect(.degrees(rotationAngle * Double.random(in: 0.5...1.5)))
            }
        }
    }
    
    private var gameStartBackground: some View {
        ZStack {
            ForEach(0..<25, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: CGFloat.random(in: 6...14)))
                    .foregroundColor(.yellow.opacity(0.3))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .scaleEffect(pulseAnimation ? 1.2 : 0.8)
                    .animation(
                        .easeInOut(duration: Double.random(in: 1...2))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...1)),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
            rotationAngle = 360
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            animationOffset = -10
        }
        
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            sparklePhase = .pi * 2
        }
    }
}

// MARK: - Loading Styles
enum LoadingStyle {
    case connection     // For network connections
    case levelLoading   // For loading levels
    case gameStart      // For game initialization
    case simple         // Basic loading spinner
}

// MARK: - Preset Loading Views
extension LoadingView {
    
    static func connecting(canCancel: Bool = true, onCancel: (() -> Void)? = nil) -> LoadingView {
        LoadingView(
            title: "Connecting",
            message: "Searching for space crew...",
            style: .connection,
            canCancel: canCancel,
            onCancel: onCancel
        )
    }
    
    static func joiningGame(gameCode: String, canCancel: Bool = true, onCancel: (() -> Void)? = nil) -> LoadingView {
        LoadingView(
            title: "Joining Mission",
            message: "Connecting to crew \(gameCode)...",
            style: .connection,
            canCancel: canCancel,
            onCancel: onCancel
        )
    }
    
    static func loadingLevel(_ level: Int) -> LoadingView {
        LoadingView(
            title: "Loading Planet \(level)",
            message: "Preparing navigation systems...",
            style: .levelLoading
        )
    }
    
    static func startingGame(playerCount: Int) -> LoadingView {
        LoadingView(
            title: "Mission Starting",
            message: "Synchronizing \(playerCount) crew members...",
            style: .gameStart
        )
    }
    
    static func syncingPlayers(progress: Double = 0.0) -> LoadingView {
        LoadingView(
            title: "Syncing Players",
            message: "Establishing secure connection...",
            style: .connection,
            showProgress: true,
            progress: progress
        )
    }
}

// MARK: - Loading Screen Manager
class LoadingScreenManager: ObservableObject {
    @Published var isLoading = false
    @Published var currentLoadingView: LoadingView?
    
    func show(_ loadingView: LoadingView) {
        currentLoadingView = loadingView
        isLoading = true
    }
    
    func hide() {
        isLoading = false
        currentLoadingView = nil
    }
    
    func updateProgress(_ progress: Double) {
        // This would require the LoadingView to be updated with new progress
        // For now, we'll handle this in the specific loading implementations
    }
}

// MARK: - Loading Screen Overlay
struct LoadingScreenOverlay: View {
    @StateObject private var loadingManager = LoadingScreenManager()
    
    var body: some View {
        Group {
            if loadingManager.isLoading, let loadingView = loadingManager.currentLoadingView {
                loadingView
            }
        }
        .environmentObject(loadingManager)
    }
}

// MARK: - Environment Key
private struct LoadingManagerKey: EnvironmentKey {
    static let defaultValue = LoadingScreenManager()
}

extension EnvironmentValues {
    var loadingManager: LoadingScreenManager {
        get { self[LoadingManagerKey.self] }
        set { self[LoadingManagerKey.self] = newValue }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        LoadingView.connecting()
        
        LoadingView.loadingLevel(3)
        
        LoadingView.startingGame(playerCount: 4)
        
        LoadingView.syncingPlayers(progress: 0.7)
    }
    .background(Color.gray)
}
