import SwiftUI

// MARK: - Apple Music Style Settings View

struct AppleMusicSettingsView: View {
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    @EnvironmentObject var premiumManager: PremiumManager
    @EnvironmentObject var audioManager: AudioEngineManager
    
    @State private var showPaywall = false
    @State private var showParentGate = false
    @State private var showNowPlaying = false
    @State private var pendingAction: (() -> Void)?
    @AppStorage("safeVolumeEnabled") private var safeVolumeEnabled = true
    @AppStorage("offlineDownloadsEnabled") private var offlineDownloadsEnabled = false
    @AppStorage("hasPassedParentGate") private var hasPassedParentGate = false
    @AppStorage("parentGateTimeout") private var parentGateTimeout: Double = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                // Main content
                List {
                    // Account Section
                    Section {
                        accountSection
                    } header: {
                        Text("Account")
                            .textCase(.none)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Audio Section
                    Section {
                        audioSection
                    } header: {
                        Text("Audio")
                            .textCase(.none)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Downloads Section (Premium)
                    if premiumManager.isPremium {
                        Section {
                            downloadsSection
                        } header: {
                            Text("Downloads")
                                .textCase(.none)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }
                    
                    // Child Safety Section
                    Section {
                        safetySection
                    } header: {
                        Text("Child Safety")
                            .textCase(.none)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // About Section
                    Section {
                        aboutSection
                    } header: {
                        Text("About")
                            .textCase(.none)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Bottom spacing for mini player
                    Color.clear
                        .frame(height: 100)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .listStyle(.insetGrouped)
                
                // Mini Player
                MiniPlayerView(showNowPlaying: $showNowPlaying)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarTitleDisplayMode(.large)
        .navigationTitle("Settings")
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: .settings,
                onSuccess: {
                    hasPassedParentGate = true
                    parentGateTimeout = Date().timeIntervalSince1970 + 300 // 5 minutes
                    pendingAction?()
                    pendingAction = nil
                }
            )
        }
        .fullScreenCover(isPresented: $showNowPlaying) {
            NowPlayingView(isPresented: $showNowPlaying)
        }
    }
    
    // MARK: - Account Section
    
    private var accountSection: some View {
        Group {
            if subscriptionService.isPremium {
                // Premium status
                SettingsRow(
                    icon: "crown.fill",
                    iconColor: .orange,
                    title: "Premium",
                    subtitle: "Active subscription",
                    trailing: {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                )
            } else {
                // Upgrade to Premium
                SettingsRow(
                    icon: "crown.fill",
                    iconColor: .orange,
                    title: "Upgrade to Premium",
                    subtitle: "Unlock all sounds and features",
                    action: {
                        showPaywall = true
                        HapticManager.shared.impact(.light)
                    },
                    trailing: {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                )
            }
            
            // Restore Purchases
            SettingsRow(
                icon: "arrow.clockwise",
                iconColor: .blue,
                title: "Restore Purchases",
                subtitle: "Restore previous purchases",
                action: {
                    requireParentGate {
                        restorePurchases()
                    }
                }
            )
        }
    }
    
    // MARK: - Audio Section
    
    private var audioSection: some View {
        Group {
            // Safe Volume
            SettingsRow(
                icon: "speaker.wave.2.fill",
                iconColor: .pink,
                title: "Safe Volume",
                subtitle: "WHO-compliant hearing protection",
                trailing: {
                    Toggle("", isOn: $safeVolumeEnabled)
                        .labelsHidden()
                        .onChange(of: safeVolumeEnabled) { enabled in
                            audioManager.setSafeVolumeEnabled(enabled)
                            HapticManager.shared.impact(.light)
                        }
                }
            )
            
            // Audio Quality (Premium feature)
            SettingsRow(
                icon: "waveform",
                iconColor: .purple,
                title: "Audio Quality",
                subtitle: premiumManager.isPremium ? "High Quality" : "Standard Quality",
                action: premiumManager.isPremium ? nil : {
                    showPaywall = true
                    HapticManager.shared.impact(.light)
                },
                trailing: {
                    if !premiumManager.isPremium {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            )
            
            // AirPlay
            SettingsRow(
                icon: "airplayaudio",
                iconColor: .blue,
                title: "AirPlay",
                subtitle: "Stream to speakers and headphones",
                action: {
                    // Handle AirPlay settings
                    HapticManager.shared.impact(.light)
                }
            )
        }
    }
    
    // MARK: - Downloads Section
    
    private var downloadsSection: some View {
        Group {
            // Offline Downloads Toggle
            SettingsRow(
                icon: "arrow.down.circle.fill",
                iconColor: .green,
                title: "Automatic Downloads",
                subtitle: "Download favorites for offline use",
                trailing: {
                    Toggle("", isOn: $offlineDownloadsEnabled)
                        .labelsHidden()
                        .onChange(of: offlineDownloadsEnabled) { _ in
                            HapticManager.shared.impact(.light)
                        }
                }
            )
            
            // Storage Usage
            SettingsRow(
                icon: "externaldrive.fill",
                iconColor: .orange,
                title: "Downloaded Sounds",
                subtitle: "Manage offline storage",
                action: {
                    // Navigate to downloads management
                    HapticManager.shared.impact(.light)
                },
                trailing: {
                    HStack {
                        Text("2.3 GB") // Placeholder
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            )
        }
    }
    
    // MARK: - Safety Section
    
    private var safetySection: some View {
        Group {
            // Parental Controls
            SettingsRow(
                icon: "hand.raised.fill",
                iconColor: .red,
                title: "Parental Controls",
                subtitle: "Manage child safety features",
                action: {
                    requireParentGate {
                        // Navigate to parental controls
                        HapticManager.shared.impact(.light)
                    }
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            )
            
            // Privacy
            SettingsRow(
                icon: "lock.shield.fill",
                iconColor: .blue,
                title: "Privacy",
                subtitle: "Data protection and usage",
                action: {
                    // Navigate to privacy settings
                    HapticManager.shared.impact(.light)
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            )
        }
    }
    
    // MARK: - About Section
    
    private var aboutSection: some View {
        Group {
            // Help & Support
            SettingsRow(
                icon: "questionmark.circle.fill",
                iconColor: .blue,
                title: "Help & Support",
                subtitle: "Get help with the app",
                action: {
                    // Navigate to help
                    HapticManager.shared.impact(.light)
                },
                trailing: {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            )
            
            // App Version
            SettingsRow(
                icon: "info.circle.fill",
                iconColor: .gray,
                title: "Version",
                subtitle: "1.0.0 (100)", // Placeholder
                trailing: {
                    EmptyView()
                }
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func requireParentGate(action: @escaping () -> Void) {
        if isParentGateValid() {
            action()
        } else {
            pendingAction = action
            showParentGate = true
        }
    }
    
    private func isParentGateValid() -> Bool {
        hasPassedParentGate && Date().timeIntervalSince1970 < parentGateTimeout
    }
    
    private func restorePurchases() {
        Task {
            do {
                try await subscriptionService.restorePurchases()
                HapticManager.shared.notification(.success)
            } catch {
                print("Failed to restore purchases: \(error)")
                HapticManager.shared.notification(.error)
            }
        }
    }
}

// MARK: - Settings Row

struct SettingsRow<Trailing: View>: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let trailing: () -> Trailing
    
    init(
        icon: String,
        iconColor: Color,
        title: String,
        subtitle: String? = nil,
        action: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.iconColor = iconColor
        self.title = title
        self.subtitle = subtitle
        self.action = action
        self.trailing = trailing
    }
    
    var body: some View {
        Button(action: action ?? {}) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(iconColor)
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: icon)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Trailing content
                trailing()
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(action == nil)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AppleMusicSettingsView()
            .environmentObject(SubscriptionServiceSK2.shared)
            .environmentObject(PremiumManager.shared)
            .environmentObject(AudioEngineManager.shared)
    }
} 