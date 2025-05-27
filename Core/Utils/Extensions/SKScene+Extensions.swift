//
//  SKScene+Extensions.swift
//  Space Maze
//
//  Created by Apple Dev on 27/05/25.
//  Copyright © 2025 ADA Team. All rights reserved.
//

import SpriteKit
import CoreGraphics

// MARK: - SKScene Extensions
extension SKScene {
    
    // MARK: - Node Management
    func addChildWithFadeIn(_ node: SKNode, duration: TimeInterval = Constants.animationDuration) {
        node.alpha = 0
        addChild(node)
        
        let fadeIn = SKAction.fadeIn(withDuration: duration)
        node.run(fadeIn)
    }
    
    func removeChildWithFadeOut(_ node: SKNode, duration: TimeInterval = Constants.animationDuration) {
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        
        node.run(sequence)
    }
    
    func removeAllChildrenWithFadeOut(duration: TimeInterval = Constants.animationDuration) {
        for child in children {
            removeChildWithFadeOut(child, duration: duration)
        }
    }
    
    // MARK: - Safe Node Finding
    func safeChildNode(withName name: String) -> SKNode? {
        return childNode(withName: name)
    }
    
    func safeChildNode<T: SKNode>(withName name: String, ofType type: T.Type) -> T? {
        return childNode(withName: name) as? T
    }
    
    func findAllNodes(withName name: String) -> [SKNode] {
        var nodes: [SKNode] = []
        enumerateChildNodes(withName: name) { node, _ in
            nodes.append(node)
        }
        return nodes
    }
    
    func findAllNodes<T: SKNode>(ofType type: T.Type) -> [T] {
        var nodes: [T] = []
        enumerateChildNodes(withName: "*") { node, _ in
            if let typedNode = node as? T {
                nodes.append(typedNode)
            }
        }
        return nodes
    }
    
    // MARK: - Screen Conversion
    func screenCenter() -> CGPoint {
        return CGPoint(x: frame.midX, y: frame.midY)
    }
    
    func screenBounds() -> CGRect {
        return frame
    }
    
    func isPointOnScreen(_ point: CGPoint, margin: CGFloat = 0) -> Bool {
        let expandedFrame = frame.insetBy(dx: -margin, dy: -margin)
        return expandedFrame.contains(point)
    }
    
    func clampToScreen(_ point: CGPoint, margin: CGFloat = 0) -> CGPoint {
        let bounds = frame.insetBy(dx: margin, dy: margin)
        return point.clamped(to: bounds)
    }
    
    // MARK: - Touch Handling Helpers
    func touchLocation(from touches: Set<UITouch>) -> CGPoint? {
        guard let touch = touches.first else { return nil }
        return touch.location(in: self)
    }
    
    func previousTouchLocation(from touches: Set<UITouch>) -> CGPoint? {
        guard let touch = touches.first else { return nil }
        return touch.previousLocation(in: self)
    }
    
    func touchDelta(from touches: Set<UITouch>) -> CGVector? {
        guard let current = touchLocation(from: touches),
              let previous = previousTouchLocation(from: touches) else { return nil }
        return CGVector(dx: current.x - previous.x, dy: current.y - previous.y)
    }
    
    // MARK: - Animation Helpers
    func shakeCamera(intensity: CGFloat = 10, duration: TimeInterval = 0.5) {
        guard let camera = camera else { return }
        
        let originalPosition = camera.position
        
        let shakeAction = SKAction.sequence([
            SKAction.moveBy(x: intensity, y: 0, duration: 0.05),
            SKAction.moveBy(x: -intensity * 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: intensity * 2, y: 0, duration: 0.05),
            SKAction.moveBy(x: -intensity, y: 0, duration: 0.05)
        ])
        
        let repeatAction = SKAction.repeat(shakeAction, count: Int(duration / 0.2))
        let resetPosition = SKAction.move(to: originalPosition, duration: 0.1)
        let sequence = SKAction.sequence([repeatAction, resetPosition])
        
        camera.run(sequence)
    }
    
    func flashScreen(color: UIColor = .white, intensity: CGFloat = 0.5, duration: TimeInterval = 0.1) {
        let flashNode = SKSpriteNode(color: color, size: frame.size)
        flashNode.position = screenCenter()
        flashNode.alpha = intensity
        flashNode.zPosition = 1000
        
        addChild(flashNode)
        
        let fadeOut = SKAction.fadeOut(withDuration: duration)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([fadeOut, remove])
        
        flashNode.run(sequence)
    }
    
    // MARK: - Particle Effects
    func createExplosion(at position: CGPoint, particleCount: Int = 20) {
        for _ in 0..<particleCount {
            let particle = SKSpriteNode(color: .orange, size: CGSize(width: 4, height: 4))
            particle.position = position
            addChild(particle)
            
            let randomAngle = Float.random(in: 0...(2 * Float.pi))
            let randomDistance = CGFloat.random(in: 20...60)
            
            let moveAction = SKAction.move(
                by: CGVector(
                    dx: cos(randomAngle) * Float(randomDistance),
                    dy: sin(randomAngle) * Float(randomDistance)
                ),
                duration: 0.5
            )
            
            let fadeAction = SKAction.fadeOut(withDuration: 0.5)
            let scaleAction = SKAction.scale(to: 0, duration: 0.5)
            let removeAction = SKAction.removeFromParent()
            
            let groupAction = SKAction.group([moveAction, fadeAction, scaleAction])
            let sequence = SKAction.sequence([groupAction, removeAction])
            
            particle.run(sequence)
        }
    }
    
    func createCheckpointEffect(at position: CGPoint) {
        let effectNode = SKSpriteNode(color: .green, size: CGSize(width: 60, height: 60))
        effectNode.position = position
        effectNode.alpha = 0.7
        effectNode.zPosition = 50
        addChild(effectNode)
        
        let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let group = SKAction.group([scaleUp, fadeOut])
        let sequence = SKAction.sequence([group, remove])
        
        effectNode.run(sequence)
    }
    
    // MARK: - Label Helpers
    func createLabel(text: String, fontSize: CGFloat = 24, fontName: String = "Helvetica-Bold") -> SKLabelNode {
        let label = SKLabelNode(fontNamed: fontName)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = .white
        label.horizontalAlignmentMode = .center
        label.verticalAlignmentMode = .center
        return label
    }
    
    func showToast(message: String, duration: TimeInterval = Constants.toastDisplayDuration) {
        let toast = createLabel(text: message, fontSize: 18)
        toast.position = CGPoint(x: frame.midX, y: frame.maxY - 100)
        toast.zPosition = 1000
        
        // Background for toast
        let background = SKSpriteNode(color: .black, size: CGSize(width: toast.frame.width + 20, height: 40))
        background.alpha = 0.8
        background.position = toast.position
        background.zPosition = 999
        
        addChild(background)
        addChild(toast)
        
        let fadeIn = SKAction.fadeIn(withDuration: 0.2)
        let wait = SKAction.wait(forDuration: duration)
        let fadeOut = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        
        let sequence = SKAction.sequence([fadeIn, wait, fadeOut, remove])
        
        toast.run(sequence)
        background.run(sequence)
    }
    
    // MARK: - Pause/Resume Helpers
    func pauseAllActions() {
        isPaused = true
        enumerateChildNodes(withName: "*") { node, _ in
            node.isPaused = true
        }
    }
    
    func resumeAllActions() {
        isPaused = false
        enumerateChildNodes(withName: "*") { node, _ in
            node.isPaused = false
        }
    }
    
    func pauseNode(_ node: SKNode) {
        node.isPaused = true
    }
    
    func resumeNode(_ node: SKNode) {
        node.isPaused = false
    }
    
    // MARK: - Background Management
    func setBackground(imageName: String, size: CGSize? = nil) {
        // Remove existing background
        childNode(withName: "background")?.removeFromParent()
        
        let background = SKSpriteNode(imageNamed: imageName)
        background.name = "background"
        background.size = size ?? frame.size
        background.position = screenCenter()
        background.zPosition = -100
        
        addChild(background)
    }
    
    func setBackgroundColor(_ color: UIColor) {
        backgroundColor = color
    }
    
    // MARK: - Debug Helpers
    func drawDebugFrame(for node: SKNode, color: UIColor = .red, lineWidth: CGFloat = 2) {
        let frame = node.frame
        let debugFrame = SKShapeNode(rect: frame)
        debugFrame.strokeColor = color
        debugFrame.lineWidth = lineWidth
        debugFrame.fillColor = .clear
        debugFrame.position = node.position
        debugFrame.zPosition = 1000
        
        addChild(debugFrame)
        
        // Auto-remove after 3 seconds
        let wait = SKAction.wait(forDuration: 3.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait, remove])
        debugFrame.run(sequence)
    }
    
    func drawDebugPath(points: [CGPoint], color: UIColor = .yellow, lineWidth: CGFloat = 3) {
        guard points.count > 1 else { return }
        
        let path = CGMutablePath()
        path.move(to: points[0])
        for i in 1..<points.count {
            path.addLine(to: points[i])
        }
        
        let debugPath = SKShapeNode(path: path)
        debugPath.strokeColor = color
        debugPath.lineWidth = lineWidth
        debugPath.zPosition = 1000
        
        addChild(debugPath)
        
        // Auto-remove after 5 seconds
        let wait = SKAction.wait(forDuration: 5.0)
        let remove = SKAction.removeFromParent()
        let sequence = SKAction.sequence([wait, remove])
        debugPath.run(sequence)
    }
    
    // MARK: - Node Counting and Performance
    func getNodeCount() -> Int {
        var count = 0
        enumerateChildNodes(withName: "*") { _, _ in
            count += 1
        }
        return count
    }
    
    func getNodeCountByType() -> [String: Int] {
        var counts: [String: Int] = [:]
        
        enumerateChildNodes(withName: "*") { node, _ in
            let typeName = String(describing: type(of: node))
            counts[typeName] = (counts[typeName] ?? 0) + 1
        }
        
        return counts
    }
    
    func printPerformanceInfo() {
        let nodeCount = getNodeCount()
        let typeCounts = getNodeCountByType()
        
        print("🎮 Scene Performance Info:")
        print("  Total Nodes: \(nodeCount)")
        print("  Node Types:")
        for (type, count) in typeCounts.sorted(by: { $0.value > $1.value }) {
            print("    \(type): \(count)")
        }
    }
    
    // MARK: - Collision Detection Helpers
    func getNodesAt(point: CGPoint) -> [SKNode] {
        return nodes(at: point)
    }
    
    func getFirstNode<T: SKNode>(at point: CGPoint, ofType type: T.Type) -> T? {
        return nodes(at: point).first { $0 is T } as? T
    }
    
    func isPointInsideNode(_ point: CGPoint, node: SKNode) -> Bool {
        let nodePoint = convert(point, to: node)
        return node.contains(nodePoint)
    }
    
    // MARK: - Texture Management
    func preloadTextures(_ textureNames: [String]) {
        let textures = textureNames.map { SKTexture(imageNamed: $0) }
        SKTexture.preload(textures) {
            print("✅ Preloaded \(textures.count) textures")
        }
    }
    
    // MARK: - Camera Management
    func setupCamera(at position: CGPoint = CGPoint.zero) {
        let cameraNode = SKCameraNode()
        cameraNode.position = position
        addChild(cameraNode)
        camera = cameraNode
    }
    
    func moveCamera(to position: CGPoint, duration: TimeInterval = 0.5) {
        guard let camera = camera else { return }
        
        let moveAction = SKAction.move(to: position, duration: duration)
        camera.run(moveAction)
    }
    
    func followNode(_ node: SKNode, smoothing: CGFloat = 0.1) {
        guard let camera = camera else { return }
        
        let targetPosition = node.position
        let currentPosition = camera.position
        
        let smoothedPosition = currentPosition.interpolated(to: targetPosition, factor: smoothing)
        camera.position = smoothedPosition
    }
}

// MARK: - Game-Specific Extensions
extension SKScene {
    
    // MARK: - SpaceMaze Specific Helpers
    func createPlayer(at position: CGPoint, playerType: PlayerType) -> SKSpriteNode {
        let player = SKSpriteNode(imageNamed: Constants.AssetNames.playerSprite)
        player.position = position
        player.name = "player"
        
        // Set up physics
        player.physicsBody = SKPhysicsBody(circleOfRadius: player.size.width / 2)
        player.physicsBody?.allowsRotation = false
        player.physicsBody?.linearDamping = Constants.playerLinearDamping
        player.physicsBody?.categoryBitMask = CollisionTypes.player.rawValue
        
        // Add visual indicator for player type
        if playerType == .mapMover {
            let indicator = SKSpriteNode(color: .green, size: CGSize(width: 8, height: 8))
            indicator.position = CGPoint(x: 0, y: player.size.height / 2 + 8)
            player.addChild(indicator)
        }
        
        return player
    }
    
    func createWall(at position: CGPoint, size: CGSize) -> SKSpriteNode {
        let wall = SKSpriteNode(imageNamed: Constants.AssetNames.wallSprite)
        wall.position = position
        wall.size = size
        wall.name = "wall"
        
        wall.physicsBody = SKPhysicsBody(rectangleOf: size)
        wall.physicsBody?.isDynamic = false
        wall.physicsBody?.categoryBitMask = CollisionTypes.wall.rawValue
        
        return wall
    }
    
    func createCheckpoint(at position: CGPoint, id: String) -> SKSpriteNode {
        let checkpoint = SKSpriteNode(imageNamed: Constants.AssetNames.checkpointSprite)
        checkpoint.position = position
        checkpoint.name = "checkpoint_\(id)"
        
        checkpoint.physicsBody = SKPhysicsBody(circleOfRadius: checkpoint.size.width / 2)
        checkpoint.physicsBody?.isDynamic = false
        checkpoint.physicsBody?.categoryBitMask = CollisionTypes.checkpoint.rawValue
        checkpoint.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        checkpoint.physicsBody?.collisionBitMask = 0
        
        // Add pulsing animation
        let scaleUp = SKAction.scale(to: Constants.checkpointPulseScale, duration: Constants.checkpointPulseDuration)
        let scaleDown = SKAction.scale(to: 1.0, duration: Constants.checkpointPulseDuration)
        let pulse = SKAction.sequence([scaleUp, scaleDown])
        checkpoint.run(SKAction.repeatForever(pulse))
        
        return checkpoint
    }
    
    func createVortex(at position: CGPoint) -> SKSpriteNode {
        let vortex = SKSpriteNode(imageNamed: Constants.AssetNames.vortexSprite)
        vortex.position = position
        vortex.name = "vortex"
        
        vortex.physicsBody = SKPhysicsBody(circleOfRadius: vortex.size.width / 2)
        vortex.physicsBody?.isDynamic = false
        vortex.physicsBody?.categoryBitMask = CollisionTypes.vortex.rawValue
        vortex.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        vortex.physicsBody?.collisionBitMask = 0
        
        // Add rotation animation
        let rotate = SKAction.rotate(byAngle: .pi, duration: Constants.vortexRotationDuration)
        vortex.run(SKAction.repeatForever(rotate))
        
        return vortex
    }
    
    func createFinish(at position: CGPoint) -> SKSpriteNode {
        let finish = SKSpriteNode(imageNamed: Constants.AssetNames.finishSprite)
        finish.position = position
        finish.name = "finish"
        
        finish.physicsBody = SKPhysicsBody(circleOfRadius: finish.size.width / 2)
        finish.physicsBody?.isDynamic = false
        finish.physicsBody?.categoryBitMask = CollisionTypes.finish.rawValue
        finish.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        finish.physicsBody?.collisionBitMask = 0
        
        return finish
    }
    
    func createPowerUp(type: PowerUpType, at position: CGPoint) -> SKSpriteNode {
        let imageName = type == .oil ? Constants.AssetNames.oilPowerUp : Constants.AssetNames.grassPowerUp
        let powerUp = SKSpriteNode(imageNamed: imageName)
        powerUp.position = position
        powerUp.name = "powerup_\(type.rawValue)"
        
        powerUp.physicsBody = SKPhysicsBody(circleOfRadius: powerUp.size.width / 2)
        powerUp.physicsBody?.isDynamic = false
        powerUp.physicsBody?.categoryBitMask = CollisionTypes.powerUp.rawValue
        powerUp.physicsBody?.contactTestBitMask = CollisionTypes.player.rawValue
        powerUp.physicsBody?.collisionBitMask = 0
        
        // Add floating animation
        let floatUp = SKAction.moveBy(x: 0, y: 10, duration: 1.0)
        let floatDown = SKAction.moveBy(x: 0, y: -10, duration: 1.0)
        let float = SKAction.sequence([floatUp, floatDown])
        powerUp.run(SKAction.repeatForever(float))
        
        return powerUp
    }
}

// MARK: - Collision Types for SpaceMaze
enum CollisionTypes: UInt32 {
    case player = 1
    case wall = 2
    case checkpoint = 4
    case vortex = 8
    case finish = 16
    case powerUp = 32
}
