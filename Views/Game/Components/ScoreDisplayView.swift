//
//  ScoreDisplayView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ScoreDisplayView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image("HighScoreC_GreenLight")
                .resizable()
                .frame(width: 28, height: 28)
            Text(gameManager.scoreText)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.trailing, 6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.5))
        .cornerRadius(10)
    }
}
