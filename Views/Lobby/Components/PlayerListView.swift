//
//  PlayerListView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct PlayerListView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Players in Room (\(multipeerManager.players.count))")
                .font(.headline)
                .foregroundColor(.white)
            ForEach(multipeerManager.players, id: \.id) { player in
                HStack {
                    Circle()
                        .fill(Constants.playerColors[player.colorIndex % Constants.playerColors.count])
                        .frame(width: 24, height: 24)
                    Text(player.peerID)
                        .foregroundColor(.white)
                        .font(.body)
                    if player.isMapMover {
                        Text("🧭 Map Mover")
                            .foregroundColor(.green)
                            .font(.caption)
                            .padding(.leading, 4)
                    }
                }
            }
        }
        .padding(.horizontal)
    }
}
