//
//  LivesIndicatorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct LivesIndicatorView: View {
    @EnvironmentObject var gameManager: GameManager
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<Constants.maxTeamLives, id: \.self) { idx in
                Image(idx < gameManager.teamLives ? "HearthBar_On" : "HearthBar_Off")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
        }
    }
}
