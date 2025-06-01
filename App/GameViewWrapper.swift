//
//  GameView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct GameViewWrapper: View {
    @StateObject private var gameManager = GameManager.shared
    @StateObject private var multipeerManager = MultipeerManager.shared
    @StateObject private var audioManager = AudioManager.shared
    @StateObject private var settingsManager = SettingsManager.shared
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some View {
        NavigationStack {
            HomeView()
                .environmentObject(gameManager)
                .environmentObject(multipeerManager)
                .environmentObject(audioManager)
                .environmentObject(settingsManager)
                .environmentObject(storageManager)
        }
        .navigationViewStyle(.stack)
    }
}
