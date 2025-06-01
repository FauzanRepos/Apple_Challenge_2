//
//  CGPoint+Extensions.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import CoreGraphics

extension CGPoint {
    /// Distance between two points
    func distance(to other: CGPoint) -> CGFloat {
        sqrt(pow(x - other.x, 2) + pow(y - other.y, 2))
    }
    
    /// Adds two CGPoints
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    /// Subtracts two CGPoints
    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    /// Multiply by scalar
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    /// Linear interpolation
    func interpolated(to other: CGPoint, factor: CGFloat) -> CGPoint {
        CGPoint(
            x: x + (other.x - x) * factor,
            y: y + (other.y - y) * factor
        )
    }
}
