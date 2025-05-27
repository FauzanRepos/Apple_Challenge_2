//
//  CGPoint+Extensions.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import CoreGraphics

// MARK: - CGPoint Extensions
extension CGPoint {
    
    // MARK: - Distance Calculations
    func distance(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func distanceSquared(to point: CGPoint) -> CGFloat {
        let dx = point.x - self.x
        let dy = point.y - self.y
        return dx * dx + dy * dy
    }
    
    func manhattanDistance(to point: CGPoint) -> CGFloat {
        return abs(point.x - self.x) + abs(point.y - self.y)
    }
    
    // MARK: - Vector Operations
    func vector(to point: CGPoint) -> CGVector {
        return CGVector(dx: point.x - self.x, dy: point.y - self.y)
    }
    
    func angle(to point: CGPoint) -> CGFloat {
        let vector = self.vector(to: point)
        return atan2(vector.dy, vector.dx)
    }
    
    func bearing(to point: CGPoint) -> CGFloat {
        let angle = self.angle(to: point)
        let bearing = angle * 180 / .pi
        return bearing < 0 ? bearing + 360 : bearing
    }
    
    // MARK: - Point Manipulation
    func offset(by vector: CGVector) -> CGPoint {
        return CGPoint(x: self.x + vector.dx, y: self.y + vector.dy)
    }
    
    func offset(dx: CGFloat, dy: CGFloat) -> CGPoint {
        return CGPoint(x: self.x + dx, y: self.y + dy)
    }
    
    func scaled(by factor: CGFloat) -> CGPoint {
        return CGPoint(x: self.x * factor, y: self.y * factor)
    }
    
    func rotated(around center: CGPoint, by angle: CGFloat) -> CGPoint {
        let cos = cosf(Float(angle))
        let sin = sinf(Float(angle))
        
        let dx = self.x - center.x
        let dy = self.y - center.y
        
        let rotatedX = center.x + CGFloat(cos * Float(dx) - sin * Float(dy))
        let rotatedY = center.y + CGFloat(sin * Float(dx) + cos * Float(dy))
        
        return CGPoint(x: rotatedX, y: rotatedY)
    }
    
    // MARK: - Interpolation
    func interpolated(to point: CGPoint, factor: CGFloat) -> CGPoint {
        let clampedFactor = max(0, min(1, factor))
        return CGPoint(
            x: self.x + (point.x - self.x) * clampedFactor,
            y: self.y + (point.y - self.y) * clampedFactor
        )
    }
    
    func midpoint(to point: CGPoint) -> CGPoint {
        return interpolated(to: point, factor: 0.5)
    }
    
    // MARK: - Clamping and Bounds
    func clamped(to rect: CGRect) -> CGPoint {
        return CGPoint(
            x: max(rect.minX, min(rect.maxX, self.x)),
            y: max(rect.minY, min(rect.maxY, self.y))
        )
    }
    
    func clamped(minX: CGFloat, maxX: CGFloat, minY: CGFloat, maxY: CGFloat) -> CGPoint {
        return CGPoint(
            x: max(minX, min(maxX, self.x)),
            y: max(minY, min(maxY, self.y))
        )
    }
    
    func isInside(_ rect: CGRect) -> Bool {
        return rect.contains(self)
    }
    
    func isInside(circle center: CGPoint, radius: CGFloat) -> Bool {
        return distance(to: center) <= radius
    }
    
    // MARK: - Grid Operations
    func rounded(to gridSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: round(self.x / gridSize) * gridSize,
            y: round(self.y / gridSize) * gridSize
        )
    }
    
    func snapped(to gridSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: floor(self.x / gridSize) * gridSize,
            y: floor(self.y / gridSize) * gridSize
        )
    }
    
    func gridCoordinates(cellSize: CGFloat) -> (row: Int, column: Int) {
        return (
            row: Int(floor(self.y / cellSize)),
            column: Int(floor(self.x / cellSize))
        )
    }
    
    // MARK: - Validation
    var isValid: Bool {
        return !self.x.isNaN && !self.y.isNaN &&
               !self.x.isInfinite && !self.y.isInfinite
    }
    
    var isZero: Bool {
        return self.x == 0 && self.y == 0
    }
    
    // MARK: - Convenience Initializers
    init(angle: CGFloat, radius: CGFloat) {
        self.init(
            x: cos(angle) * radius,
            y: sin(angle) * radius
        )
    }
    
    init(gridRow: Int, gridColumn: Int, cellSize: CGFloat) {
        self.init(
            x: CGFloat(gridColumn) * cellSize + cellSize / 2,
            y: CGFloat(gridRow) * cellSize + cellSize / 2
        )
    }
    
    // MARK: - String Representation
    var shortDescription: String {
        return String(format: "(%.1f, %.1f)", self.x, self.y)
    }
    
    var preciseDescription: String {
        return String(format: "(%.3f, %.3f)", self.x, self.y)
    }
}

// MARK: - CGPoint Arithmetic Operators
extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func - (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x - right.x, y: left.y - right.y)
    }
    
    static func * (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x * scalar, y: point.y * scalar)
    }
    
    static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }
    
    static func += (left: inout CGPoint, right: CGPoint) {
        left = left + right
    }
    
    static func -= (left: inout CGPoint, right: CGPoint) {
        left = left - right
    }
    
    static func *= (point: inout CGPoint, scalar: CGFloat) {
        point = point * scalar
    }
    
    static func /= (point: inout CGPoint, scalar: CGFloat) {
        point = point / scalar
    }
}

// MARK: - CGPoint Array Extensions
extension Array where Element == CGPoint {
    var centroid: CGPoint {
        guard !isEmpty else { return .zero }
        
        let sum = reduce(CGPoint.zero) { $0 + $1 }
        return sum / CGFloat(count)
    }
    
    var boundingRect: CGRect {
        guard !isEmpty else { return .zero }
        
        let minX = map { $0.x }.min()!
        let maxX = map { $0.x }.max()!
        let minY = map { $0.y }.min()!
        let maxY = map { $0.y }.max()!
        
        return CGRect(
            x: minX,
            y: minY,
            width: maxX - minX,
            height: maxY - minY
        )
    }
    
    func totalDistance() -> CGFloat {
        guard count > 1 else { return 0 }
        
        var total: CGFloat = 0
        for i in 1..<count {
            total += self[i-1].distance(to: self[i])
        }
        return total
    }
    
    func smoothed(factor: CGFloat = 0.5) -> [CGPoint] {
        guard count > 2 else { return self }
        
        var smoothed = [self[0]]
        
        for i in 1..<count-1 {
            let prev = self[i-1]
            let current = self[i]
            let next = self[i+1]
            
            let smoothX = current.x * (1 - factor) + (prev.x + next.x) * factor / 2
            let smoothY = current.y * (1 - factor) + (prev.y + next.y) * factor / 2
            
            smoothed.append(CGPoint(x: smoothX, y: smoothY))
        }
        
        smoothed.append(self[count-1])
        return smoothed
    }
}

// MARK: - Game-Specific Extensions
extension CGPoint {
    // Convert world coordinates to screen coordinates
    func toScreen(worldNode: CGPoint, screenSize: CGSize) -> CGPoint {
        return CGPoint(
            x: self.x - worldNode.x + screenSize.width / 2,
            y: self.y - worldNode.y + screenSize.height / 2
        )
    }
    
    // Convert screen coordinates to world coordinates
    func toWorld(worldNode: CGPoint, screenSize: CGSize) -> CGPoint {
        return CGPoint(
            x: self.x + worldNode.x - screenSize.width / 2,
            y: self.y + worldNode.y - screenSize.height / 2
        )
    }
    
    // Check if point is near screen edge
    func isNearScreenEdge(screenSize: CGSize, margin: CGFloat) -> (Bool, EdgeDirection?) {
        if self.x < margin {
            return (true, .left)
        } else if self.x > screenSize.width - margin {
            return (true, .right)
        } else if self.y > screenSize.height - margin {
            return (true, .top)
        } else if self.y < margin {
            return (true, .bottom)
        }
        return (false, nil)
    }
    
    // Get direction to move map based on player position
    func getMapMoveDirection(screenSize: CGSize, margin: CGFloat) -> CGVector {
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        
        if self.x < margin {
            dx = Constants.mapScrollSpeed
        } else if self.x > screenSize.width - margin {
            dx = -Constants.mapScrollSpeed
        }
        
        if self.y > screenSize.height - margin {
            dy = -Constants.mapScrollSpeed
        } else if self.y < margin {
            dy = Constants.mapScrollSpeed
        }
        
        return CGVector(dx: dx, dy: dy)
    }
}

enum EdgeDirection: String, CaseIterable {
    case left, right, top, bottom
    
    var opposite: EdgeDirection {
        switch self {
        case .left: return .right
        case .right: return .left
        case .top: return .bottom
        case .bottom: return .top
        }
    }
}
