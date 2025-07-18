//
//  main.swift
//  BabySoundsApp
//
/// Entry point for BabySounds iOS application
///
/// Modern app for child sleep with safe audio accompaniment
/// Features COPPA compliance, premium subscriptions, and comprehensive audio engine
/// 
/// Key Features:
/// - AVAudioEngine with multi-track mixing
/// - StoreKit 2 premium subscriptions  
/// - Kids Category compliance (COPPA safe)
/// - WHO hearing safety guidelines

import SwiftUI
import BabySoundsCore

/// Main BabySounds application
@main struct BabySoundsApp: App {
    /// Application state
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .task {
                    // Initialize audio session on startup
                    await appState.initializeAudio()
                }
        }
    }
}

/// Main application content
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            Text("🍼 BabySounds")
                .font(.largeTitle)
            
            // Main content
            if appState.isAudioReady {
                MainAppView()
            } else {
                LoadingView()
            }
            
            // Footer with version
            Text("v1.0.0 - Kids Category")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct MainAppView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Welcome to BabySounds")
                .font(.title2)
            
            Text("Safe sleep sounds for children")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Demo of UI component from BabySoundsUI
            VStack {
                Text("Audio System")
                    .font(.headline)
                
                // Audio system status
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 12, height: 12)
                    Text("Audio Ready")
                        .font(.subheadline)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button("Play Demo Sound") {
                // Here will be sound playback implementation
                // via BabySoundsCore
                playDemoSound()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private func playDemoSound() {
        // Here will be sound playback implementation
        // via BabySoundsCore
    }
}

/// Application state
@MainActor
class AppState: ObservableObject {
    @Published var isAudioReady = false
    
    /// Audio system initialization
    func initializeAudio() async {
        do {
            // Simulate audio initialization
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isAudioReady = true
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Initializing Audio...")
                .padding(.top)
        }
    }
} 