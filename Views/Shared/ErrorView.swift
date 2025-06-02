//
//  ErrorView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            Image("AlertPage_Red")
                .resizable()
                .frame(width: 84, height: 84)
            Text("Error")
                .font(.title)
                .foregroundColor(.red)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
            if let retryAction = retryAction {
                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(radius: 12)
    }
}
