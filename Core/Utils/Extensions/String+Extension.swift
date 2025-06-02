//
//  String+Extension.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation

extension String {
    /// Pads the string on the left with zeros until it reaches the given length
    func leftPad(toLength: Int) -> String {
        let padCount = toLength - self.count
        if padCount <= 0 { return self }
        return String(repeating: "0", count: padCount) + self
    }
    
    /// Returns a display-friendly duration string from seconds
    static func durationString(from seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", minutes, secs)
    }
}
