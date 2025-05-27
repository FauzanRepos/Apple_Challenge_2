//
//  AudioManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import AVFoundation

class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    // MARK: - Properties
    @Published var isMusicEnabled: Bool = true {
        didSet {
            updateMusicState()
        }
    }
    
    @Published var areSoundEffectsEnabled: Bool = true
    @Published var musicVolume: Float = 0.7 {
        didSet {
            backgroundMusicPlayer?.volume = musicVolume
        }
    }
    @Published var soundEffectsVolume: Float = 0.8
    
    // MARK: - Audio Players
    private var backgroundMusicPlayer: AVAudioPlayer?
    private var soundEffectPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        setupAudioSession()
        loadSoundEffects()
    }
    
    // MARK: - Setup
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }
    
    private func loadSoundEffects() {
        let soundEffects = [
            "checkpoint": "checkpoint.wav",
            "collision": "collision.wav",
            "powerup": "powerup.wav",
            "victory": "victory.wav",
            "death": "death.wav",
            "button": "button.wav"
        ]
        
        for (key, filename) in soundEffects {
            if let path = Bundle.main.path(forResource: filename.replacingOccurrences(of: ".wav", with: ""), ofType: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
                    player.prepareToPlay()
                    player.volume = soundEffectsVolume
                    soundEffectPlayers[key] = player
                } catch {
                    print("❌ Failed to load sound effect \(filename): \(error)")
                }
            }
        }
    }
    
    // MARK: - Background Music
    func playBackgroundMusic() {
        guard isMusicEnabled else { return }
        
        guard let path = Bundle.main.path(forResource: "game_theme", ofType: "mp3") else {
            print("⚠️ Background music file not found")
            return
        }
        
        do {
            backgroundMusicPlayer = try AVAudioPlayer(contentsOf: URL(fileURLWithPath: path))
            backgroundMusicPlayer?.numberOfLoops = -1 // Loop indefinitely
            backgroundMusicPlayer?.volume = musicVolume
            backgroundMusicPlayer?.play()
        } catch {
            print("❌ Failed to play background music: \(error)")
        }
    }
    
    func pauseBackgroundMusic() {
        backgroundMusicPlayer?.pause()
    }
    
    func resumeBackgroundMusic() {
        guard isMusicEnabled else { return }
        backgroundMusicPlayer?.play()
    }
    
    func stopBackgroundMusic() {
        backgroundMusicPlayer?.stop()
        backgroundMusicPlayer = nil
    }
    
    private func updateMusicState() {
        if isMusicEnabled {
            if backgroundMusicPlayer?.isPlaying == false {
                resumeBackgroundMusic()
            }
        } else {
            pauseBackgroundMusic()
        }
    }
    
    // MARK: - Sound Effects
    func playCheckpointSound() {
        playSoundEffect("checkpoint")
    }
    
    func playCollisionSound() {
        playSoundEffect("collision")
    }
    
    func playPowerUpSound() {
        playSoundEffect("powerup")
    }
    
    func playVictorySound() {
        playSoundEffect("victory")
    }
    
    func playDeathSound() {
        playSoundEffect("death")
    }
    
    func playButtonSound() {
        playSoundEffect("button")
    }
    
    func playLevelCompleteSound() {
        playSoundEffect("victory")
    }
    
    private func playSoundEffect(_ soundKey: String) {
        guard areSoundEffectsEnabled,
              let player = soundEffectPlayers[soundKey] else { return }
        
        player.stop()
        player.currentTime = 0
        player.volume = soundEffectsVolume
        player.play()
    }
    
    // MARK: - Settings
    func updateSettings(musicEnabled: Bool, soundEffectsEnabled: Bool, musicVolume: Float, soundEffectsVolume: Float) {
        self.isMusicEnabled = musicEnabled
        self.areSoundEffectsEnabled = soundEffectsEnabled
        self.musicVolume = musicVolume
        self.soundEffectsVolume = soundEffectsVolume
        
        // Update existing players
        for player in soundEffectPlayers.values {
            player.volume = soundEffectsVolume
        }
    }
}
