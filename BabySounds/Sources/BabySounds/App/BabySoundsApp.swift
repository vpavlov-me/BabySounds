import SwiftUI
import AVFoundation

@main
struct BabySoundsApp: App {
    @StateObject private var audioManager = AudioEngineManager.shared
    @StateObject private var subscriptionService = SubscriptionServiceSK2.shared
    @StateObject private var soundCatalog = SoundCatalog.shared
    @StateObject private var premiumManager = PremiumManager.shared
    @StateObject private var safeVolumeManager = SafeVolumeManager.shared

    init() {
        // Setup background audio session
        AudioEngineManager.shared.setupBackgroundAudioSession()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(audioManager)
                .environmentObject(subscriptionService)
                .environmentObject(soundCatalog)
                .environmentObject(premiumManager)
                .environmentObject(safeVolumeManager)
                .onAppear {
                    Task {
                        await subscriptionService.initialize()
                    }
                }
        }
    }
} 