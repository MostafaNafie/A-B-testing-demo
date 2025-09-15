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
    
    /// Force refresh Remote Config, bypassing cache
    func forceRefresh() async {
        // Temporarily set minimum fetch interval to 0 to bypass cache
        let originalInterval = remoteConfig.configSettings.minimumFetchInterval
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        settings.fetchTimeout = remoteConfig.configSettings.fetchTimeout
        remoteConfig.configSettings = settings
        
        await fetchAndActivateConfig()
        
        // Restore original settings
        let restoredSettings = RemoteConfigSettings()
        restoredSettings.minimumFetchInterval = originalInterval
        restoredSettings.fetchTimeout = settings.fetchTimeout
        remoteConfig.configSettings = restoredSettings
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
        // Configure fetch settings for optimal caching
        let settings = RemoteConfigSettings()
        
        #if DEBUG
        // For development - allow frequent fetches to test changes
        settings.minimumFetchInterval = 60
        #else
        // For production - cache for 1 hour to reduce network calls and improve performance
        settings.minimumFetchInterval = 3600
        #endif
        
        // Set fetch timeout (default is 60 seconds)
        settings.fetchTimeout = 30
        
        remoteConfig.configSettings = settings

        Task {
            // Setting custom user properties for better targeting
            try? await remoteConfig.setCustomSignals(["role": "agent"])
            
            // Initial fetch and activate - subsequent calls will use cache when appropriate
            await fetchAndActivateConfig()
        }
    }

    func fetchAndActivateConfig() async {
        do {
            // Check if we should fetch based on cache status
            print(getCacheStatus())

            if isCacheValid() {
                print("📱 Using cached Remote Config values")
                triggerValuesUpdated()
                return
            }
            
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

            triggerValuesUpdated()
        } catch {
            print("❌ Firebase Remote Config fetch failed: \(error)")
        }
    }

    func triggerValuesUpdated() {
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

    /// Get detailed cache status information
    func getCacheStatus() -> String {
        let cacheInfo = getCacheInfo()

        if let lastFetch = cacheInfo.lastFetchTime {
            let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
            let isValid = isCacheValid()
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium

            return """
            Cache Status: \(isValid ? "✅ Valid" : "⚠️ Expired")
            Last Fetch: \(formatter.string(from: lastFetch))
            Time Since Fetch: \(Int(timeSinceLastFetch))s
            Cache Duration: \(Int(cacheInfo.cacheExpiration))s
            """
        } else {
            return "Cache Status: ❌ No data fetched yet"
        }
    }

    /// Get cache information
    func getCacheInfo() -> (lastFetchTime: Date?, cacheExpiration: TimeInterval) {
        return (
            lastFetchTime: remoteConfig.lastFetchTime,
            cacheExpiration: remoteConfig.configSettings.minimumFetchInterval
        )
    }

    /// Check if cache is valid (not expired)
    func isCacheValid() -> Bool {
        guard let lastFetch = remoteConfig.lastFetchTime else { return false }
        let cacheExpiration = remoteConfig.configSettings.minimumFetchInterval
        return Date().timeIntervalSince(lastFetch) < cacheExpiration
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
