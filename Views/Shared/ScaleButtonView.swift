//
//  ScaleButtonView.swift
//  Space Maze
//
//  Created by Apple Dev on 28/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

// MARK: - Custom Button Styles
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
