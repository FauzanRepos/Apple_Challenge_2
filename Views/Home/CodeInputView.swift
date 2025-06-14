//
//  CodeInputView.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SwiftUI

struct CodeInputView: View {
    @Binding var code: String
    @State private var showInvalid = false
    
    var onSubmit: ((String) -> Void)?
    
    var body: some View {
        VStack(spacing: 16) {
            TextField("Enter Room Code", text: $code)
                .textCase(.uppercase)
                .keyboardType(.asciiCapable)
                .frame(width: 160)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .onSubmit {
                    submitCode()
                }
                .onChange(of: code) { newValue in
                    // Limit to 4 characters and uppercase
                    let filtered = String(newValue.uppercased().prefix(4))
                    if filtered != newValue {
                        code = filtered
                    }
                }
            
            Button(action: submitCode) {
                Text("Join Room")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(code.count != 4) // Fixed: Now matches 4-character generation
            
            if showInvalid {
                Text("Invalid code. Please try again.")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding()
    }
    
    private func submitCode() {
        if ValidationHelper.isValidRoomCode(code) {
            showInvalid = false
            onSubmit?(code)
        } else {
            showInvalid = true
        }
    }
}
