//
//  AppDelegate.swift
//  Project26
//
//  Created by SpaceMaze-ADA_Team_8 on 20/05/2025.
//  Copyright © 2025 Apple Team. All rights reserved.
//

import UIKit
import SwiftUI

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set up the root window with a SwiftUI view
        let window = UIWindow(frame: UIScreen.main.bounds)
        let rootView = GameViewWrapper()
        window.rootViewController = UIHostingController(rootView: rootView)
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
    
    // For iOS 17 and up, scene lifecycle is handled automatically if using App protocol,
    // but this delegate is still valid for direct UIWindow bootstrapping.
}
