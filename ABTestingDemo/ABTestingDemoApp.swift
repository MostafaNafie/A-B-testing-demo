//
//  ABTestingDemoApp.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import SwiftUI
import FirebaseCore

@main
struct ABTestingDemoApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            HomeScreen()
        }
    }
}
