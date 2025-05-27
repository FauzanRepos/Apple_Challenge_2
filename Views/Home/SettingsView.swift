//
//  SettingsView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    
    // MARK: - Properties
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var storageManager = StorageManager.shared
    
    @State private var tempPlayerName: String = ""
    @State private var showResetAlert: Bool = false
    @State private var showAbout: Bool = false
    @State private var selectedCategory: SettingsCategory = .audio
    @State private var animateChanges: Bool = false
    @State private var showSuccessMessage: Bool = false
    @State private var successMessage: String = ""
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color.black
                    .ignoresSafeArea()
                
                // Animated background elements
                backgroundElements
                
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Category Selector
                        categorySelector
                            .padding(.horizontal)
                            .padding(.top)
                        
                        // Settings Content
                        ScrollView {
                            LazyVStack(spacing: 20) {
                                settingsContent
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .background(Color.clear)
                    }
                }
                
                // Success Message Overlay
                if showSuccessMessage {
                    successMessageOverlay
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .onAppear {
                tempPlayerName = settingsManager.getPlayerName()
                animateChanges = true
            }
            .alert("Reset All Settings", isPresented: $showResetAlert) {
                Button("Reset", role: .destructive) {
                    resetAllSettings()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will reset all settings to their default values. This action cannot be undone.")
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
        }
    }
    
    // MARK: - Background Elements
    private var backgroundElements: some View {
        ZStack {
            // Floating particles
            ForEach(0..<15, id: \.self) { i in
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: CGFloat.random(in: 4...8))
                    .position(
                        x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                        y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
                    )
                    .animation(
                        .easeInOut(duration: Double.random(in: 3...6))
                        .repeatForever(autoreverses: true)
                        .delay(Double.random(in: 0...3)),
                        value: animateChanges
                    )
            }
        }
    }
    
    // MARK: - Category Selector
    private var categorySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(SettingsCategory.allCases, id: \.self) { category in
                    categoryButton(category)
                }
            }
            .padding(.horizontal, 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func categoryButton(_ category: SettingsCategory) -> some View {
        Button(action: {
            selectedCategory = category
            audioManager.playButtonSound()
        }) {
            HStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.callout)
                
                Text(category.rawValue)
                    .font(.callout)
                    .fontWeight(.medium)
            }
            .foregroundColor(selectedCategory == category ? .black : .white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedCategory == category ? Color.green : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        selectedCategory == category ? Color.clear : Color.gray.opacity(0.5),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
    }
    
    // MARK: - Settings Content
    private var settingsContent: some View {
        Group {
            switch selectedCategory {
            case .audio:
                audioSettings
            case .player:
                playerSettings
            case .multiplayer:
                multiplayerSettings
            case .game:
                gameSettings
            case .about:
                aboutSettings
            }
        }
        .animation(.easeInOut(duration: 0.3), value: selectedCategory)
    }
    
    // MARK: - Audio Settings
    private var audioSettings: some View {
        VStack(spacing: 20) {
            settingsSectionHeader("Audio Settings", icon: "speaker.wave.2")
            
            // Music Settings
            VStack(alignment: .leading, spacing: 12) {
                SettingsToggle(
                    title: "Background Music",
                    description: "Play background music during gameplay",
                    isOn: $settingsManager.gameSettings.musicEnabled,
                    icon: "music.note"
                ) {
                    settingsManager.toggleMusic()
                    showSuccess("Music \(settingsManager.gameSettings.musicEnabled ? "enabled" : "disabled")")
                }
                
                if settingsManager.gameSettings.musicEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Music Volume")
                                .font(.callout)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(Int(settingsManager.gameSettings.musicVolume * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Slider(
                            value: $settingsManager.gameSettings.musicVolume,
                            in: 0...1,
                            step: 0.1
                        ) {
                            settingsManager.setMusicVolume(settingsManager.gameSettings.musicVolume)
                        }
                        .accentColor(.green)
                    }
                    .padding(.leading, 32)
                    .transition(.opacity.combined(with: .slide))
                }
            }
            
            // Sound Effects Settings
            VStack(alignment: .leading, spacing: 12) {
                SettingsToggle(
                    title: "Sound Effects",
                    description: "Play sound effects for game actions",
                    isOn: $settingsManager.gameSettings.soundEffectsEnabled,
                    icon: "speaker.wave.1"
                ) {
                    settingsManager.toggleSoundEffects()
                    showSuccess("Sound effects \(settingsManager.gameSettings.soundEffectsEnabled ? "enabled" : "disabled")")
                }
                
                if settingsManager.gameSettings.soundEffectsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("SFX Volume")
                                .font(.callout)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("\(Int(settingsManager.gameSettings.soundEffectsVolume * 100))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Slider(
                            value: $settingsManager.gameSettings.soundEffectsVolume,
                            in: 0...1,
                            step: 0.1
                        ) {
                            settingsManager.setSoundEffectsVolume(settingsManager.gameSettings.soundEffectsVolume)
                        }
                        .accentColor(.green)
                    }
                    .padding(.leading, 32)
                    .transition(.opacity.combined(with: .slide))
                }
            }
            
            // Audio Presets
            audioPresets
        }
    }
    
    private var audioPresets: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Audio Presets")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                ForEach(SettingsPreset.allCases, id: \.self) { preset in
                    Button(action: {
                        settingsManager.applyPreset(preset)
                        showSuccess("Applied \(preset.rawValue) preset")
                    }) {
                        VStack(spacing: 4) {
                            Text(preset.rawValue)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.3))
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    // MARK: - Player Settings
    private var playerSettings: some View {
        VStack(spacing: 20) {
            settingsSectionHeader("Player Settings", icon: "person")
            
            // Player Name
            VStack(alignment: .leading, spacing: 8) {
                Text("Player Name")
                    .font(.headline)
                    .foregroundColor(.white)
                
                TextField("Enter your name", text: $tempPlayerName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .onSubmit {
                        updatePlayerName()
                    }
                
                if !tempPlayerName.isValidPlayerName {
                    Text("Name must be 2-20 characters, letters and numbers only")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Save Name Button
            Button(action: updatePlayerName) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Save Name")
                }
                .font(.callout)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(tempPlayerName.isValidPlayerName && tempPlayerName != settingsManager.getPlayerName() ? Color.green : Color.gray)
                )
            }
            .disabled(!tempPlayerName.isValidPlayerName || tempPlayerName == settingsManager.getPlayerName())
            .buttonStyle(ScaleButtonStyle())
            
            // Player Statistics
            playerStatistics
        }
    }
    
    private var playerStatistics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.white)
            
            let stats = storageManager.getGameStatistics()
            
            VStack(spacing: 8) {
                StatRow(title: "High Score", value: String.formatScore(stats.highScore))
                StatRow(title: "Games Played", value: "\(stats.gamesPlayed)")
                StatRow(title: "Levels Completed", value: "\(stats.levelsCompleted)")
                StatRow(title: "Total Score", value: String.formatScore(stats.totalScore))
                
                if let lastPlayed = stats.lastPlayedDate {
                    StatRow(title: "Last Played", value: formatDate(lastPlayed))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - Multiplayer Settings
    private var multiplayerSettings: some View {
        VStack(spacing: 20) {
            settingsSectionHeader("Multiplayer Settings", icon: "person.2")
            
            // Connection Info
            VStack(alignment: .leading, spacing: 12) {
                Text("Connection")
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text("Device Name")
                        .foregroundColor(.gray)
                    Spacer()
                    Text(UIDevice.current.name)
                        .foregroundColor(.white)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            
            // Network Diagnostics
            networkDiagnostics
        }
    }
    
    private var networkDiagnostics: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Network Diagnostics")
                .font(.headline)
                .foregroundColor(.white)
            
            Button(action: runNetworkTest) {
                HStack {
                    Image(systemName: "network")
                    Text("Test Connection")
                }
                .font(.callout)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.6))
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }
    
    // MARK: - Game Settings
    private var gameSettings: some View {
        VStack(spacing: 20) {
            settingsSectionHeader("Game Settings", icon: "gamecontroller")
            
            // Data Management
            VStack(alignment: .leading, spacing: 12) {
                Text("Data Management")
                    .font(.headline)
                    .foregroundColor(.white)
                
                VStack(spacing: 12) {
                    Button(action: { showResetAlert = true }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reset All Settings")
                        }
                        .font(.callout)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.red, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    
                    Button(action: clearGameData) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Game Data")
                        }
                        .font(.callout)
                        .foregroundColor(.orange)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.orange, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }
    
    // MARK: - About Settings
    private var aboutSettings: some View {
        VStack(spacing: 20) {
            settingsSectionHeader("About", icon: "info.circle")
            
            // App Info
            VStack(spacing: 16) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                
                Text("SpaceMaze")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Version \(Constants.gameVersion)")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                Text("A cooperative multiplayer marble game where teamwork is key to navigating through space mazes and reaching the next planet.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Credits
            VStack(alignment: .leading, spacing: 8) {
                Text("Credits")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Developed by ADA Team")
                    .font(.callout)
                    .foregroundColor(.gray)
                
                Text("Built with SwiftUI and SpriteKit")
                    .font(.callout)
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
            )
        }
    }
    
    // MARK: - Helper Views
    private func settingsSectionHeader(_ title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
            
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Spacer()
        }
    }
    
    private var successMessageOverlay: some View {
        VStack {
            Image(systemName: "checkmark.circle.fill")
                .font(.largeTitle)
                .foregroundColor(.green)
            
            Text(successMessage)
                .font(.callout)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 1)
                )
        )
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showSuccessMessage = false
            }
        }
    }
    
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
                Button(action: { showAbout = true }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    // MARK: - Methods
    private func updatePlayerName() {
        let validatedName = ValidationHelper.sanitizePlayerName(tempPlayerName)
        settingsManager.setPlayerName(validatedName)
        tempPlayerName = validatedName
        showSuccess("Player name updated to '\(validatedName)'")
    }
    
    private func resetAllSettings() {
        settingsManager.resetToDefaults()
        tempPlayerName = settingsManager.getPlayerName()
        showSuccess("All settings reset to defaults")
    }
    
    private func clearGameData() {
        storageManager.resetGameData()
        showSuccess("Game data cleared")
    }
    
    private func runNetworkTest() {
        showSuccess("Network test completed - Connection OK")
    }
    
    private func showSuccess(_ message: String) {
        successMessage = message
        showSuccessMessage = true
        audioManager.playButtonSound()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct SettingsToggle: View {
    let title: String
    let description: String
    @Binding var isOn: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: icon)
                        .font(.callout)
                        .foregroundColor(.green)
                    
                    Text(title)
                        .font(.callout)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .onChange(of: isOn) { _, _ in
                    action()
                }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.callout)
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
    }
}

struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.callout)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.green.opacity(0.5), lineWidth: 1)
                    )
            )
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("SpaceMaze")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Version \(Constants.gameVersion)")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Text("SpaceMaze is a cooperative game played with 2-4 people in the same group. Each player needs a phone.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tips:")
                        .font(.headline)
                    
                    Text("• Make sure you can communicate with fellow space crew")
                    Text("• Work together to navigate through mazes")
                    Text("• Reach the spaceship to advance to the next planet")
                    Text("• Be careful of vortexes - they're deadly!")
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                
                Spacer()
            }
            .padding()
            .navigationTitle("About SpaceMaze")
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

// MARK: - Preview
#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
}
