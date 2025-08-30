//
//  ABTestValue.swift
//  ABTestingDemo
//
//  Created by Nafie on 30/08/2025.
//

import Foundation

// MARK: - A/B Test Value Types
/// Protocol for A/B test values
protocol ABTestValue {
    associatedtype ValueType
    var defaultValue: ValueType { get }
}

/// String A/B test value
struct StringABTest: ABTestValue {
    typealias ValueType = String
    let key: ABTestKey
    let defaultValue: String
    
    init(_ key: ABTestKey, defaultValue: String) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

/// Boolean A/B test value
struct BoolABTest: ABTestValue {
    typealias ValueType = Bool
    let key: ABTestKey
    let defaultValue: Bool
    
    init(_ key: ABTestKey, defaultValue: Bool) {
        self.key = key
        self.defaultValue = defaultValue
    }
}

/// Integer A/B test value
struct IntABTest: ABTestValue {
    typealias ValueType = Int
    let key: ABTestKey
    let defaultValue: Int
    
    init(_ key: ABTestKey, defaultValue: Int) {
        self.key = key
        self.defaultValue = defaultValue
    }
}
