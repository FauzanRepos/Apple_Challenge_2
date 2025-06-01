//
//  LoadingView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct LoadingView: View {
    let message: String?
    
    var body: some View {
        VStack(spacing: 18) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.5)
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.gray)
            }
        }
        .padding(40)
        .background(Color.white.opacity(0.95))
        .cornerRadius(20)
        .shadow(radius: 14)
    }
}
