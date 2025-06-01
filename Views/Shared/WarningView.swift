//
//  WarningView.swift
//  Space Maze
//
//  Created by WESLY CHAU LI ZHAN on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct WarningView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 18) {
            Image("AlertPage")
                .resizable()
                .frame(width: 84, height: 84)
            Text("Warning")
                .font(.title2)
                .foregroundColor(.orange)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
        }
        .padding(24)
        .background(Color.yellow.opacity(0.85))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
