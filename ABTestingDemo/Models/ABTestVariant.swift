//
//  ABTestVariant.swift
//  ABTestingDemo
//
//  Created by Nafie on 30/08/2025.
//

import Foundation

// MARK: - A/B Test Variant
/// Represents an A/B test variant with metadata
struct ABTestVariant<T> {
    let value: T
    let variantName: String
    let experimentId: String?
    
    init(value: T, variantName: String = "default", experimentId: String? = nil) {
        self.value = value
        self.variantName = variantName
        self.experimentId = experimentId
    }
}
