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
        VStack(spacing: 0) {
            ForEach(0..<4) { index in
                if index < multipeerManager.players.count {
                    // Player row
                    HStack {
                        Circle()
                            .fill(Color("text"))
                            .frame(width: 7.4, height: 7.4)
                            .padding(.trailing, 8)
                        
                        Text(multipeerManager.players[index].peerID)
                            .font(.custom("VCROSDMono", size: 16))
                            .foregroundStyle(Color("text"))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Image(multipeerManager.players[index].isReady ? "ReadyPlayerLight" : "NotReadyPlayerLight")
                            .resizable()
                            .frame(width: 21, height: 21)
                        
                        if multipeerManager.players[index].isMapMover {
                            Text("🧭 Map Mover")
                                .foregroundColor(.green)
                                .font(.caption)
                                .padding(.leading, 4)
                        }
                    }
                    .padding(.horizontal)
                    .frame(height: 30)
                    
                } else {
                    HStack {
                        Circle()
                            .fill(Color("text").opacity(0.3))
                            .frame(width: 7.4, height: 7.4)
                            .padding(.trailing, 8)
                        
                        Text("Waiting for player...")
                            .font(.custom("VCROSDMono", size: 16))
                            .foregroundStyle(Color("text").opacity(0.3))
                            .fontWeight(.semibold)
                            .lineLimit(1)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .frame(height: 30)
                }
                
                if index < 3 {
                    Rectangle()
                        .fill(Color("text").opacity(0.3))
                        .frame(height: 3)
                        .padding(.horizontal)
                }
            }
        }
        .frame(width: UIScreen.main.bounds.width * 0.68, height: 144)
        .padding(.horizontal)
        .padding(.vertical)
        .overlay(
            Rectangle()
                .stroke(Color("text"), lineWidth: 3)
                .frame(width: UIScreen.main.bounds.width * 0.68, height: 144)
        )
    }
}
