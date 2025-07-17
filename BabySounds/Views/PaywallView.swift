import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var subscriptionService: SubscriptionServiceSK2
    
    @State private var selectedProductId = "baby.annual"
    @State private var showParentGate = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header Illustration
                    VStack(spacing: 16) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                        
                        Text("Sweet Dreams Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Unlock all premium sounds and features for better sleep")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Features List
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "music.note.list",
                            title: "50+ Premium Sounds",
                            description: "Exclusive nature sounds, womb sounds, and music tracks"
                        )
                        
                        FeatureRow(
                            icon: "slider.horizontal.3",
                            title: "Multi-Sound Mixing",
                            description: "Create custom blends with up to 4 sounds playing together"
                        )
                        
                        FeatureRow(
                            icon: "timer",
                            title: "Extended Sleep Timer",
                            description: "Sleep timer up to 12 hours for all-night comfort"
                        )
                        
                        FeatureRow(
                            icon: "calendar",
                            title: "Sleep Schedules",
                            description: "Automated bedtime routines with your favorite sounds"
                        )
                        
                        FeatureRow(
                            icon: "moon.fill",
                            title: "Dark Night Controls",
                            description: "Special dark mode with red-tinted controls for nighttime use"
                        )
                        
                        FeatureRow(
                            icon: "arrow.down.circle",
                            title: "Offline Sound Packs",
                            description: "Download sounds for airplane mode and data-free listening"
                        )
                    }
                    .padding(.horizontal)
                    
                    // Subscription Options
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        VStack(spacing: 12) {
                            SubscriptionCard(
                                productId: "baby.annual",
                                title: "Annual Plan",
                                price: "$19.99/year",
                                savings: "Save 50%",
                                trialText: "7-day free trial",
                                isSelected: selectedProductId == "baby.annual"
                            ) {
                                selectedProductId = "baby.annual"
                            }
                            
                            SubscriptionCard(
                                productId: "baby.monthly", 
                                title: "Monthly Plan",
                                price: "$3.99/month",
                                savings: nil,
                                trialText: "7-day free trial",
                                isSelected: selectedProductId == "baby.monthly"
                            ) {
                                selectedProductId = "baby.monthly"
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // CTA Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            showParentGate = true
                        }) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Start 7-Day Free Trial")
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            )
                        }
                        .disabled(isLoading)
                        
                        Button("Maybe Later") {
                            isPresented = false
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Legal Text
                    VStack(spacing: 8) {
                        Text("7-day free trial, then \(selectedProductId == "baby.annual" ? "$19.99/year" : "$3.99/month")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Subscription automatically renews. Cancel anytime in Settings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        HStack(spacing: 16) {
                            Button("Terms of Service") {
                                // TODO: Open terms
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("Privacy Policy") {
                                // TODO: Open privacy policy
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                            
                            Button("Restore") {
                                Task {
                                    await restorePurchases()
                                }
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("✕") {
                        isPresented = false
                    }
                    .font(.title2)
                    .foregroundColor(.secondary)
                }
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                onSuccess: {
                    Task {
                        await purchaseSubscription()
                    }
                }
            )
        }
    }
    
    private func purchaseSubscription() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await subscriptionService.purchase(productId: selectedProductId)
            // TODO: Track analytics event: purchase_success
            isPresented = false
        } catch {
            // TODO: Handle purchase error
            // TODO: Track analytics event: purchase_fail
            print("Purchase failed: \(error)")
        }
    }
    
    private func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await subscriptionService.restorePurchases()
            // TODO: Track analytics event: restore
            if subscriptionService.isPremium {
                isPresented = false
            }
        } catch {
            // TODO: Handle restore error
            print("Restore failed: \(error)")
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct SubscriptionCard: View {
    let productId: String
    let title: String
    let price: String
    let savings: String?
    let trialText: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.orange)
                                )
                        }
                        
                        Spacer()
                    }
                    
                    Text(price)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(trialText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color.clear)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    PaywallView(isPresented: .constant(true))
        .environmentObject(SubscriptionServiceSK2())
} 