//
//  ABTestModels.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import Foundation

// MARK: - A/B Test Keys
/// Enum defining all A/B test parameter keys
enum ABTestKey: String, CaseIterable {
    case buttonColor = "button_color"
    case buttonText = "button_text"
    case welcomeMessage = "welcome_message"
    case featureEnabled = "feature_enabled"
    case maxItems = "max_items"
}

// MARK: - A/B Test Configuration
/// Configuration for A/B tests with predefined test cases
enum ABTestConfiguration: CaseIterable {
    // String tests
    static let buttonColor = StringABTest(.buttonColor, defaultValue: "blue")
    static let buttonText = StringABTest(.buttonText, defaultValue: "Get Started")
    static let welcomeMessage = StringABTest(.welcomeMessage, defaultValue: "Welcome to our app!")
    
    // Boolean tests
    static let featureEnabled = BoolABTest(.featureEnabled, defaultValue: false)
    
    // Integer tests
    static let maxItems = IntABTest(.maxItems, defaultValue: 10)
}
