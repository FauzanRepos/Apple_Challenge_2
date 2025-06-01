//
//  StartGameSliderView.swift
//  Marble
//
//  Created by WESLY CHAU LI ZHAN on 23/05/25.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import SwiftUI

struct StartGameSliderView: View {
    var onSlide: () -> Void
    @State private var sliderValue: Double = 0.0
    private let threshold: Double = 1.0
    
    var body: some View {
        VStack {
            Text("Slide to Start")
                .font(.headline)
                .foregroundColor(.white)
            Slider(
                value: $sliderValue,
                in: 0...threshold,
                onEditingChanged: { editing in
                    if !editing && sliderValue >= threshold {
                        sliderValue = 0
                        onSlide()
                    }
                }
            )
            .accentColor(.green)
            .frame(width: 220)
        }
    }
}
