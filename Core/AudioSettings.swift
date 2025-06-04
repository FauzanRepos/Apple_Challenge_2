import Foundation

public struct AudioSettings: Codable {
    public var bgmVolume: Double
    public var sfxVolume: Double
    public var isBgmMuted: Bool
    public var isSfxMuted: Bool
    
    public static let defaultSettings = AudioSettings(
        bgmVolume: 0.7,
        sfxVolume: 1.0,
        isBgmMuted: false,
        isSfxMuted: false
    )
    
    static let userDefaultsKey = "audioSettings"
    
    public static func load() -> AudioSettings {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey),
              let settings = try? JSONDecoder().decode(AudioSettings.self, from: data)
        else {
            return defaultSettings
        }
        return settings
    }
    
    public func save() {
        if let encoded = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(encoded, forKey: AudioSettings.userDefaultsKey)
        }
    }
    
    public init(bgmVolume: Double, sfxVolume: Double, isBgmMuted: Bool, isSfxMuted: Bool) {
        self.bgmVolume = bgmVolume
        self.sfxVolume = sfxVolume
        self.isBgmMuted = isBgmMuted
        self.isSfxMuted = isSfxMuted
    }
} 