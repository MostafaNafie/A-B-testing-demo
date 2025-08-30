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
final class FirebaseABTestingManager: ObservableObject {

    // MARK: - Properties
    private let remoteConfig = RemoteConfig.remoteConfig()
    private let valuesSubject = PassthroughSubject<Void, Never>()
    private var notificationObserver: NSObjectProtocol?
    
    var valuesUpdated: AnyPublisher<Void, Never> {
        valuesSubject.eraseToAnyPublisher()
    }

    static var shared = FirebaseABTestingManager()

    // MARK: - Initialization
    private init() {
        setupRemoteConfig()
        setupRemoteConfigObserver()
    }

    /// Setup Remote Config with default values and fetch settings
    private func setupRemoteConfig() {
        let remoteConfig = RemoteConfig.remoteConfig()

        // Configure fetch settings
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0 // For development - set to 3600 for production
        remoteConfig.configSettings = settings

        Task {
            // Example of setting custom user properties
            try? await remoteConfig.setCustomSignals(["role": "agent"])
        }

        // Fetch and activate config
        remoteConfig.fetchAndActivate { status, error in
            if let error = error {
                print("Firebase Remote Config fetch failed: \(error)")
                return
            }

            switch status {
            case .successFetchedFromRemote:
                print("Firebase Remote Config fetched from remote")
                // Notify that Remote Config values have been updated
                NotificationCenter.default.post(name: .remoteConfigUpdated, object: nil)
            case .successUsingPreFetchedData:
                print("Firebase Remote Config using pre-fetched data")
                // Notify that Remote Config values are ready
                NotificationCenter.default.post(name: .remoteConfigUpdated, object: nil)
            default:
                print("Firebase Remote Config fetch completed with status: \(status)")
                NotificationCenter.default.post(name: .remoteConfigUpdated, object: nil)
            }
        }
    }

    private func setupRemoteConfigObserver() {
        // Observe Remote Config value changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .remoteConfigUpdated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            print("🔄 Remote Config updated - triggering valuesUpdated publisher")
            self?.valuesSubject.send()
        }
    }
    
    deinit {
        if let observer = notificationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - ABTestingManager Implementation
    
    func getString(for test: StringABTest) -> ABTestVariant<String> {
        let configValue = remoteConfig.configValue(forKey: test.key.rawValue)
        let value = configValue.stringValue
        let experimentInfo = getExperimentInfo(for: test.key)

        print(">>> Config for \(test.key.rawValue): '\(configValue.stringValue)' (source: \(configValue.source))")

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
        let configValue = remoteConfig.configValue(forKey: test.key.rawValue)
        let value = configValue.numberValue.intValue
        let experimentInfo = getExperimentInfo(for: test.key)
        
        return ABTestVariant(
            value: value,
            variantName: experimentInfo.variantName,
            experimentId: experimentInfo.experimentId
        )
    }
    
    func refresh() async {
        do {
            let status = try await remoteConfig.fetchAndActivate()
            
            DispatchQueue.main.async { [weak self] in
                print("🔄 Manual refresh - triggering valuesUpdated publisher")
                self?.valuesSubject.send()
            }
            
            switch status {
            case .successFetchedFromRemote:
                print("Firebase Remote Config refreshed from remote")
            case .successUsingPreFetchedData:
                print("Firebase Remote Config using cached data")
            default:
                print("Firebase Remote Config refresh completed with status: \(status)")
            }
        } catch {
            print("Firebase Remote Config refresh failed: \(error)")
        }
    }
    
    /// Manually trigger the valuesUpdated publisher (useful for initial load)
    func triggerUpdate() {
        DispatchQueue.main.async { [weak self] in
            print("🔄 Manual trigger - sending valuesUpdated")
            self?.valuesSubject.send()
        }
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
    
    // MARK: - Private Methods
    
    private func getExperimentInfo(for key: ABTestKey) -> (variantName: String, experimentId: String?) {
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
