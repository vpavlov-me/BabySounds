import SwiftUI

// MARK: - Premium Gate View

/// Displays premium content gates with appropriate UI feedback
struct PremiumGateView: View {
    let feature: PremiumManager.PremiumFeature
    let onUnlock: () -> Void
    
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var pulseAnimation = false
    
    var body: some View {
        VStack(spacing: 16) {
            // Premium Lock Icon with Animation
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                    .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                    .animation(
                        Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: pulseAnimation
                    )
                
                Image(systemName: "crown.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.orange)
            }
            .onAppear {
                pulseAnimation = true
            }
            
            // Feature Info
            VStack(spacing: 8) {
                Text(feature.localizedName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            // Unlock Button
            Button(action: onUnlock) {
                HStack(spacing: 8) {
                    Image(systemName: "lock.open.fill")
                        .font(.callout)
                    
                    Text("Unlock Premium")
                        .font(.callout)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.orange, .orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(Capsule())
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
    }
}

// MARK: - Premium Badge

/// Shows premium badge on content
struct PremiumBadge: View {
    let isLocked: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isLocked ? "lock.fill" : "crown.fill")
                .font(.caption2)
            
            Text("Premium")
                .font(.caption2)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            LinearGradient(
                colors: isLocked ? [.gray, .gray.opacity(0.8)] : [.orange, .orange.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(Capsule())
    }
}

// MARK: - Premium Content Overlay

/// Overlay for premium-locked content
struct PremiumContentOverlay: View {
    let feature: PremiumManager.PremiumFeature
    let onUnlock: () -> Void
    
    var body: some View {
        ZStack {
            // Background blur
            Rectangle()
                .fill(.ultraThinMaterial)
            
            // Lock content
            VStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.orange)
                
                Text("Premium Feature")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Button("Unlock") {
                    onUnlock()
                }
                .font(.callout)
                .fontWeight(.medium)
                .foregroundColor(.orange)
            }
        }
    }
}

// MARK: - Premium Alert Modifier

struct PremiumAlertModifier: ViewModifier {
    @ObservedObject var premiumManager: PremiumManager
    @Binding var showPaywall: Bool
    @State private var alertMessage: String?
    
    func body(content: Content) -> some View {
        content
            .onChange(of: premiumManager.gateActionTrigger) { _ in
                guard let action = premiumManager.pendingGateAction else { return }
                
                switch action {
                case .showPaywall:
                    showPaywall = true
                    premiumManager.clearPendingAction()
                    
                case .showMessage(let message):
                    alertMessage = message
                    premiumManager.clearPendingAction()
                    
                case .allow:
                    break // No action needed
                }
            }
            .alert("Premium Feature", isPresented: .constant(alertMessage != nil)) {
                Button("Upgrade to Premium") {
                    showPaywall = true
                    alertMessage = nil
                }
                
                Button("Maybe Later", role: .cancel) {
                    alertMessage = nil
                }
            } message: {
                if let message = alertMessage {
                    Text(message)
                }
            }
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Premium Feature Card

/// Card showing premium feature benefits
struct PremiumFeatureCard: View {
    let feature: PremiumManager.PremiumFeature
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Feature Icon
            ZStack {
                Circle()
                    .fill(isUnlocked ? .green.opacity(0.2) : .orange.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(isUnlocked ? .green : .orange)
            }
            
            // Feature Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(feature.localizedName)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    if isUnlocked {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                Text(feature.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
        .opacity(isUnlocked ? 1.0 : 0.8)
    }
}

// MARK: - View Extensions

extension View {
    /// Apply premium gate alert modifier
    func premiumGateAlert(
        premiumManager: PremiumManager,
        showPaywall: Binding<Bool>
    ) -> some View {
        modifier(PremiumAlertModifier(premiumManager: premiumManager, showPaywall: showPaywall))
    }
    
    /// Apply premium content styling
    func premiumContent(
        feature: PremiumManager.PremiumFeature,
        premiumManager: PremiumManager
    ) -> some View {
        self
            .opacity(premiumManager.premiumContentOpacity(for: feature))
            .disabled(premiumManager.isPremiumContentDisabled(for: feature))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        PremiumGateView(feature: .premiumSounds) {
            print("Unlock tapped")
        }
        
        PremiumFeatureCard(feature: .multiTrackMixing, isUnlocked: false)
        
        PremiumFeatureCard(feature: .extendedTimer, isUnlocked: true)
    }
    .padding()
    .environmentObject(PremiumManager(subscriptionService: SubscriptionServiceSK2()))
}
