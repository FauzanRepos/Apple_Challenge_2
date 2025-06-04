//
//  GameView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct GameViewWrapper: View {
    let isHost: Bool
    @StateObject private var gameManager: GameManager
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    
    init(isHost: Bool) {
        self.isHost = isHost
        // Initialize GameManager with appropriate PlayerType
        _gameManager = StateObject(wrappedValue: GameManager(playerType: isHost ? .mapMover : .regular))
    }
    
    var body: some View {
        GameView(gameManager: gameManager)
            .navigationBarBackButtonHidden(true)
            .onChange(of: gameManager.shouldReturnToHome) { shouldReturn in
                if shouldReturn {
                    // Pop to root view
                    presentationMode.wrappedValue.dismiss()
                }
            }
    }
}

