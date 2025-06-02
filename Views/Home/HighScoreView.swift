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
        
            
        ZStack {
            
            Image("HighScoreBoard_Empty")
                .resizable()
                .frame(width: UIScreen.main.bounds.width * 0.85, height: 140)
            
            VStack {
                Text("High Score")
                    .font(.custom("VCROSDMono", size: 20))
                    .foregroundColor(Color("text"))
                    .padding(.top, 11)
                
                Spacer()
                
                Text("NO RECORD")
                    .font(.custom("VCROSDMono", size: 20))
                    .foregroundColor(Color("text"))
                    .padding(.bottom, 60)
//                    ZStack {
//                        HStack(spacing: 45) {
//                            ForEach(0..<6) { _ in
//                                Circle()
//                                    .fill(Color(.systemGray2))
//                                    .frame(width: 15, height: 15)
//                            }
//                        }
//                        Rectangle()
//                            .fill(Color(.systemGray2))
//                            .frame(width: 15*6 + 45*5, height: 5)
                }
                .frame(width: UIScreen.main.bounds.width * 0.85, height: 140)
            }
    }
}
//        }
//        .padding()

#Preview {
    HighScoreView()
}

