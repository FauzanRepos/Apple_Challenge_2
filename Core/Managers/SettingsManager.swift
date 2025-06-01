//
//  SettingsManager.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import Combine

/// Handles persistent user settings for audio, controls, etc.
final class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var musicVolume: Float = 1.0 {
        didSet { save() }
    }
    @Published var sfxVolume: Float = 1.0 {
        didSet { save() }
    }
    @Published var controlSensitivity: Float = 1.0 {
        didSet { save() }
    }
    @Published var accelerometerInverted: Bool = false {
        didSet { save() }
    }
    
    private let musicKey = "musicVolume"
    private let sfxKey = "sfxVolume"
    private let sensitivityKey = "controlSensitivity"
    private let invertKey = "accelInvert"
    
    private init() {
        load()
    }
    
    func load() {
        let defaults = UserDefaults.standard
        musicVolume = defaults.float(forKey: musicKey)
        sfxVolume = defaults.float(forKey: sfxKey)
        controlSensitivity = defaults.float(forKey: sensitivityKey)
        accelerometerInverted = defaults.bool(forKey: invertKey)
    }
    
    func save() {
        let defaults = UserDefaults.standard
        defaults.set(musicVolume, forKey: musicKey)
        defaults.set(sfxVolume, forKey: sfxKey)
        defaults.set(controlSensitivity, forKey: sensitivityKey)
        defaults.set(accelerometerInverted, forKey: invertKey)
    }
    
    func resetToDefaults() {
        musicVolume = 1.0
        sfxVolume = 1.0
        controlSensitivity = 1.0
        accelerometerInverted = false
        save()
    }
}
