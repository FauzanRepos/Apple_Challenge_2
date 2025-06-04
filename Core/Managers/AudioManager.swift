//
//  AudioManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import AVFoundation

/// Singleton audio manager for background music and SFX.
final class AudioManager: ObservableObject {
    static let shared = AudioManager()
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var volume: Float = 1.0
    
    private init() {}
    
    // MARK: - Background Music
    func playBGM(_ name: String, loop: Bool = true) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else { return }
        do {
            bgmPlayer = try AVAudioPlayer(contentsOf: url)
            bgmPlayer?.volume = volume
            bgmPlayer?.numberOfLoops = loop ? -1 : 0
            bgmPlayer?.prepareToPlay()
            bgmPlayer?.play()
        } catch {
            print("[AudioManager] Failed to play BGM: \(error)")
        }
    }
    
    func stopBGM() {
        bgmPlayer?.stop()
    }
    
    // MARK: - Sound Effects
    func playSFX(_ name: String, xtension: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: xtension) else { return }
        do {
            sfxPlayer = try AVAudioPlayer(contentsOf: url)
            sfxPlayer?.volume = volume
            sfxPlayer?.numberOfLoops = 0
            sfxPlayer?.prepareToPlay()
            sfxPlayer?.play()
        } catch {
            print("[AudioManager] Failed to play SFX: \(error)")
        }
    }
    
    // MARK: - Volume
    func setVolume(_ value: Float) {
        volume = max(0.0, min(1.0, value))
        bgmPlayer?.volume = volume
        sfxPlayer?.volume = volume
    }
}
