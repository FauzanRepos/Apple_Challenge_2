//
//  ResumeCountdownOverlay.swift
//  Space Maze
//
//  Created by Apple Dev on 01/06/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct ResumeCountdownOverlay: View {
    @State var count: Int
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 22) {
                Text("Resuming in…")
                    .font(.title)
                    .foregroundColor(.white)
                Text("\(count)")
                    .font(.system(size: 80, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
        }
    }
}
