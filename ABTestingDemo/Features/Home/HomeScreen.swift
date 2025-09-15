//
//  ContentView.swift
//  ABTestingDemo
//
//  Created by Nafie on 27/08/2025.
//

import SwiftUI

struct HomeScreen: View {
    @StateObject private var viewModel = HomeScreenViewModel()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                    headerSection
                    
                    abTestDemoSection
                    
                    if viewModel.featureEnabled {
                        featureSection
                    }
                    
                    controlsSection
                }
                .padding()
            }
            .navigationTitle("A/B Testing Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.refreshButtonOnTap) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isRefreshing)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "flask")
                .font(.system(size: 60))
                .foregroundColor(Color.from(string: viewModel.buttonColor))
            
            Text(viewModel.welcomeMessage)
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .onAppear {
                    viewModel.welcomeMessageOnAppear()
                }
        }
    }
    
    private var abTestDemoSection: some View {
        VStack(spacing: 20) {
            Text("A/B Test Demo")
                .font(.headline)
            
            Button(action: viewModel.buttonOnTap) {
                Text(viewModel.buttonText)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.from(string: viewModel.buttonColor))
                    .cornerRadius(12)
            }
            .onAppear {
                viewModel.buttonOnAppear()
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
                ForEach(1...viewModel.maxItems, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.from(string: viewModel.buttonColor).opacity(0.3))
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
            viewModel.featureSectionOnAppear()
        }
    }
    
    private var controlsSection: some View {
        VStack(spacing: 15) {
            Text("Current A/B Test Values")
                .font(.headline)
            
            VStack(spacing: 8) {
                ABTestValueRow(title: "Button Color", value: viewModel.buttonColor)
                ABTestValueRow(title: "Button Text", value: viewModel.buttonText)
                ABTestValueRow(title: "Welcome Message", value: viewModel.welcomeMessage)
                ABTestValueRow(title: "Feature Enabled", value: String(viewModel.featureEnabled))
                ABTestValueRow(title: "Max Items", value: String(viewModel.maxItems))
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(8)
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
