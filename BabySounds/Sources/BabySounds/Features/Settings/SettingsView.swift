import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var safeVolumeManager: SafeVolumeManager
    @EnvironmentObject private var premiumManager: PremiumManager
    @EnvironmentObject private var subscriptionService: SubscriptionServiceSK2

    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationView {
            List {
                safetySection
                premiumSection
                appearanceSection
                privacySection
                aboutSection
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPrivacyPolicy) {
                PrivacyPolicyView()
            }
            .sheet(isPresented: $showingTerms) {
                TermsOfServiceView()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Safety Section

    private var safetySection: some View {
        Section {
            Toggle("WHO Volume Safety", isOn: Binding(
                get: { safeVolumeManager.isSafeVolumeEnabled },
                set: { safeVolumeManager.setEnabled($0) }
            ))

            VStack(alignment: .leading, spacing: 4) {
                Text("Volume Limit")
                    .font(.subheadline)

                HStack {
                    Image(systemName: "speaker.wave.1")
                        .foregroundColor(.secondary)

                    Slider(value: Binding(
                        get: { safeVolumeManager.currentVolumeLimit },
                        set: { safeVolumeManager.setVolumeLimit($0) }
                    ), in: 0.3 ... 0.75)

                    Image(systemName: "speaker.wave.3")
                        .foregroundColor(.secondary)

                    Text("\(Int(safeVolumeManager.currentVolumeLimit * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 40)
                }
            }
            .disabled(!safeVolumeManager.isSafeVolumeEnabled)

            if safeVolumeManager.totalListeningTime > 0 {
                HStack {
                    Text("Today's Listening Time")
                    Spacer()
                    Text(formatDuration(safeVolumeManager.totalListeningTime))
                        .foregroundColor(.secondary)
                }
            }
        } header: {
            Text("Hearing Safety")
        } footer: {
            Text("WHO recommends limiting volume to 75% and taking breaks every hour")
                .font(.caption)
        }
    }

    // MARK: - Premium Section

    private var premiumSection: some View {
        Section {
            if subscriptionService.hasActiveSubscription {
                HStack {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                    Text("Premium Active")
                    Spacer()
                    if let product = subscriptionService.currentSubscriptionProduct {
                        Text(product.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Button("Manage Subscription") {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.orange)
                        Text("Upgrade to Premium")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Button("Restore Purchases") {
                Task {
                    try? await subscriptionService.restorePurchases()
                }
            }
        } header: {
            Text("Premium")
        }
    }

    // MARK: - Appearance Section

    private var appearanceSection: some View {
        Section {
            NavigationLink("Display & Theme") {
                Text("Coming soon: Dark Night Mode")
                    .foregroundColor(.secondary)
            }

            Toggle("Reduced Motion", isOn: .constant(false))
                .disabled(true)
        } header: {
            Text("Appearance")
        }
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        Section {
            Toggle("Analytics", isOn: Binding(
                get: { true }, // AnalyticsService.shared.isEnabled
                set: { AnalyticsService.shared.setEnabled($0) }
            ))

            Button("Privacy Policy") {
                showingPrivacyPolicy = true
            }

            Button("Terms of Service") {
                showingTerms = true
            }
        } header: {
            Text("Privacy")
        } footer: {
            Text("We collect anonymous usage data to improve the app. No personal information is collected.")
                .font(.caption)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                Spacer()
                Text(appVersion)
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("Build")
                Spacer()
                Text(appBuild)
                    .foregroundColor(.secondary)
            }

            Button("Rate Baby Sounds") {
                // TODO: Replace with actual App Store ID when app is published
                if let url = URL(string: "https://apps.apple.com/app/id000000000?action=write-review") {
                    UIApplication.shared.open(url)
                }
            }

            Button("Support") {
                if let url = URL(string: "mailto:support@babysounds.app") {
                    UIApplication.shared.open(url)
                }
            }

            Button("GitHub") {
                if let url = URL(string: "https://github.com/vpavlov-me/BabySounds") {
                    UIApplication.shared.open(url)
                }
            }
        } header: {
            Text("About")
        } footer: {
            Text("Made with ❤️ for babies and parents")
                .font(.caption)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.top, 8)
        }
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var appBuild: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(SafeVolumeManager.shared)
        .environmentObject(PremiumManager.shared)
        .environmentObject(SubscriptionServiceSK2.shared)
}
