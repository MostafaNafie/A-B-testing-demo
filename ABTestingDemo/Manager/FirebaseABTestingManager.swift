//
//  FirebaseABTestingManager.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import Foundation
import Combine
import FirebaseRemoteConfig
import FirebaseAnalytics

/// Concrete Firebase implementation of ABTestingManager
final class FirebaseABTestingManager {

    // MARK: - Properties
    private let remoteConfig = RemoteConfig.remoteConfig()
    private let valuesSubject = PassthroughSubject<Void, Never>()

    var valuesUpdated: AnyPublisher<Void, Never> {
        valuesSubject.eraseToAnyPublisher()
    }

    static var shared = FirebaseABTestingManager()

    // MARK: - Initialization
    private init() {
        setupRemoteConfig()
    }
    
    // MARK: - ABTestingManager Implementation
    
    func getString(for test: StringABTest) -> ABTestVariant<String> {
        let value = remoteConfig.configValue(forKey: test.key.rawValue).stringValue
        let experimentInfo = getExperimentInfo(for: test.key)

        return ABTestVariant(
            value: value,
            variantName: experimentInfo.variantName,
            experimentId: experimentInfo.experimentId
        )
    }
    
    func getBool(for test: BoolABTest) -> ABTestVariant<Bool> {
        let value = remoteConfig.configValue(forKey: test.key.rawValue).boolValue
        let experimentInfo = getExperimentInfo(for: test.key)
        
        return ABTestVariant(
            value: value,
            variantName: experimentInfo.variantName,
            experimentId: experimentInfo.experimentId
        )
    }
    
    func getInt(for test: IntABTest) -> ABTestVariant<Int> {
        let value = remoteConfig.configValue(forKey: test.key.rawValue).numberValue.intValue
        let experimentInfo = getExperimentInfo(for: test.key)
        
        return ABTestVariant(
            value: value,
            variantName: experimentInfo.variantName,
            experimentId: experimentInfo.experimentId
        )
    }
    
    func refresh() async {
        await fetchAndActivateConfig()
    }
    
    func trackEvent(for key: ABTestKey, variant: String, action: String) {
        let parameters: [String: Any] = [
            "experiment_key": key.rawValue,
            "variant": variant,
            "action": action
        ]
        
        Analytics.logEvent(action, parameters: parameters)
        
        // Also log a custom event for easier analysis
        Analytics.logEvent("ab_test_event", parameters: [
            "test_key": key.rawValue,
            "variant": variant,
            "event_type": action
        ])
    }
}

// MARK: - Private Methods
private extension FirebaseABTestingManager {
    /// Setup Remote Config with default values and fetch settings
    func setupRemoteConfig() {
        // Configure fetch settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development - set to 3600 for production
        remoteConfig.configSettings = settings

        Task {
            // Setting custom user properties
            try? await remoteConfig.setCustomSignals(["role": "agent"])
            // Fetch and activate config
            await fetchAndActivateConfig()
        }
    }

    func fetchAndActivateConfig() async {
        do {
            print("⏳ Fetching Values from Firebase Remote Config...")

            let status = try await remoteConfig.fetchAndActivate()

            switch status {
                case .successFetchedFromRemote:
                    print("✅ Firebase Remote Config fetched from remote and cached")
                case .successUsingPreFetchedData:
                    print("📱 Firebase Remote Config using cached data")
                default:
                    print("🔄 Firebase Remote Config fetch completed with status: \(status)")
            }

            print("🔄 Remote Config updated - triggering valuesUpdated publisher")
            valuesSubject.send()

            #if DEBUG
            // Log all remote keys for debugging
            let keys = remoteConfig.allKeys(from: .remote)
            print("📋 Remote Config Keys (\(keys.count) total):")
            for key in keys {
                let val = remoteConfig.configValue(forKey: key)
                print("  • \(key) = \(val.stringValue)")
            }
            #endif

        } catch {
            print("❌ Firebase Remote Config fetch failed: \(error)")
        }
    }
    
    func getExperimentInfo(for key: ABTestKey) -> (variantName: String, experimentId: String?) {
        let configValue = remoteConfig.configValue(forKey: key.rawValue)
        
        // Extract experiment info from Remote Config metadata
        // Note: In a real implementation, you might need to parse additional metadata
        // from Firebase A/B Testing to get the actual experiment ID and variant name
        
        let variantName: String
        let experimentId: String?
        
        switch configValue.source {
        case .remote:
            // This value came from an A/B test
            variantName = "variant_\(abs((configValue.stringValue).hashValue) % 2)" // Simplified variant naming
            experimentId = "exp_\(key.rawValue)" // Simplified experiment ID
        case .default:
            variantName = "control"
            experimentId = nil
        case .static:
            variantName = "static"
            experimentId = nil
        @unknown default:
            variantName = "unknown"
            experimentId = nil
        }
        
        return (variantName, experimentId)
    }
}

// MARK: - A/B Test Event Tracking
/// Events for A/B test analytics
enum ABTestEvent: String {
    case impression = "ab_test_impression"
    case interaction = "ab_test_interaction"
    case conversion = "ab_test_conversion"
}

// MARK: - A/B Testing Manager Extensions
extension FirebaseABTestingManager {
    /// Convenience method to get color from string A/B test
    func getColor(for test: StringABTest) -> ABTestVariant<String> {
        return getString(for: test)
    }

    /// Track impression event
    func trackImpression(for key: ABTestKey, variant: String) {
        trackEvent(for: key, variant: variant, action: ABTestEvent.impression.rawValue)
    }

    /// Track interaction event
    func trackInteraction(for key: ABTestKey, variant: String) {
        trackEvent(for: key, variant: variant, action: ABTestEvent.interaction.rawValue)
    }

    /// Track conversion event
    func trackConversion(for key: ABTestKey, variant: String) {
        trackEvent(for: key, variant: variant, action: ABTestEvent.conversion.rawValue)
    }
}
