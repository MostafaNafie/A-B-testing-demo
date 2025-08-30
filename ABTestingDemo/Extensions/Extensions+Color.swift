//
//  Extensions.swift
//  ABTestingDemo
//
//  Created by Nafie on 30/08/2025.
//

import SwiftUI

extension Color {
    /// Convert string color names to SwiftUI Colors
    static func from(string: String) -> Color {
        switch string.lowercased() {
        case "red":
            return .red
        case "blue":
            return .blue
        case "green":
            return .green
        case "orange":
            return .orange
        case "purple":
            return .purple
        case "pink":
            return .pink
        case "yellow":
            return .yellow
        default:
            return .blue
        }
    }
}
