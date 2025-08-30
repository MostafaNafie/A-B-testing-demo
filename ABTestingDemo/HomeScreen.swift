//
//  ContentView.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import SwiftUI
import Combine

struct HomeScreen: View {
    private var abTestManager = FirebaseABTestingManager.shared
    @State private var cancellables = Set<AnyCancellable>()
    @State private var isRefreshing = false
    
    // A/B test values
    @State private var buttonColor = "blue"
    @State private var buttonText = "Get Started"
    @State private var welcomeMessage = "Welcome to our app!"
    @State private var featureEnabled = false
    @State private var maxItems = 10
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    headerSection
                    
                    abTestDemoSection
                    
                    if featureEnabled {
                        featureSection
                    }
                    
                    controlsSection
                }
                .padding()
            }
            .navigationTitle("A/B Testing Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: refreshABTests) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(isRefreshing)
                }
            }
        }
        .onAppear {
                loadABTestValues()
                setupABTestObserver()
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "flask")
                .font(.system(size: 60))
                .foregroundColor(Color.from(string: buttonColor))
            
            Text(welcomeMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .onAppear {
                    // Track impression for welcome message
                    let variant = abTestManager.getString(for: ABTestConfiguration.welcomeMessage)
                    abTestManager.trackImpression(for: .welcomeMessage, variant: variant.variantName)
                }
        }
    }
    
    private var abTestDemoSection: some View {
        VStack(spacing: 20) {
            Text("A/B Test Demo")
                .font(.headline)
            
            // Dynamic button based on A/B test
            Button(action: {
                let variant = abTestManager.getString(for: ABTestConfiguration.buttonColor)
//                abTestManager.trackInteraction(for: .buttonText, variant: variant.variantName)
                abTestManager.trackInteraction(for: .buttonColor, variant: variant.value)

                // Simulate conversion
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    abTestManager.trackConversion(for: .buttonText, variant: variant.variantName)
                }
            }) {
                Text(buttonText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.from(string: buttonColor))
                    .cornerRadius(12)
            }
            .onAppear {
                // Track impression for button
                let colorVariant = abTestManager.getString(for: ABTestConfiguration.buttonColor)
                let textVariant = abTestManager.getString(for: ABTestConfiguration.buttonText)
                
                abTestManager.trackImpression(for: .buttonColor, variant: colorVariant.variantName)
                abTestManager.trackImpression(for: .buttonText, variant: textVariant.variantName)
            }
        }
    }
    
    private var featureSection: some View {
        VStack(spacing: 15) {
            Text("🎉 Special Feature")
                .font(.headline)
            
            Text("This feature is enabled through A/B testing!")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 10) {
                ForEach(1...maxItems, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.from(string: buttonColor).opacity(0.3))
                        .frame(height: 60)
                        .overlay {
                            Text("Item \(index)")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .onAppear {
            let variant = abTestManager.getBool(for: ABTestConfiguration.featureEnabled)
            abTestManager.trackImpression(for: .featureEnabled, variant: variant.variantName)
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 15) {
            Text("Current A/B Test Values")
                .font(.headline)
            
            VStack(spacing: 8) {
                ABTestValueRow(title: "Button Color", value: buttonColor)
                ABTestValueRow(title: "Button Text", value: buttonText)
                ABTestValueRow(title: "Welcome Message", value: welcomeMessage)
                ABTestValueRow(title: "Feature Enabled", value: String(featureEnabled))
                ABTestValueRow(title: "Max Items", value: String(maxItems))
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Actions
    
    private func loadABTestValues() {
        buttonColor = abTestManager.getString(for: ABTestConfiguration.buttonColor).value
        buttonText = abTestManager.getString(for: ABTestConfiguration.buttonText).value
        welcomeMessage = abTestManager.getString(for: ABTestConfiguration.welcomeMessage).value
        featureEnabled = abTestManager.getBool(for: ABTestConfiguration.featureEnabled).value
        maxItems = abTestManager.getInt(for: ABTestConfiguration.maxItems).value
    }
    
    private func setupABTestObserver() {
        abTestManager.valuesUpdated
            .receive(on: DispatchQueue.main)
            .sink {
                loadABTestValues()
            }
            .store(in: &cancellables)
    }
    
    private func refreshABTests() {
        isRefreshing = true
        
        Task {
            await abTestManager.refresh()
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Helper Views

struct ABTestValueRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(4)
        }
    }
}

#Preview {
    HomeScreen()
}
