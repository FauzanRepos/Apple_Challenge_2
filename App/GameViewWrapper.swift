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
    @StateObject private var permissionManager = LANPermissionManager.shared
    
    var body: some View {
        ZStack {
            // Warning View Layer
            WarningView()
        }
        .environmentObject(gameManager)
        .environmentObject(multipeerManager)
        .environmentObject(audioManager)
        .environmentObject(settingsManager)
        .environmentObject(storageManager)
        .environmentObject(permissionManager)
        .ignoresSafeArea(.all)
    }
}
