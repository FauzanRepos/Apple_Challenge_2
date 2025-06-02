//
//  SettingsView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var settingsManager: SettingsManager
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Audio")) {
                    HStack {
                        Text("Music Volume")
                        Slider(value: $settingsManager.musicVolume, in: 0...1)
                    }
                    HStack {
                        Text("SFX Volume")
                        Slider(value: $settingsManager.sfxVolume, in: 0...1)
                    }
                }
                Section(header: Text("Controls")) {
                    HStack {
                        Text("Sensitivity")
                        Slider(value: $settingsManager.controlSensitivity, in: 0.5...2.0, step: 0.05)
                    }
                    Toggle("Invert Accelerometer", isOn: $settingsManager.accelerometerInverted)
                }
                Button("Reset to Defaults") {
                    settingsManager.resetToDefaults()
                }
                .foregroundColor(.red)
            }
            .navigationTitle("Settings")
        }
    }
}
