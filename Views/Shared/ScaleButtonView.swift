//
//  ScaleButtonView.swift
//  Space Maze
//
//  Created by Apple Dev on 28/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ScaleButtonView: View {
    let title: String
    var action: () -> Void
    
    @State private var pressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.18, dampingFraction: 0.6)) {
                pressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                pressed = false
                action()
            }
        }) {
            Text(title)
                .foregroundColor(.white)
                .padding(.vertical, 16)
                .padding(.horizontal, 36)
                .background(Color.blue)
                .cornerRadius(16)
                .scaleEffect(pressed ? 0.92 : 1.0)
                .shadow(color: .blue.opacity(0.25), radius: 5, x: 0, y: 4)
        }
    }
}
