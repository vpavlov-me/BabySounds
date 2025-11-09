import Combine
import Foundation
import StoreKit

// MARK: - SubscriptionProduct

// swiftlint:disable:next no_hardcoded_strings
public enum SubscriptionProduct: String, CaseIterable {
    case monthly = "baby.monthly" // swiftlint:disable:this no_hardcoded_strings
    case annual = "baby.annual" // swiftlint:disable:this no_hardcoded_strings

    public var displayName: String {
        switch self {
        case .monthly:
            return NSLocalizedString("subscription_monthly_name", comment: "Monthly subscription name")

        case .annual:
            return NSLocalizedString("subscription_annual_name", comment: "Annual subscription name")
        }
    }

    public var trialDays: Int {
        7 // 7-day trial for both plans
    }
}

// MARK: - SubscriptionStatus

public enum SubscriptionStatus {
    case notSubscribed
    case subscribed(Product, Transaction)
    case expired(Product, Transaction)
    case inTrialPeriod(Product, Transaction)
    case inGracePeriod(Product, Transaction)
    case pending(Product)

    public var isActive: Bool {
        switch self {
        case .inGracePeriod, .inTrialPeriod, .subscribed:
            return true

        case .expired, .notSubscribed, .pending:
            return false
        }
    }

    public var product: Product? {
        switch self {
        case let .expired(product, _),
             let .inGracePeriod(product, _),
             let .inTrialPeriod(product, _),
             let .pending(product),
             let .subscribed(product, _):
            return product

        case .notSubscribed:
            return nil
        }
    }
}

// MARK: - SubscriptionError

public enum SubscriptionError: LocalizedError {
    case storeKitNotAvailable
    case productNotFound(String)
    case purchaseFailed(String)
    case restoreFailed(String)
    case receiptValidationFailed
    case networkError
    case userCancelled

    public var errorDescription: String? {
        switch self {
        case .storeKitNotAvailable:
            return NSLocalizedString("subscription_error_storekit_unavailable", comment: "StoreKit not available")

        case let .productNotFound(productId):
            return NSLocalizedString("subscription_error_product_not_found", comment: "Product not found")

        case let .purchaseFailed(reason):
            return String(
                format: NSLocalizedString("subscription_error_purchase_failed", comment: "Purchase failed"),
                reason
            )

        case let .restoreFailed(reason):
            return String(
                format: NSLocalizedString("subscription_error_restore_failed", comment: "Restore failed"),
                reason
            )

        case .receiptValidationFailed:
            return NSLocalizedString(
                "subscription_error_receipt_validation_failed",
                comment: "Receipt validation failed"
            )

        case .networkError:
            return NSLocalizedString("subscription_error_network", comment: "Network error")

        case .userCancelled:
            return NSLocalizedString("subscription_error_user_cancelled", comment: "User cancelled")
        }
    }
}

// MARK: - SubscriptionServiceSK2

@MainActor
public class SubscriptionServiceSK2: ObservableObject {
    public static let shared = SubscriptionServiceSK2()

    // MARK: - Published Properties

    @Published public var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published public var availableProducts: [Product] = []
    @Published public var isLoading = false
    @Published public var lastError: SubscriptionError?

    // MARK: - Private Properties

    private var productsLoaded = false
    private var transactionUpdateTask: Task<Void, Never>?

    private init() {
        startTransactionObserver()
    }

    deinit {
        transactionUpdateTask?.cancel()
    }

    // MARK: - Public Methods

    /// Initialize the subscription service
    public func initialize() async {
        await loadProducts()
        await updateSubscriptionStatus()
    }

    /// Load available subscription products from App Store
    public func loadProducts() async {
        guard !productsLoaded else { return }

        isLoading = true
        defer { isLoading = false }

        do {
            let productIds = SubscriptionProduct.allCases.map { $0.rawValue }
            let products = try await Product.products(for: productIds)

            // Sort products: monthly first, then annual
            let sortedProducts = products.sorted { product1, product2 in
                if product1.id == SubscriptionProduct.monthly.rawValue {
                    return true
                } else if product2.id == SubscriptionProduct.monthly.rawValue {
                    return false
                } else {
                    return product1.price < product2.price
                }
            }

            availableProducts = sortedProducts
            productsLoaded = true
            lastError = nil

            print("[SubscriptionService] Loaded \(products.count) products")
        } catch {
            print("[SubscriptionService] Failed to load products: \(error)")
            lastError = .productNotFound("Failed to load products")
        }
    }

    /// Purchase a subscription
    public func purchase(_ product: Product) async throws -> Transaction {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    await transaction.finish()
                    await updateSubscriptionStatus()
                    lastError = nil
                    print("[SubscriptionService] Purchase successful: \(transaction.productID)")
                    return transaction

                case let .unverified(transaction, error):
                    await transaction.finish()
                    print("[SubscriptionService] Purchase unverified: \(error)")
                    throw SubscriptionError.receiptValidationFailed
                }

            case .userCancelled:
                print("[SubscriptionService] Purchase cancelled by user")
                throw SubscriptionError.userCancelled

            case .pending:
                print("[SubscriptionService] Purchase pending")
                // Update status to show pending state
                if let subscriptionProduct = SubscriptionProduct(rawValue: product.id) {
                    subscriptionStatus = .pending(product)
                }
                throw SubscriptionError.purchaseFailed("Purchase is pending approval")

            @unknown default:
                print("[SubscriptionService] Unknown purchase result")
                throw SubscriptionError.purchaseFailed("Unknown error occurred")
            }
        } catch let error as SubscriptionError {
            lastError = error
            throw error
        } catch {
            print("[SubscriptionService] Purchase error: \(error)")
            let subscriptionError = SubscriptionError.purchaseFailed(error.localizedDescription)
            lastError = subscriptionError
            throw subscriptionError
        }
    }

    /// Restore previous purchases
    public func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await updateSubscriptionStatus()
            lastError = nil
            print("[SubscriptionService] Restore purchases completed")
        } catch {
            print("[SubscriptionService] Restore failed: \(error)")
            let subscriptionError = SubscriptionError.restoreFailed(error.localizedDescription)
            lastError = subscriptionError
            throw subscriptionError
        }
    }

    /// Get product by subscription type
    public func product(for subscription: SubscriptionProduct) -> Product? {
        availableProducts.first { $0.id == subscription.rawValue }
    }

    /// Get formatted price for product
    public func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }

    /// Get trial information
    public func trialInfo(for product: Product) -> String? {
        guard let subscriptionProduct = SubscriptionProduct(rawValue: product.id) else { return nil }

        let trialDays = subscriptionProduct.trialDays
        if trialDays > 0 {
            return String(format: NSLocalizedString("subscription_trial_info", comment: "Trial info"), trialDays)
        }
        return nil
    }

    /// Check if user has active subscription
    public var hasActiveSubscription: Bool {
        subscriptionStatus.isActive
    }

    /// Get current subscription product
    public var currentSubscriptionProduct: SubscriptionProduct? {
        guard let product = subscriptionStatus.product else { return nil }
        return SubscriptionProduct(rawValue: product.id)
    }

    // MARK: - Private Methods

    /// Start observing transaction updates
    private func startTransactionObserver() {
        transactionUpdateTask = Task.detached { [weak self] in
            for await result in Transaction.updates {
                await self?.handleTransactionUpdate(result)
            }
        }
    }

    /// Handle transaction updates
    private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
        switch result {
        case let .verified(transaction):
            await transaction.finish()
            await updateSubscriptionStatus()
            print("[SubscriptionService] Transaction updated: \(transaction.productID)")

        case let .unverified(transaction, error):
            await transaction.finish()
            print("[SubscriptionService] Unverified transaction: \(error)")
        }
    }

    /// Update subscription status based on current entitlements
    private func updateSubscriptionStatus() async {
        var currentEntitlement: Transaction?
        var currentProduct: Product?

        // Check all subscription products for current entitlements
        for await result in Transaction.currentEntitlements {
            switch result {
            case let .verified(transaction):
                // Only consider subscription products
                if SubscriptionProduct.allCases.map({ $0.rawValue }).contains(transaction.productID) {
                    if let product = availableProducts.first(where: { $0.id == transaction.productID }) {
                        currentEntitlement = transaction
                        currentProduct = product
                        break
                    }
                }

            case let .unverified(transaction, error):
                print("[SubscriptionService] Unverified entitlement: \(error)")
            }
        }

        // Update status based on entitlement
        if let transaction = currentEntitlement,
           let product = currentProduct
        {
            let now = Date()

            // Check if subscription is still valid
            if let expirationDate = transaction.expirationDate {
                if now < expirationDate {
                    // Check if in trial period
                    if let originalPurchaseDate = transaction.originalPurchaseDate {
                        let trialEndDate = Calendar.current.date(byAdding: .day,
                                                                 value: SubscriptionProduct(rawValue: product.id)?
                                                                     .trialDays ?? 0,
                                                                 to: originalPurchaseDate) ?? originalPurchaseDate
                        if now < trialEndDate {
                            subscriptionStatus = .inTrialPeriod(product, transaction)
                        } else {
                            subscriptionStatus = .subscribed(product, transaction)
                        }
                    } else {
                        subscriptionStatus = .subscribed(product, transaction)
                    }
                } else {
                    subscriptionStatus = .expired(product, transaction)
                }
            } else {
                // No expiration date means it's active
                subscriptionStatus = .subscribed(product, transaction)
            }
        } else {
            subscriptionStatus = .notSubscribed
        }

        print("[SubscriptionService] Subscription status updated: \(subscriptionStatus)")
    }
}

// MARK: - Extensions

extension Product {
    var subscriptionProduct: SubscriptionProduct? {
        SubscriptionProduct(rawValue: id)
    }
}

extension Transaction {
    var subscriptionProduct: SubscriptionProduct? {
        SubscriptionProduct(rawValue: productID)
    }
}
