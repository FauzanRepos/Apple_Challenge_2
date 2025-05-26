//
//  SwiftUIView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 22/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct HighScoreView: View {
    var body: some View {
        VStack (spacing: 16) {
            Text("High Score")
                .font(.largeTitle)
                .bold()
                .foregroundColor(.black)
            ZStack {
                Rectangle()
                    .foregroundColor(Color(.systemGray6))
                    .frame(width: UIScreen.main.bounds.width * 0.85, height: 110)
                VStack (spacing: 16) {
                    Text("NO RECORD")
                        .font(.title)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                    ZStack {
                        HStack(spacing: 45) {
                            ForEach(0..<6) { _ in
                                Circle()
                                    .fill(Color(.systemGray2))
                                    .frame(width: 15, height: 15)
                            }
                        }
                        Rectangle()
                            .fill(Color(.systemGray2))
                            .frame(width: 15*6 + 45*5, height: 5)
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray4))
        )
        .padding()
    }
}

#Preview {
    HighScoreView()
}
