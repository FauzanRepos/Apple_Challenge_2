//
//  SwiftUIView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 22/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct HighScoreView: View {
    @EnvironmentObject var storageManager: StorageManager
    
    var body: some View {
        VStack(spacing: 8) {
            Image("HighScoreBoard_Mock")
                .resizable()
                .frame(width: 240, height: 64)
            Text("High Score")
                .font(.headline)
                .foregroundColor(.yellow)
            Text("Planet \(storageManager.highScore.planet) Section \(storageManager.highScore.section)/\(Constants.numberOfSections)")
                .font(.system(.title2, design: .rounded))
                .bold()
                .foregroundColor(.white)
        }
        .padding(.vertical, 10)
    }
}
