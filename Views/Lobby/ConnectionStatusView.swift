//
//  ConnectionStatusView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ConnectionStatusView: View {
    @EnvironmentObject var multipeerManager: MultipeerManager
    
    var body: some View {
        HStack {
            Image(systemName: multipeerManager.connected ? "wifi" : "wifi.slash")
                .foregroundColor(multipeerManager.connected ? .green : .red)
            Text(multipeerManager.connected ? "Connected" : "Not Connected")
                .foregroundColor(.white)
                .font(.subheadline)
        }
        .padding(6)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)
    }
}
