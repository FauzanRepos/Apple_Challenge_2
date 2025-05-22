//
//  GameViewController.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 19/08/2016.
//  Copyright © 2016 Paul Hudson. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let view = self.view as! SKView? {
            // Create scene with a more appropriate size
            // Using 16:9 aspect ratio which is common for mobile games
            let sceneWidth = view.bounds.width
            let sceneHeight = sceneWidth * (16/9) // Maintain 16:9 aspect ratio
            
            let scene = GameScene(size: CGSize(width: sceneWidth, height: sceneHeight))
            
            // Set the scale mode to fit the entire view
            scene.scaleMode = .aspectFill
            
            // Center the scene in the view
            view.presentScene(scene)
            
            view.ignoresSiblingOrder = true
            view.showsFPS = true
            view.showsNodeCount = true
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // force landscape on phones, but allow everything on iPad
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.landscapeLeft, .landscapeRight]
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
