//
//  CollisionHelper.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import Foundation
import SpriteKit
import CoreGraphics

class CollisionHelper {
    
    // MARK: - Collision Detection
    static func checkCollision(between nodeA: SKNode, and nodeB: SKNode) -> Bool {
        return nodeA.frame.intersects(nodeB.frame)
    }
    
    static func checkCircleCollision(centerA: CGPoint, radiusA: CGFloat, centerB: CGPoint, radiusB: CGFloat) -> Bool {
        let distance = centerA.distance(to: centerB)
        return distance <= (radiusA + radiusB)
    }
    
    static func checkRectangleCollision(rectA: CGRect, rectB: CGRect) -> Bool {
        return rectA.intersects(rectB)
    }
    
    static func checkPointInCircle(point: CGPoint, center: CGPoint, radius: CGFloat) -> Bool {
        return point.distance(to: center) <= radius
    }
    
    static func checkPointInRectangle(point: CGPoint, rect: CGRect) -> Bool {
        return rect.contains(point)
    }
    
    // MARK: - Advanced Collision Detection
    static func checkCollisionWithPrediction(
        objectA: MovingObject,
        objectB: MovingObject,
        deltaTime: TimeInterval
    ) -> CollisionPrediction? {
        
        // Predict future positions
        let futurePositionA = objectA.position + objectA.velocity * CGFloat(deltaTime)
        let futurePositionB = objectB.position + objectB.velocity * CGFloat(deltaTime)
        
        // Check if collision will occur
        let willCollide = checkCircleCollision(
            centerA: futurePositionA,
            radiusA: objectA.radius,
            centerB: futurePositionB,
            radiusB: objectB.radius
        )
        
        if willCollide {
            let timeToCollision = calculateTimeToCollision(objectA: objectA, objectB: objectB)
            let collisionPoint = calculateCollisionPoint(objectA: objectA, objectB: objectB, time: timeToCollision)
            
            return CollisionPrediction(
                willCollide: true,
                timeToCollision: timeToCollision,
                collisionPoint: collisionPoint,
                relativeVelocity: objectA.velocity - objectB.velocity
            )
        }
        
        return nil
    }
    
    private static func calculateTimeToCollision(objectA: MovingObject, objectB: MovingObject) -> TimeInterval {
        let relativePosition = objectA.position - objectB.position
        let relativeVelocity = objectA.velocity - objectB.velocity
        
        // Using quadratic equation to solve for collision time
        let a = relativeVelocity.dx * relativeVelocity.dx + relativeVelocity.dy * relativeVelocity.dy
        let b = 2 * (relativePosition.x * relativeVelocity.dx + relativePosition.y * relativeVelocity.dy)
        let c = relativePosition.x * relativePosition.x + relativePosition.y * relativePosition.y -
                pow(objectA.radius + objectB.radius, 2)
        
        let discriminant = b * b - 4 * a * c
        
        if discriminant < 0 || a == 0 {
            return TimeInterval.greatestFiniteMagnitude
        }
        
        let t1 = (-b - sqrt(discriminant)) / (2 * a)
        let t2 = (-b + sqrt(discriminant)) / (2 * a)
        
        let validTimes = [t1, t2].filter { $0 >= 0 }
        return TimeInterval(validTimes.min() ?? TimeInterval.greatestFiniteMagnitude)
    }
    
    private static func calculateCollisionPoint(objectA: MovingObject, objectB: MovingObject, time: TimeInterval) -> CGPoint {
        let futureA = objectA.position + objectA.velocity * CGFloat(time)
        let futureB = objectB.position + objectB.velocity * CGFloat(time)
        
        // Collision point is between the two objects at collision time
        let direction = (futureB - futureA).normalized()
        return futureA + direction * objectA.radius
    }
    
    // MARK: - Collision Response
    static func handleElasticCollision(objectA: inout MovingObject, objectB: inout MovingObject, restitution: CGFloat = 1.0) {
        let relativePosition = objectA.position - objectB.position
        let distance = relativePosition.magnitude()
        
        guard distance > 0 else { return }
        
        let normal = relativePosition / distance
        let relativeVelocity = objectA.velocity - objectB.velocity
        let velocityAlongNormal = relativeVelocity.dot(normal)
        
        // Objects are separating
        if velocityAlongNormal > 0 { return }
        
        // Calculate collision impulse
        let impulse = -(1 + restitution) * velocityAlongNormal / (objectA.inverseMass + objectB.inverseMass)
        let impulseVector = normal * impulse
        
        // Apply impulse to velocities
        objectA.velocity += impulseVector * objectA.inverseMass
        objectB.velocity -= impulseVector * objectB.inverseMass
        
        // Separate objects to prevent overlap
        separateObjects(&objectA, &objectB)
    }
    
    static func handleInelasticCollision(objectA: inout MovingObject, objectB: inout MovingObject) {
        // Calculate combined momentum
        let totalMass = objectA.mass + objectB.mass
        let newVelocity = (objectA.velocity * objectA.mass + objectB.velocity * objectB.mass) / totalMass
        
        objectA.velocity = newVelocity
        objectB.velocity = newVelocity
        
        separateObjects(&objectA, &objectB)
    }
    
    private static func separateObjects(_ objectA: inout MovingObject, _ objectB: inout MovingObject) {
        let relativePosition = objectA.position - objectB.position
        let distance = relativePosition.magnitude()
        let minDistance = objectA.radius + objectB.radius
        
        if distance < minDistance && distance > 0 {
            let separation = (minDistance - distance) / 2
            let separationVector = relativePosition.normalized() * separation
            
            objectA.position += separationVector
            objectB.position -= separationVector
        }
    }
    
    // MARK: - Wall Collision
    static func handleWallCollision(object: inout MovingObject, wallBounds: CGRect, damping: CGFloat = 0.8) {
        let objectBounds = CGRect(
            x: object.position.x - object.radius,
            y: object.position.y - object.radius,
            width: object.radius * 2,
            height: object.radius * 2
        )
        
        // Check each wall
        if objectBounds.minX < wallBounds.minX {
            object.position.x = wallBounds.minX + object.radius
            object.velocity.dx = -object.velocity.dx * damping
        }
        
        if objectBounds.maxX > wallBounds.maxX {
            object.position.x = wallBounds.maxX - object.radius
            object.velocity.dx = -object.velocity.dx * damping
        }
        
        if objectBounds.minY < wallBounds.minY {
            object.position.y = wallBounds.minY + object.radius
            object.velocity.dy = -object.velocity.dy * damping
        }
        
        if objectBounds.maxY > wallBounds.maxY {
            object.position.y = wallBounds.maxY - object.radius
            object.velocity.dy = -object.velocity.dy * damping
        }
    }
    
    // MARK: - Screen Edge Detection
    static func checkScreenEdgeCollision(position: CGPoint, screenBounds: CGRect, margin: CGFloat = 0) -> EdgeCollisionInfo? {
        let adjustedBounds = screenBounds.insetBy(dx: margin, dy: margin)
        
        if position.x <= adjustedBounds.minX {
            return EdgeCollisionInfo(edge: .left, penetration: adjustedBounds.minX - position.x)
        }
        
        if position.x >= adjustedBounds.maxX {
            return EdgeCollisionInfo(edge: .right, penetration: position.x - adjustedBounds.maxX)
        }
        
        if position.y <= adjustedBounds.minY {
            return EdgeCollisionInfo(edge: .bottom, penetration: adjustedBounds.minY - position.y)
        }
        
        if position.y >= adjustedBounds.maxY {
            return EdgeCollisionInfo(edge: .top, penetration: position.y - adjustedBounds.maxY)
        }
        
        return nil
    }
    
    // MARK: - Grid-Based Collision
    static func getGridPosition(worldPosition: CGPoint, cellSize: CGFloat) -> GridPosition {
        return GridPosition(
            row: Int(floor(worldPosition.y / cellSize)),
            column: Int(floor(worldPosition.x / cellSize))
        )
    }
    
    static func getWorldPosition(gridPosition: GridPosition, cellSize: CGFloat) -> CGPoint {
        return CGPoint(
            x: CGFloat(gridPosition.column) * cellSize + cellSize / 2,
            y: CGFloat(gridPosition.row) * cellSize + cellSize / 2
        )
    }
    
    static func isValidGridPosition(_ position: GridPosition, gridSize: GridSize) -> Bool {
        return position.row >= 0 && position.row < gridSize.rows &&
               position.column >= 0 && position.column < gridSize.columns
    }
    
    // MARK: - SpaceMaze Specific Collisions
    static func handlePlayerWallCollision(player: SKSpriteNode, wall: SKSpriteNode) -> Bool {
        guard let playerPhysics = player.physicsBody,
              let wallPhysics = wall.physicsBody else { return false }
        
        let playerRadius = playerPhysics.area.squareRoot() / 2
        let wallFrame = wall.frame
        
        // Check if player is colliding with wall
        let collision = checkCollision(between: player, and: wall)
        
        if collision {
            // Calculate separation vector
            let separation = calculateSeparationVector(
                playerPosition: player.position,
                playerRadius: playerRadius,
                wallFrame: wallFrame
            )
            
            // Apply separation
            player.position += separation
            
            // Reduce velocity
            if let velocity = playerPhysics.velocity {
                let dampedVelocity = velocity * 0.5
                playerPhysics.velocity = dampedVelocity
            }
            
            return true
        }
        
        return false
    }
    
    private static func calculateSeparationVector(playerPosition: CGPoint, playerRadius: CGFloat, wallFrame: CGRect) -> CGVector {
        let closestPoint = CGPoint(
            x: max(wallFrame.minX, min(wallFrame.maxX, playerPosition.x)),
            y: max(wallFrame.minY, min(wallFrame.maxY, playerPosition.y))
        )
        
        let direction = playerPosition - closestPoint
        let distance = direction.magnitude()
        
        if distance < playerRadius && distance > 0 {
            let separationDistance = playerRadius - distance
            return direction.normalized() * separationDistance
        }
        
        return CGVector.zero
    }
    
    static func handlePlayerCheckpointCollision(player: SKSpriteNode, checkpoint: SKSpriteNode) -> Bool {
        let playerRadius = player.frame.width / 2
        let checkpointRadius = checkpoint.frame.width / 2
        
        return checkCircleCollision(
            centerA: player.position,
            radiusA: playerRadius,
            centerB: checkpoint.position,
            radiusB: checkpointRadius
        )
    }
    
    static func handlePlayerVortexCollision(player: SKSpriteNode, vortex: SKSpriteNode) -> VortexCollisionInfo? {
        let playerRadius = player.frame.width / 2
        let vortexRadius = vortex.frame.width / 2
        let distance = player.position.distance(to: vortex.position)
        
        if distance <= vortexRadius {
            // Player is fully inside vortex
            return VortexCollisionInfo(
                isFullyInside: true,
                pullStrength: 1.0,
                pullDirection: vortex.position - player.position
            )
        } else if distance <= vortexRadius + playerRadius {
            // Player is partially inside vortex
            let pullStrength = 1.0 - (distance - vortexRadius) / playerRadius
            return VortexCollisionInfo(
                isFullyInside: false,
                pullStrength: pullStrength,
                pullDirection: vortex.position - player.position
            )
        }
        
        return nil
    }
    
    // MARK: - Utility Functions
    static func getNearestPoint(on rect: CGRect, to point: CGPoint) -> CGPoint {
        return CGPoint(
            x: max(rect.minX, min(rect.maxX, point.x)),
            y: max(rect.minY, min(rect.maxY, point.y))
        )
    }
    
    static func getDistance(from pointA: CGPoint, to pointB: CGPoint) -> CGFloat {
        return pointA.distance(to: pointB)
    }
    
    static func getDirection(from pointA: CGPoint, to pointB: CGPoint) -> CGVector {
        return (pointB - pointA).normalized()
    }
    
    static func isPointInsideCircle(point: CGPoint, center: CGPoint, radius: CGFloat) -> Bool {
        return point.distance(to: center) <= radius
    }
    
    static func isPointInsideRectangle(point: CGPoint, rect: CGRect) -> Bool {
        return rect.contains(point)
    }
    
    // MARK: - Debug Helpers
    static func debugDrawCollisionBounds(for node: SKNode, in scene: SKScene, color: UIColor = .red) {
        let frame = node.frame
        let debugShape = SKShapeNode(rect: frame)
        debugShape.strokeColor = color
        debugShape.fillColor = .clear
        debugShape.lineWidth = 2
        debugShape.position = node.position
        debugShape.zPosition = 1000
        
        scene.addChild(debugShape)
        
        // Auto-remove after 2 seconds
        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        debugShape.run(SKAction.sequence([wait, remove]))
    }
    
    static func debugDrawCircle(center: CGPoint, radius: CGFloat, in scene: SKScene, color: UIColor = .blue) {
        let debugCircle = SKShapeNode(circleOfRadius: radius)
        debugCircle.strokeColor = color
        debugCircle.fillColor = .clear
        debugCircle.lineWidth = 2
        debugCircle.position = center
        debugCircle.zPosition = 1000
        
        scene.addChild(debugCircle)
        
        // Auto-remove after 2 seconds
        let wait = SKAction.wait(forDuration: 2.0)
        let remove = SKAction.removeFromParent()
        debugCircle.run(SKAction.sequence([wait, remove]))
    }
}

// MARK: - Supporting Data Types
struct MovingObject {
    var position: CGPoint
    var velocity: CGVector
    var radius: CGFloat
    var mass: CGFloat
    
    var inverseMass: CGFloat {
        return mass > 0 ? 1.0 / mass : 0
    }
    
    init(position: CGPoint, velocity: CGVector = .zero, radius: CGFloat, mass: CGFloat = 1.0) {
        self.position = position
        self.velocity = velocity
        self.radius = radius
        self.mass = mass
    }
}

struct CollisionPrediction {
    let willCollide: Bool
    let timeToCollision: TimeInterval
    let collisionPoint: CGPoint
    let relativeVelocity: CGVector
}

struct EdgeCollisionInfo {
    let edge: EdgeDirection
    let penetration: CGFloat
}

struct GridPosition {
    let row: Int
    let column: Int
}

struct GridSize {
    let rows: Int
    let columns: Int
}

struct VortexCollisionInfo {
    let isFullyInside: Bool
    let pullStrength: CGFloat
    let pullDirection: CGVector
}

// MARK: - CGVector Extensions for Collision
extension CGVector {
    func magnitude() -> CGFloat {
        return sqrt(dx * dx + dy * dy)
    }
    
    func normalized() -> CGVector {
        let mag = magnitude()
        return mag > 0 ? CGVector(dx: dx / mag, dy: dy / mag) : .zero
    }
    
    func dot(_ other: CGVector) -> CGFloat {
        return dx * other.dx + dy * other.dy
    }
    
    static func + (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx + right.dx, dy: left.dy + right.dy)
    }
    
    static func - (left: CGVector, right: CGVector) -> CGVector {
        return CGVector(dx: left.dx - right.dx, dy: left.dy - right.dy)
    }
    
    static func * (vector: CGVector, scalar: CGFloat) -> CGVector {
        return CGVector(dx: vector.dx * scalar, dy: vector.dy * scalar)
    }
    
    static func / (vector: CGVector, scalar: CGFloat) -> CGVector {
        return CGVector(dx: vector.dx / scalar, dy: vector.dy / scalar)
    }
}
