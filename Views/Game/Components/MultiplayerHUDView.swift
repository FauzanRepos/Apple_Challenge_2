//
//  MultiplayerHUDView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct MultiplayerHUDView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(multipeerManager.players, id: \.id) { player in
                VStack(spacing: 2) {
                    Circle()
                        .fill(Constants.playerColors[player.colorIndex % Constants.playerColors.count])
                        .frame(width: 18, height: 18)
                    if player.isMapMover {
                        Text("🧭")
                            .font(.caption)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.4))
        .cornerRadius(8)
    }
}
