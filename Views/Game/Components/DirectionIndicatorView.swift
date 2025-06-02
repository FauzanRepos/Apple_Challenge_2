//
//  DirectionIndicatorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct DirectionIndicatorView: View {
    let direction: CGVector
    let label: String?
    
    var body: some View {
        VStack {
            if let label = label {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white)
            }
            Image("Compass")
                .resizable()
                .frame(width: 40, height: 40)
                .rotationEffect(.radians(atan2(direction.dy, direction.dx)))
        }
        .padding(6)
        .background(Color.black.opacity(0.5))
        .cornerRadius(14)
    }
}
