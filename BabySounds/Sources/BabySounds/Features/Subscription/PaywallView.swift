import SwiftUI

struct PaywallView: View {
    @Binding var isPresented: Bool
    @StateObject private var subscriptionService = SubscriptionServiceSK2.shared
    @StateObject private var parentGate = ParentGateManager.shared
    
    @State private var selectedProduct: Product?
    @State private var showParentGate = false
    @State private var parentGateContext: ParentGateManager.GateContext = .paywall
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private var purchaseButtonTitle: String {
        guard let product = selectedProduct else {
            return "Select a Plan"
        }
        
        if let trialInfo = subscriptionService.trialInfo(for: product) {
            return "Start \(trialInfo)"
        } else {
            return "Subscribe for \(subscriptionService.formattedPrice(for: product))"
        }
    }
    
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
                        
                        if subscriptionService.availableProducts.isEmpty {
                            if subscriptionService.isLoading {
                                VStack(spacing: 16) {
                                    ProgressView()
                                    Text("Loading subscription options...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 120)
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.system(size: 24))
                                        .foregroundColor(.orange)
                                    Text("Unable to load subscription options")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .frame(height: 120)
                            }
                        } else {
                            VStack(spacing: 12) {
                                ForEach(subscriptionService.availableProducts, id: \.id) { product in
                                    SubscriptionCardStoreKit(
                                        product: product,
                                        isSelected: selectedProduct?.id == product.id,
                                        subscriptionService: subscriptionService
                                    ) {
                                        selectedProduct = product
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // CTA Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            parentGateContext = .paywall
                            showParentGate = true
                        }) {
                            HStack {
                                if subscriptionService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                } else {
                                    Text(purchaseButtonTitle)
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
                        .disabled(subscriptionService.isLoading || selectedProduct == nil)
                        
                        Button("Restore Purchases") {
                            parentGateContext = .restore
                            showParentGate = true
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        
                        Button("Maybe Later") {
                            isPresented = false
                        }
                        .font(.body)
                        .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // Legal Text
                    VStack(spacing: 8) {
                        Text("7-day free trial, then \(selectedProduct?.id == "baby.annual" ? "$19.99/year" : "$3.99/month")")
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
        .onAppear {
            // Set default selection to annual plan
            if selectedProduct == nil && !subscriptionService.availableProducts.isEmpty {
                selectedProduct = subscriptionService.product(for: .annual) ?? subscriptionService.availableProducts.first
            }
            
            // Initialize subscription service if needed
            Task {
                await subscriptionService.initialize()
            }
        }
        .sheet(isPresented: $showParentGate) {
            ParentGateView(
                isPresented: $showParentGate,
                context: parentGateContext,
                onSuccess: {
                    Task {
                        await handleParentGateSuccess()
                    }
                }
            )
        }
        .alert("Subscription Error", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func handleParentGateSuccess() async {
        switch parentGateContext {
        case .paywall:
            await purchaseSubscription()
        case .restore:
            await restorePurchases()
        default:
            break
        }
    }
    
    private func purchaseSubscription() async {
        guard let product = selectedProduct else {
            showError("Please select a subscription plan")
            return
        }
        
        do {
            let transaction = try await subscriptionService.purchase(product)
            print("[PaywallView] Purchase successful: \(transaction.productID)")
            isPresented = false
        } catch SubscriptionError.userCancelled {
            // User cancelled, no need to show error
            print("[PaywallView] Purchase cancelled by user")
        } catch {
            print("[PaywallView] Purchase error: \(error)")
            showError(error.localizedDescription)
        }
    }
    
    private func restorePurchases() async {
        do {
            try await subscriptionService.restorePurchases()
            print("[PaywallView] Restore successful")
            isPresented = false
        } catch {
            print("[PaywallView] Restore error: \(error)")
            showError(error.localizedDescription)
        }
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showAlert = true
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