import StoreKit
import SwiftUI

struct SubscriptionCardStoreKit: View {
    let product: Product
    let isSelected: Bool
    let subscriptionService: SubscriptionServiceSK2
    let action: () -> Void
    
    private var subscriptionProduct: SubscriptionProduct? {
        SubscriptionProduct(rawValue: product.id)
    }
    
    private var savings: String? {
        guard let subscriptionProduct = subscriptionProduct,
              subscriptionProduct == .annual else { return nil }
        
        // Calculate savings vs monthly plan
        if let monthlyProduct = subscriptionService.product(for: .monthly) {
            let monthlyAnnualPrice = monthlyProduct.price * 12
            let annualPrice = product.price
            let savingsAmount = monthlyAnnualPrice - annualPrice
            let savingsPercentage = (savingsAmount / monthlyAnnualPrice) * 100
            
            if savingsPercentage > 0 {
                return String(format: "Save %.0f%%", savingsPercentage)
            }
        }
        
        return nil
    }
    
    private var displayTitle: String {
        subscriptionProduct?.displayName ?? product.displayName
    }
    
    private var trialText: String? {
        subscriptionService.trialInfo(for: product)
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(displayTitle)
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
                    
                    Text(subscriptionService.formattedPrice(for: product))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    if let trialText = trialText {
                        Text(trialText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isSelected ? .blue : .gray)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#if DEBUG
struct SubscriptionCardStoreKit_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            SubscriptionCardStoreKit(
                product: MockProduct.monthly,
                isSelected: false,
                subscriptionService: SubscriptionServiceSK2.shared
            )                {}
            
            SubscriptionCardStoreKit(
                product: MockProduct.annual,
                isSelected: true,
                subscriptionService: SubscriptionServiceSK2.shared
            )                {}
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// Mock Product for Previews
private struct MockProduct {
    static let monthly = MockStoreKitProduct(
        id: "baby.monthly",
        displayName: "Monthly Premium",
        displayPrice: "$4.99",
        price: 4.99
    )
    
    static let annual = MockStoreKitProduct(
        id: "baby.annual",
        displayName: "Annual Premium",
        displayPrice: "$29.99",
        price: 29.99
    )
}

private class MockStoreKitProduct: Product {
    private let _id: String
    private let _displayName: String
    private let _displayPrice: String
    private let _price: Decimal
    
    init(id: String, displayName: String, displayPrice: String, price: Decimal) {
        self._id = id
        self._displayName = displayName
        self._displayPrice = displayPrice
        self._price = price
    }
    
    override var id: String { _id }
    override var displayName: String { _displayName }
    override var displayPrice: String { _displayPrice }
    override var price: Decimal { _price }
}
#endif
