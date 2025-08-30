//
//  HomeScreenViewModel.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import SwiftUI
import Combine

@MainActor
class HomeScreenViewModel: ObservableObject {
    private var abTestManager = FirebaseABTestingManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isRefreshing = false
    
    // A/B test values
    @Published var maxItems = 10
    @Published var featureEnabled = false
    @Published var buttonColor = "blue"
    @Published var buttonText = "Get Started"
    @Published var welcomeMessage = "Welcome to our app!"
    
    init() {
        loadABTestValues()
        setupABTestObserver()
    }
    
    // MARK: - Public Methods
    func onAppear() {
        loadABTestValues()
        setupABTestObserver()
    }

    func welcomeMessageOnAppear() {
        trackWelcomeMessageImpression()
    }

    func buttonOnAppear() {
        trackButtonImpressions()
    }

    func featureSectionOnAppear() {
        trackFeatureImpression()
    }

    func buttonOnTap() {
        handleButtonTap()
    }

    func refreshButtonOnTap() {
        isRefreshing = true

        Task {
            await abTestManager.refresh()

            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

private extension HomeScreenViewModel {
    func loadABTestValues() {
        buttonColor = abTestManager.getString(for: ABTestConfiguration.buttonColor).value
        buttonText = abTestManager.getString(for: ABTestConfiguration.buttonText).value
        welcomeMessage = abTestManager.getString(for: ABTestConfiguration.welcomeMessage).value
        featureEnabled = abTestManager.getBool(for: ABTestConfiguration.featureEnabled).value
        maxItems = abTestManager.getInt(for: ABTestConfiguration.maxItems).value
    }

    func setupABTestObserver() {
        abTestManager.valuesUpdated
            .receive(on: DispatchQueue.main)
            .sink {
                self.loadABTestValues()
            }
            .store(in: &cancellables)
    }
}

// MARK: - Tracking
private extension HomeScreenViewModel {
    func trackWelcomeMessageImpression() {
        let variant = abTestManager.getString(for: ABTestConfiguration.welcomeMessage)
        abTestManager.trackImpression(for: .welcomeMessage, variant: variant.variantName)
    }

    func trackButtonImpressions() {
        let colorVariant = abTestManager.getString(for: ABTestConfiguration.buttonColor)
        let textVariant = abTestManager.getString(for: ABTestConfiguration.buttonText)

        abTestManager.trackImpression(for: .buttonColor, variant: colorVariant.variantName)
        abTestManager.trackImpression(for: .buttonText, variant: textVariant.variantName)
    }

    func trackFeatureImpression() {
        let variant = abTestManager.getBool(for: ABTestConfiguration.featureEnabled)
        abTestManager.trackImpression(for: .featureEnabled, variant: variant.variantName)
    }

    func handleButtonTap() {
        let variant = abTestManager.getString(for: ABTestConfiguration.buttonColor)
        abTestManager.trackInteraction(for: .buttonColor, variant: variant.value)

        // Simulate conversion
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.abTestManager.trackConversion(for: .buttonText, variant: variant.variantName)
        }
    }
}
