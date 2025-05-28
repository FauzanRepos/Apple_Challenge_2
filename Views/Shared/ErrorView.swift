//
//  ErrorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    
    // MARK: - Properties
    let error: GameError
    let onRetry: (() -> Void)?
    let onDismiss: (() -> Void)?
    let showDismiss: Bool
    
    @State private var shakeAnimation = false
    @State private var pulseAnimation = false
    @State private var showDetails = false
    
    // MARK: - Initialization
    init(
        error: GameError,
        onRetry: (() -> Void)? = nil,
        onDismiss: (() -> Void)? = nil,
        showDismiss: Bool = true
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
        self.showDismiss = showDismiss
    }
    
    var body: some View {
        ZStack {
            // Background overlay
            backgroundOverlay
            
            // Error content
            errorContent
        }
        .onAppear {
            startAnimations()
            playErrorSound()
        }
    }
    
    // MARK: - Background Overlay
    private var backgroundOverlay: some View {
        Color.black.opacity(0.85)
            .ignoresSafeArea()
            .overlay(
                // Error background pattern
                errorBackgroundPattern
            )
    }
    
    private var errorBackgroundPattern: some View {
        ZStack {
            ForEach(0..<15, id: \.self) { i in
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: CGFloat.random(in: 20...40)))
                    .foregroundColor(.red.opacity(0.1))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .opacity(pulseAnimation ? 0.3 : 0.1)
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: pulseAnimation
                    )
            }
        }
    }
    
    // MARK: - Error Content
    private var errorContent: some View {
        VStack(spacing: 24) {
            // Error icon
            errorIcon
            
            // Error message
            errorMessage
            
            // Error details (expandable)
            if error.hasDetails {
                errorDetails
            }
            
            // Action buttons
            actionButtons
        }
        .padding(32)
        .background(errorBackground)
        .cornerRadius(20)
        .shadow(color: .red.opacity(0.3), radius: 20, x: 0, y: 10)
        .scaleEffect(shakeAnimation ? 1.02 : 1.0)
        .offset(x: shakeAnimation ? -2 : 0)
        .animation(.easeInOut(duration: 0.1), value: shakeAnimation)
    }
    
    // MARK: - Error Icon
    private var errorIcon: some View {
        ZStack {
            // Pulsing background
            Circle()
                .fill(Color.red.opacity(0.2))
                .frame(width: 100, height: 100)
                .scaleEffect(pulseAnimation ? 1.2 : 1.0)
                .opacity(pulseAnimation ? 0.3 : 0.8)
                .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
            
            // Error icon
            Image(systemName: error.iconName)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.red)
                .shadow(color: .red.opacity(0.5), radius: 5)
        }
    }
    
    // MARK: - Error Message
    private var errorMessage: some View {
        VStack(spacing: 12) {
            Text(error.title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
            
            Text(error.message)
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    // MARK: - Error Details
    private var errorDetails: some View {
        VStack(spacing: 8) {
            Button(action: {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showDetails.toggle()
                }
            }) {
                HStack {
                    Text("Details")
                        .font(.callout)
                        .foregroundColor(.gray)
                    
                    Spacer()
                    
                    Image(systemName: showDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
            
            if showDetails {
                VStack(alignment: .leading, spacing: 8) {
                    if let suggestion = error.suggestion {
                        HStack(alignment: .top) {
                            Image(systemName: "lightbulb")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            
                            Text(suggestion)
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    if let technicalDetails = error.technicalDetails {
                        HStack(alignment: .top) {
                            Image(systemName: "info.circle")
                                .font(.caption)
                                .foregroundColor(.blue)
                            
                            Text(technicalDetails)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .textSelection(.enabled)
                        }
                    }
                    
                    if let errorCode = error.errorCode {
                        HStack {
                            Text("Error Code:")
                                .font(.caption2)
                                .foregroundColor(.gray)
                            
                            Text(errorCode)
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.5))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Primary action (Retry)
            if let retry = onRetry {
                Button(action: {
                    AudioManager.shared.playButtonSound()
                    retry()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                            .font(.callout)
                        
                        Text(error.retryButtonText)
                            .font(.callout)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color.blue)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Secondary action (Dismiss)
            if showDismiss, let dismiss = onDismiss {
                Button(action: {
                    AudioManager.shared.playButtonSound()
                    dismiss()
                }) {
                    Text(error.dismissButtonText)
                        .font(.callout)
                        .foregroundColor(.gray)
                        .padding(.vertical, 12)
                }
                .buttonStyle(ScaleButtonStyle())
            }
            
            // Additional actions
            additionalActions
        }
    }
    
    // MARK: - Additional Actions
    private var additionalActions: some View {
        Group {
            switch error.type {
            case .connectionFailed:
                Button("Check Network Settings") {
                    openNetworkSettings()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
            case .gameNotFound:
                Button("Browse Available Games") {
                    // This would navigate to a game browser
                }
                .font(.caption)
                .foregroundColor(.blue)
                
            case .permissionDenied:
                Button("Open Settings") {
                    openAppSettings()
                }
                .font(.caption)
                .foregroundColor(.blue)
                
            default:
                EmptyView()
            }
        }
    }
    
    // MARK: - Styling
    private var errorBackground: some View {
        RoundedRectangle(cornerRadius: 20)
            .fill(Color.black.opacity(0.95))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.red.opacity(0.6), Color.red.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
            )
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            pulseAnimation = true
        }
        
        // Shake animation for critical errors
        if error.severity == .critical {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeInOut(duration: 0.1).repeatCount(6, autoreverses: true)) {
                    shakeAnimation = true
                }
            }
        }
    }
    
    private func playErrorSound() {
        switch error.severity {
        case .low:
            break // No sound for low severity
        case .medium:
            AudioManager.shared.playButtonSound() // Soft sound
        case .high, .critical:
            AudioManager.shared.playCollisionSound() // Attention-grabbing sound
        }
    }
    
    // MARK: - System Actions
    private func openNetworkSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Game Error Model
struct GameError: Identifiable {
    let id = UUID()
    let type: GameErrorType
    let title: String
    let message: String
    let suggestion: String?
    let technicalDetails: String?
    let errorCode: String?
    let severity: ErrorSeverity
    let retryButtonText: String
    let dismissButtonText: String
    
    init(
        type: GameErrorType,
        title: String? = nil,
        message: String? = nil,
        suggestion: String? = nil,
        technicalDetails: String? = nil,
        errorCode: String? = nil,
        severity: ErrorSeverity? = nil,
        retryButtonText: String = "Try Again",
        dismissButtonText: String = "Cancel"
    ) {
        self.type = type
        self.title = title ?? type.defaultTitle
        self.message = message ?? type.defaultMessage
        self.suggestion = suggestion ?? type.defaultSuggestion
        self.technicalDetails = technicalDetails
        self.errorCode = errorCode
        self.severity = severity ?? type.defaultSeverity
        self.retryButtonText = retryButtonText
        self.dismissButtonText = dismissButtonText
    }
    
    var iconName: String {
        return type.iconName
    }
    
    var hasDetails: Bool {
        return suggestion != nil || technicalDetails != nil || errorCode != nil
    }
}

// MARK: - Game Error Types
enum GameErrorType {
    case connectionFailed
    case gameNotFound
    case gameFull
    case hostDisconnected
    case networkTimeout
    case invalidGameCode
    case permissionDenied
    case levelLoadFailed
    case audioInitFailed
    case syncFailed
    case unknownError
    
    var defaultTitle: String {
        switch self {
        case .connectionFailed: return "Connection Failed"
        case .gameNotFound: return "Game Not Found"
        case .gameFull: return "Game is Full"
        case .hostDisconnected: return "Host Disconnected"
        case .networkTimeout: return "Connection Timeout"
        case .invalidGameCode: return "Invalid Game Code"
        case .permissionDenied: return "Permission Required"
        case .levelLoadFailed: return "Level Load Failed"
        case .audioInitFailed: return "Audio Error"
        case .syncFailed: return "Sync Failed"
        case .unknownError: return "Unknown Error"
        }
    }
    
    var defaultMessage: String {
        switch self {
        case .connectionFailed:
            return "Unable to connect to the game. Please check your network connection and try again."
        case .gameNotFound:
            return "The game you're trying to join doesn't exist or has ended."
        case .gameFull:
            return "This game already has the maximum number of players."
        case .hostDisconnected:
            return "The game host has disconnected. The game session has ended."
        case .networkTimeout:
            return "The connection timed out. Please check your network and try again."
        case .invalidGameCode:
            return "The game code you entered is not valid. Please check and try again."
        case .permissionDenied:
            return "This feature requires permission to access your device's capabilities."
        case .levelLoadFailed:
            return "Failed to load the game level. Please try again."
        case .audioInitFailed:
            return "Unable to initialize audio. Some sounds may not work properly."
        case .syncFailed:
            return "Failed to synchronize game state with other players."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
    
    var defaultSuggestion: String? {
        switch self {
        case .connectionFailed:
            return "Make sure you're connected to WiFi or cellular data."
        case .gameNotFound:
            return "Double-check the game code or ask the host to share it again."
        case .gameFull:
            return "Wait for a player to leave or ask the host to start a new game."
        case .hostDisconnected:
            return "Try creating your own game or joining a different one."
        case .networkTimeout:
            return "Move closer to your WiFi router or switch to a better network."
        case .invalidGameCode:
            return "Game codes are 6 characters long and contain only letters and numbers."
        case .permissionDenied:
            return "Go to Settings to grant the required permissions."
        case .levelLoadFailed:
            return "Check your device's available storage space."
        case .audioInitFailed:
            return "Try restarting the app or checking your device's audio settings."
        case .syncFailed:
            return "Check your connection and ask other players to do the same."
        case .unknownError:
            return "Try restarting the app or your device."
        }
    }
    
    var defaultSeverity: ErrorSeverity {
        switch self {
        case .connectionFailed, .hostDisconnected, .networkTimeout, .syncFailed:
            return .high
        case .gameNotFound, .gameFull, .invalidGameCode:
            return .medium
        case .permissionDenied, .levelLoadFailed:
            return .medium
        case .audioInitFailed:
            return .low
        case .unknownError:
            return .critical
        }
    }
    
    var iconName: String {
        switch self {
        case .connectionFailed, .networkTimeout:
            return "wifi.exclamationmark"
        case .gameNotFound:
            return "questionmark.circle"
        case .gameFull:
            return "person.crop.circle.badge.xmark"
        case .hostDisconnected:
            return "person.slash"
        case .invalidGameCode:
            return "key.slash"
        case .permissionDenied:
            return "lock.circle"
        case .levelLoadFailed:
            return "folder.badge.minus"
        case .audioInitFailed:
            return "speaker.slash"
        case .syncFailed:
            return "arrow.triangle.2.circlepath"
        case .unknownError:
            return "exclamationmark.triangle"
        }
    }
}

// MARK: - Error Severity
enum ErrorSeverity {
    case low      // Minor issues that don't prevent gameplay
    case medium   // Issues that affect functionality but can be worked around
    case high     // Serious issues that prevent core functionality
    case critical // Fatal errors that prevent the app from functioning
}

// MARK: - Error Factory
struct GameErrorFactory {
    
    static func connectionFailed(technicalDetails: String? = nil) -> GameError {
        GameError(
            type: .connectionFailed,
            technicalDetails: technicalDetails,
            errorCode: "NET001"
        )
    }
    
    static func gameNotFound(gameCode: String) -> GameError {
        GameError(
            type: .gameNotFound,
            message: "Game with code '\(gameCode)' was not found.",
            errorCode: "GAME001"
        )
    }
    
    static func gameFull(maxPlayers: Int) -> GameError {
        GameError(
            type: .gameFull,
            message: "This game already has \(maxPlayers) players (maximum allowed).",
            errorCode: "GAME002"
        )
    }
    
    static func hostDisconnected() -> GameError {
        GameError(
            type: .hostDisconnected,
            retryButtonText: "Find New Game",
            errorCode: "NET002"
        )
    }
    
    static func invalidGameCode(_ code: String) -> GameError {
        GameError(
            type: .invalidGameCode,
            message: "'\(code)' is not a valid game code.",
            suggestion: "Game codes are exactly 6 characters long and contain only letters and numbers (no I, O, 0, or 1).",
            errorCode: "GAME003"
        )
    }
    
    static func networkTimeout() -> GameError {
        GameError(
            type: .networkTimeout,
            technicalDetails: "Connection timed out after 30 seconds.",
            errorCode: "NET003"
        )
    }
    
    static func levelLoadFailed(level: Int, error: Error) -> GameError {
        GameError(
            type: .levelLoadFailed,
            message: "Failed to load level \(level).",
            technicalDetails: error.localizedDescription,
            errorCode: "LEVEL001"
        )
    }
    
    static func syncFailed(reason: String) -> GameError {
        GameError(
            type: .syncFailed,
            technicalDetails: reason,
            errorCode: "SYNC001"
        )
    }
    
    static func unknown(error: Error) -> GameError {
        GameError(
            type: .unknownError,
            technicalDetails: error.localizedDescription,
            errorCode: "UNKNOWN"
        )
    }
}

// MARK: - Inline Error View
struct InlineErrorView: View {
    let error: GameError
    let onRetry: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.iconName)
                .font(.title3)
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(error.title)
                    .font(.callout)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(error.message)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            if let retry = onRetry {
                Button("Retry") {
                    retry()
                }
                .font(.caption)
                .foregroundColor(.blue)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        ErrorView(
            error: GameErrorFactory.connectionFailed(),
            onRetry: { print("Retry tapped") },
            onDismiss: { print("Dismiss tapped") }
        )
        
        InlineErrorView(
            error: GameErrorFactory.gameNotFound(gameCode: "ABC123"),
            onRetry: { print("Retry") }
        )
    }
}
