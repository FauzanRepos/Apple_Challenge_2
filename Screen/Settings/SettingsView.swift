import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var highScoreManager = HighScoreManager.shared
    @State private var showClearConfirmation = false
    
    @State private var bgmVolume: Double
    @State private var sfxVolume: Double
    @State private var isBgmMuted: Bool
    @State private var isSfxMuted: Bool
    
    init() {
        let settings = AudioManager.shared.settings
        _bgmVolume = State(initialValue: settings.bgmVolume)
        _sfxVolume = State(initialValue: settings.sfxVolume)
        _isBgmMuted = State(initialValue: settings.isBgmMuted)
        _isSfxMuted = State(initialValue: settings.isSfxMuted)
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 24) {
                // Header
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    Text("SETTINGS")
                        .font(.custom("PressStart2P-Regular", size: 24))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Empty view for symmetry
                    Color.clear.frame(width: 24, height: 24)
                }
                .padding()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Volume Controls
                        VStack(spacing: 32) {
                            VolumeSliderView(
                                title: "BACKGROUND MUSIC",
                                volume: $bgmVolume,
                                isMuted: $isBgmMuted,
                                showMuteButton: false
                            ) { volume in
                                audioManager.setBGMVolume(volume)
                                // Test sound when adjusting
                                if !audioManager.settings.isBgmMuted {
                                    audioManager.playBGM()
                                }
                            }
                            
                            VolumeSliderView(
                                title: "SOUND EFFECTS",
                                volume: $sfxVolume,
                                isMuted: $isSfxMuted,
                                showMuteButton: false
                            ) { volume in
                                audioManager.setSFXVolume(volume)
                                // Test sound when adjusting
                                if !audioManager.settings.isSfxMuted {
                                    audioManager.playSFX(.powerup)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 32)
                        
                        // High Scores Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("HIGH SCORES")
                                .font(.custom("PressStart2P-Regular", size: 18))
                                .foregroundColor(.white)
                            
                            if !highScoreManager.scores.isEmpty {
                                Button(action: {
                                    showClearConfirmation = true
                                }) {
                                    HStack {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                        Text("Clear All High Scores")
                                            .font(.custom("PressStart2P-Regular", size: 12))
                                            .foregroundColor(.red)
                                    }
                                    .padding()
                                    .background(Color.red.opacity(0.2))
                                    .cornerRadius(8)
                                }
                            } else {
                                Text("No high scores yet")
                                    .font(.custom("PressStart2P-Regular", size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // About Section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("ABOUT")
                                .font(.custom("PressStart2P-Regular", size: 18))
                                .foregroundColor(.white)
                            
                            Text("Space Maze is an exciting arcade game where you navigate through challenging mazes in space. Test your skills, collect power-ups, and reach the finish line!")
                                .font(.custom("PressStart2P-Regular", size: 12))
                                .foregroundColor(.gray)
                                .lineSpacing(8)
                        }
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .padding(.horizontal)
                        
                        // Version
                        Text("Version 1.0.0")
                            .font(.custom("PressStart2P-Regular", size: 12))
                            .foregroundColor(.gray)
                            .padding(.bottom)
                    }
                }
            }
        }
        .alert("Clear High Scores?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                highScoreManager.clearHighScores()
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .onChange(of: isBgmMuted) { oldValue, newValue in
            audioManager.toggleBGMMute()
        }
        .onChange(of: isSfxMuted) { oldValue, newValue in
            audioManager.toggleSFXMute()
        }
    }
} 