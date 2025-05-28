//
//  CodeInputVIew.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct CodeInputView: View {
    
    // MARK: - Properties
    @StateObject private var multipeerManager = MultipeerManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var audioManager = AudioManager.shared
    
    @State private var gameCode: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String = ""
    @State private var showError: Bool = false
    @State private var validationResult: ValidationResult?
    @State private var suggestions: [String] = []
    @State private var showSuggestions: Bool = false
    @State private var animateInput: Bool = false
    @State private var keyboardHeight: CGFloat = 0
    
    // Navigation
    @State private var navigateToLobby: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Constants
    private let maxCodeLength = Constants.maxGameCodeLength
    private let validCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Color.black
                        .ignoresSafeArea()
                    
                    // Animated Background Pattern
                    backgroundPattern
                    
                    ScrollView {
                        VStack(spacing: 32) {
                            
                            Spacer(minLength: 40)
                            
                            // Header Section
                            headerSection
                            
                            // Code Input Section
                            codeInputSection
                                .scaleEffect(animateInput ? 1.05 : 1.0)
                                .animation(.easeInOut(duration: 0.3), value: animateInput)
                            
                            // Validation and Suggestions
                            validationSection
                            
                            // Action Buttons
                            actionButtonsSection
                            
                            // Loading State
                            if isLoading {
                                loadingSection
                            }
                            
                            Spacer(minLength: 40)
                        }
                        .padding(.horizontal, 20)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    
                    // Error Overlay
                    if showError {
                        errorOverlay
                            .transition(.opacity.combined(with: .scale))
                    }
                }
                .onAppear {
                    setupKeyboardObservers()
                    animateInput = true
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    toolbarContent
                }
                .navigationDestination(isPresented: $navigateToLobby) {
                    LobbyView()
                        .navigationBarBackButtonHidden(true)
                }
            }
        }
    }
    
    // MARK: - Background Pattern
    private var backgroundPattern: some View {
        ZStack {
            // Animated stars/dots
            ForEach(0..<20, id: \.self) { i in
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: CGFloat.random(in: 2...4))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 2...4))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...2)),
                        value: animateInput
                    )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: "wifi")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.green)
                .rotationEffect(.degrees(animateInput ? 360 : 0))
                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: false), value: animateInput)
            
            // Title
            Text("Join Space Crew")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            // Subtitle
            Text("Enter the 6-character code shared by your commander")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    
    // MARK: - Code Input Section
    private var codeInputSection: some View {
        VStack(spacing: 20) {
            // Code Input Field
            HStack(spacing: 8) {
                ForEach(0..<maxCodeLength, id: \.self) { index in
                    codeCharacterBox(for: index)
                }
            }
            .padding(.horizontal)
            
            // Hidden TextField for keyboard input
            TextField("", text: $gameCode)
                .keyboardType(.asciiCapable)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .opacity(0)
                .frame(height: 0)
                .onChange(of: gameCode) { _, newValue in
                    handleCodeInput(newValue)
                }
        }
        .onTapGesture {
            // Focus on hidden text field
            UIApplication.shared.sendAction(#selector(UIResponder.becomeFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    private func codeCharacterBox(for index: Int) -> some View {
        let character = index < gameCode.count ? String(gameCode[gameCode.index(gameCode.startIndex, offsetBy: index)]) : ""
        let isActive = index == gameCode.count
        let isFilled = index < gameCode.count
        
        return ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive ? Color.green : (isFilled ? Color.blue : Color.gray),
                    lineWidth: isActive ? 3 : 2
                )
                .frame(width: 45, height: 55)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.3))
                )
                .scaleEffect(isActive ? 1.1 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: isActive)
            
            Text(character)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .scaleEffect(isFilled ? 1.0 : 0.8)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isFilled)
            
            // Blinking cursor for active position
            if isActive {
                Rectangle()
                    .fill(Color.green)
                    .frame(width: 2, height: 25)
                    .opacity(animateInput ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: animateInput)
            }
        }
    }
    
    // MARK: - Validation Section
    private var validationSection: some View {
        VStack(spacing: 12) {
            if let result = validationResult {
                HStack {
                    Image(systemName: result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(result.isValid ? .green : .red)
                    
                    Text(result.isValid ? "Valid game code format" : (result.errorMessage ?? "Invalid code"))
                        .font(.callout)
                        .foregroundColor(result.isValid ? .green : .red)
                }
                .transition(.opacity.combined(with: .slide))
            }
            
            // Suggestions
            if showSuggestions && !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Did you mean:")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                        ForEach(suggestions, id: \.self) { suggestion in
                            suggestionButton(suggestion)
                        }
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: validationResult?.isValid)
        .animation(.easeInOut(duration: 0.3), value: showSuggestions)
    }
    
    private func suggestionButton(_ suggestion: String) -> some View {
        Button(action: {
            gameCode = suggestion
            audioManager.playButtonSound()
            validateCode()
        }) {
            Text(suggestion)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            // Join Game Button
            joinGameButton
            
            // Alternative Actions
            HStack(spacing: 20) {
                // Create Game Button
                Button(action: createGame) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Create Game")
                    }
                    .font(.callout)
                    .foregroundColor(.blue)
                }
                .buttonStyle(ScaleButtonStyle())
                
                Divider()
                    .frame(height: 20)
                
                // Paste Code Button
                Button(action: pasteCode) {
                    HStack {
                        Image(systemName: "doc.on.clipboard")
                        Text("Paste Code")
                    }
                    .font(.callout)
                    .foregroundColor(.green)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }
    
    private var joinGameButton: some View {
        Button(action: joinGame) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                
                Text(isLoading ? "Joining..." : "Join Game")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        gameCode.count == maxCodeLength && validationResult?.isValid == true
                        ? Color.green
                        : Color.gray
                    )
            )
            .scaleEffect(gameCode.count == maxCodeLength ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: gameCode.count == maxCodeLength)
        }
        .disabled(gameCode.count != maxCodeLength || validationResult?.isValid != true || isLoading)
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .green))
                .scaleEffect(1.2)
            
            Text("Searching for game...")
                .font(.callout)
                .foregroundColor(.gray)
        }
        .transition(.opacity.combined(with: .scale))
    }
    
    // MARK: - Error Overlay
    private var errorOverlay: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Connection Failed")
                .font(.headline)
                .foregroundColor(.white)
            
            Text(errorMessage)
                .font(.callout)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 16) {
                Button("Retry") {
                    hideError()
                    joinGame()
                }
                .buttonStyle(PrimaryButtonStyle())
                
                Button("Cancel") {
                    hideError()
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.red, lineWidth: 1)
                )
        )
        .padding(.horizontal, 40)
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
                Button(action: clearCode) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
                .opacity(gameCode.isEmpty ? 0 : 1)
            }
        }
    }
    
    // MARK: - Methods
    private func handleCodeInput(_ newValue: String) {
        let filtered = String(newValue.uppercased().prefix(maxCodeLength).filter { validCharacters.contains($0) })
        
        if filtered != gameCode {
            gameCode = filtered
            validateCode()
            
            if !filtered.isEmpty {
                audioManager.playButtonSound()
            }
        }
    }
    
    private func validateCode() {
        validationResult = ValidationHelper.validateGameCode(gameCode)
        
        if let result = validationResult, !result.isValid && !result.suggestions.isEmpty {
            suggestions = result.suggestions
            showSuggestions = true
        } else {
            showSuggestions = false
        }
    }
    
    private func joinGame() {
        guard let result = validationResult, result.isValid else { return }
        
        isLoading = true
        audioManager.playButtonSound()
        
        multipeerManager.joinGame(with: gameCode) { [self] success, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if success {
                    // Navigate to lobby
                    navigateToLobby = true
                } else {
                    // Show error
                    errorMessage = error ?? "Failed to join game"
                    showError = true
                }
            }
        }
    }
    
    private func createGame() {
        audioManager.playButtonSound()
        
        let newGameCode = MultipeerManager.shared.createGame()
        gameCode = newGameCode
        
        // Navigate to lobby as host
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToLobby = true
        }
    }
    
    private func pasteCode() {
        if let clipboardString = UIPasteboard.general.string {
            let cleanedCode = GameCodeManager.cleanCode(clipboardString)
            if GameCodeManager.validateCode(cleanedCode) {
                gameCode = cleanedCode
                audioManager.playButtonSound()
                validateCode()
            }
        }
    }
    
    private func clearCode() {
        gameCode = ""
        validationResult = nil
        showSuggestions = false
        audioManager.playButtonSound()
    }
    
    private func hideError() {
        showError = false
        errorMessage = ""
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardSize = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                keyboardHeight = keyboardSize.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            keyboardHeight = 0
        }
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.blue)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout)
            .foregroundColor(.gray)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    CodeInputView()
        .preferredColorScheme(.dark)
}
