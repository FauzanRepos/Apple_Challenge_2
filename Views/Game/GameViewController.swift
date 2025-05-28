//
//  GameViewController.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {
    
    override func loadView() {
        self.view = SKView()
    }

//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        guard let skView = self.view as? SKView else { return }
//
//        let sceneWidth = skView.bounds.width
//        let sceneHeight = sceneWidth * (16/9)
//        let scene = GameScene(size: CGSize(width: sceneWidth, height: sceneHeight))
//        scene.scaleMode = .aspectFit
//
//        skView.presentScene(scene)
//        skView.ignoresSiblingOrder = true
//        skView.showsFPS = true
//        skView.showsNodeCount = true
//    }

    override func viewDidLoad() {
        super.viewDidLoad()

        DispatchQueue.main.async {
            guard let skView = self.view as? SKView else { return }

            let sceneWidth = skView.bounds.width
            let sceneHeight = sceneWidth * (16/9)
            let scene = GameScene(size: CGSize(width: sceneWidth, height: sceneHeight))
            scene.scaleMode = .aspectFit

            skView.presentScene(scene)
            skView.ignoresSiblingOrder = true
            skView.showsFPS = true
            skView.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // force portrait on phones
            return [.portrait]
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
