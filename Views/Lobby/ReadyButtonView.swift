//
//  ReadyButtonView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ReadyButtonView: View {
    @Binding var isReady: Bool
    var onReady: () -> Void
    
    var body: some View {
        Button(action: {
            isReady.toggle()
            onReady()
        }) {
            Text(isReady ? "Ready!" : "Tap when Ready")
                .foregroundColor(.white)
                .padding(.horizontal, 36)
                .padding(.vertical, 14)
                .background(isReady ? Color.green : Color.blue)
                .cornerRadius(12)
                .font(.headline)
        }
    }
}
