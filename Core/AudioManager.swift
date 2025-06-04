import AVFoundation
import SwiftUI

public class AudioManager: ObservableObject {
    public static let shared = AudioManager()
    
    @Published public private(set) var settings: AudioSettings {
        didSet {
            settings.save()
            updateVolumes()
        }
    }
    
    private var bgmPlayer: AVAudioPlayer?
    private var sfxPlayers: [URL: AVAudioPlayer] = [:]
    private var wasPlayingBeforeBackground = false
    
    // Sound file names
    public enum SoundFile: String, CaseIterable {
        case bgm = "bgm_space"
        case powerup = "sfx_powerup"
        case finish = "sfx_finish"
        case death = "sfx_death"
        case collision = "sfx_collision"
        case checkpoint = "sfx_checkpoint"
        
        var filePath: String {
            return self.rawValue
        }
    }
    
    private init() {
        print("DEBUG: Initializing AudioManager")
        self.settings = AudioSettings.load()
        print("DEBUG: Loaded settings - BGM Volume: \(settings.bgmVolume), SFX Volume: \(settings.sfxVolume)")
        setupAudioSession()
        preloadSounds()
        updateVolumes()
        setupNotifications()
    }
    
    private func setupNotifications() {
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleEnterBackground),
                                             name: UIApplication.willResignActiveNotification,
                                             object: nil)
        
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleEnterForeground),
                                             name: UIApplication.didBecomeActiveNotification,
                                             object: nil)
        
        // Add audio interruption handling
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAudioInterruption),
                                             name: AVAudioSession.interruptionNotification,
                                             object: nil)
        
        // Add audio route change handling
        NotificationCenter.default.addObserver(self,
                                             selector: #selector(handleAudioRouteChange),
                                             name: AVAudioSession.routeChangeNotification,
                                             object: nil)
    }
    
    @objc private func handleEnterBackground() {
        print("DEBUG: App entering background")
        wasPlayingBeforeBackground = bgmPlayer?.isPlaying ?? false
        stopAllSounds()
    }
    
    @objc private func handleEnterForeground() {
        print("DEBUG: App entering foreground")
        if wasPlayingBeforeBackground {
            playBGM()
        }
    }
    
    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            print("DEBUG: Audio interruption began")
            stopAllSounds()
            
        case .ended:
            print("DEBUG: Audio interruption ended")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            
            if options.contains(.shouldResume) {
                print("DEBUG: Audio interruption ended - should resume")
                // Try to reactivate the audio session
                do {
                    try AVAudioSession.sharedInstance().setActive(true)
                    if wasPlayingBeforeBackground {
                        playBGM()
                    }
                } catch {
                    print("ERROR: Failed to reactivate audio session: \(error)")
                }
            }
            
        @unknown default:
            print("WARNING: Unknown audio interruption type")
        }
    }
    
    @objc private func handleAudioRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        print("DEBUG: Audio route changed - reason: \(reason)")
        
        switch reason {
        case .oldDeviceUnavailable:
            print("DEBUG: Old audio device unavailable")
            stopAllSounds()
            if wasPlayingBeforeBackground {
                playBGM()
            }
        case .newDeviceAvailable:
            print("DEBUG: New audio device available")
            // Optionally handle new device connection
        case .categoryChange:
            print("DEBUG: Audio category changed")
            // Ensure our preferred category is still set
            setupAudioSession()
        default:
            break
        }
    }
    
    private func stopAllSounds() {
        print("DEBUG: Stopping all sounds")
        stopBGM()
        sfxPlayers.values.forEach { player in
            player.stop()
            player.currentTime = 0
        }
    }
    
    private func setupAudioSession() {
        do {
            print("DEBUG: Setting up audio session")
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default)
            try audioSession.setActive(true)
            print("DEBUG: Audio session setup successful")
            
            // Print current audio session configuration for debugging
            print("DEBUG: Audio Session Configuration:")
            print("- Category: \(audioSession.category.rawValue)")
            print("- Mode: \(audioSession.mode.rawValue)")
            print("- Options: \(audioSession.categoryOptions.rawValue)")
        } catch {
            print("ERROR: Failed to set up audio session: \(error.localizedDescription)")
            print("ERROR: Audio session error details: \(error)")
        }
    }
    
    private func preloadSounds() {
        print("DEBUG: Starting to preload sounds")
        // Print the bundle path for debugging
        print("DEBUG: Bundle path: \(Bundle.main.bundlePath)")
        
        // List all resources in the bundle for debugging
        if let resourcePath = Bundle.main.resourcePath {
            print("DEBUG: Listing all resources in bundle:")
            do {
                let items = try FileManager.default.contentsOfDirectory(atPath: resourcePath)
                print("DEBUG: Found \(items.count) items in bundle:")
                items.forEach { print("  - \($0)") }
            } catch {
                print("ERROR: Could not list bundle contents: \(error)")
            }
        }
        
        // Preload all sound effects
        SoundFile.allCases.forEach { sound in
            print("DEBUG: Attempting to load sound: \(sound.rawValue)")
            
            // First try mp3 extension
            if let url = Bundle.main.url(forResource: sound.filePath, withExtension: "mp3") {
                loadSound(sound: sound, url: url)
            }
            // If mp3 fails, try wav as fallback
            else if let url = Bundle.main.url(forResource: sound.filePath, withExtension: "wav") {
                loadSound(sound: sound, url: url)
            }
            else {
                print("ERROR: Could not find sound file \(sound.rawValue) with either mp3 or wav extension")
                print("DEBUG: Searched in bundle path: \(Bundle.main.bundlePath)")
                print("DEBUG: Searched in resource path: \(Bundle.main.resourcePath ?? "nil")")
            }
        }
    }
    
    private func loadSound(sound: SoundFile, url: URL) {
        print("DEBUG: Found sound file at path: \(url.path)")
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            if sound == .bgm {
                bgmPlayer = player
                player.numberOfLoops = -1 // Infinite loop for BGM
                print("DEBUG: BGM player initialized successfully")
                print("DEBUG: BGM player volume: \(player.volume)")
                print("DEBUG: BGM player duration: \(player.duration)")
            } else {
                sfxPlayers[url] = player
                print("DEBUG: SFX player initialized for \(sound.rawValue)")
                print("DEBUG: SFX player volume: \(player.volume)")
                print("DEBUG: SFX player duration: \(player.duration)")
            }
            player.prepareToPlay()
        } catch {
            print("ERROR: Failed to load sound \(sound.rawValue)")
            print("ERROR: Error details: \(error.localizedDescription)")
            
            // Additional debugging for file attributes
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                print("DEBUG: File attributes:")
                print("- Size: \(attributes[.size] ?? "unknown")")
                print("- Created: \(attributes[.creationDate] ?? "unknown")")
                print("- Type: \(attributes[.type] ?? "unknown")")
            } catch {
                print("ERROR: Could not read file attributes: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateVolumes() {
        // Update BGM volume
        if let player = bgmPlayer {
            let newVolume = Float(settings.isBgmMuted ? 0 : settings.bgmVolume)
            player.volume = newVolume
            print("DEBUG: Updated BGM volume to \(newVolume)")
        } else {
            print("DEBUG: Cannot update BGM volume - player is nil")
        }
        
        // Update SFX volumes
        sfxPlayers.values.forEach { player in
            let newVolume = Float(settings.isSfxMuted ? 0 : settings.sfxVolume)
            player.volume = newVolume
            print("DEBUG: Updated SFX volume to \(newVolume)")
        }
    }
    
    // MARK: - Public Methods
    
    public func setBGMVolume(_ volume: Double) {
        print("DEBUG: Setting BGM volume to \(volume)")
        settings.bgmVolume = volume
        if bgmPlayer?.isPlaying == false {
            playBGM()
        }
    }
    
    public func setSFXVolume(_ volume: Double) {
        print("DEBUG: Setting SFX volume to \(volume)")
        settings.sfxVolume = volume
    }
    
    public func toggleBGMMute() {
        settings.isBgmMuted.toggle()
        print("DEBUG: BGM muted: \(settings.isBgmMuted)")
        if settings.isBgmMuted {
            bgmPlayer?.pause()
        } else if bgmPlayer?.isPlaying == false {
            playBGM()
        }
    }
    
    public func toggleSFXMute() {
        settings.isSfxMuted.toggle()
        print("DEBUG: SFX muted: \(settings.isSfxMuted)")
    }
    
    public func playBGM() {
        print("DEBUG: Attempting to play BGM")
        guard let player = bgmPlayer else {
            print("DEBUG: Cannot play BGM - player is nil")
            return
        }
        
        guard !settings.isBgmMuted else {
            print("DEBUG: Cannot play BGM - audio is muted")
            return
        }
        
        // Check audio session status
        let audioSession = AVAudioSession.sharedInstance()
        print("DEBUG: Current audio session active: \(audioSession.isOtherAudioPlaying)")
        print("DEBUG: Current route: \(audioSession.currentRoute.outputs.map { $0.portType.rawValue })")
        
        player.volume = Float(settings.bgmVolume)
        print("DEBUG: Playing BGM with volume \(player.volume)")
        print("DEBUG: BGM player status - isPlaying: \(player.isPlaying), currentTime: \(player.currentTime), duration: \(player.duration)")
        
        if !player.isPlaying {
            player.currentTime = 0
            let success = player.play()
            print("DEBUG: BGM playback started - success: \(success)")
            
            // Double check if playback actually started
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                print("DEBUG: BGM playback check after 0.1s - isPlaying: \(player.isPlaying)")
            }
        } else {
            print("DEBUG: BGM is already playing")
        }
    }
    
    public func stopBGM() {
        print("DEBUG: Stopping BGM")
        if let player = bgmPlayer {
            player.stop()
            player.currentTime = 0
            print("DEBUG: BGM stopped successfully")
        } else {
            print("DEBUG: Cannot stop BGM - player is nil")
        }
    }
    
    public func pauseBGM() {
        print("DEBUG: Pausing BGM")
        if let player = bgmPlayer {
            player.pause()
            print("DEBUG: BGM paused successfully")
        } else {
            print("DEBUG: Cannot pause BGM - player is nil")
        }
    }
    
    public func playSFX(_ sound: SoundFile) {
        print("DEBUG: Attempting to play SFX: \(sound.rawValue)")
        guard !settings.isSfxMuted else {
            print("DEBUG: Cannot play SFX - audio is muted")
            return
        }
        
        guard let url = Bundle.main.url(forResource: sound.filePath, withExtension: "mp3") else {
            print("ERROR: Could not find SFX file URL for \(sound.filePath)")
            return
        }
        
        guard let player = sfxPlayers[url] else {
            print("ERROR: Could not find SFX player for \(sound.filePath)")
            return
        }
        
        // Check audio session status
        let audioSession = AVAudioSession.sharedInstance()
        print("DEBUG: Current audio session active: \(audioSession.isOtherAudioPlaying)")
        print("DEBUG: Current route: \(audioSession.currentRoute.outputs.map { $0.portType.rawValue })")
        
        player.volume = Float(settings.sfxVolume)
        print("DEBUG: Playing SFX \(sound.rawValue) with volume \(player.volume)")
        print("DEBUG: SFX player status - duration: \(player.duration)")
        player.currentTime = 0
        let success = player.play()
        print("DEBUG: SFX playback started - success: \(success)")
        
        // Double check if playback actually started
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("DEBUG: SFX playback check after 0.1s - isPlaying: \(player.isPlaying)")
        }
    }
} 