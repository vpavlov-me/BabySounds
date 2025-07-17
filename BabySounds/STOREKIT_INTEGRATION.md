# StoreKit 2 Integration Guide

## Overview

This document describes the complete StoreKit 2 subscription implementation for the Baby Sounds app. The integration includes two subscription products with 7-day free trials and comprehensive subscription management.

## Product Configuration

### Subscription Products
- **Monthly Plan**: `baby.monthly` - $4.99/month
- **Annual Plan**: `baby.annual` - $29.99/year (Save ~50%)
- **Trial Period**: 7 days free for both plans
- **Subscription Group**: `BabySoundsPremium` (ID: 21548343)

### Product Features
Both subscription plans include:
- ✅ 50+ Premium Sounds
- ✅ Multi-Track Mixing (up to 4 sounds)
- ✅ Extended Timer (up to 12 hours)
- ✅ Sleep Schedules
- ✅ Offline Packs
- ✅ Advanced Controls (gain, pan, fade)
- ✅ Unlimited Favorites
- ✅ Dark Night Mode

## Architecture

### Core Components

#### 1. SubscriptionServiceSK2
**Location**: `BabySounds/Subscriptions/SubscriptionServiceSK2.swift`

Main subscription service using StoreKit 2 with singleton pattern:
```swift
@MainActor
public class SubscriptionServiceSK2: ObservableObject {
    public static let shared = SubscriptionServiceSK2()
    
    // Published state
    @Published public var subscriptionStatus: SubscriptionStatus
    @Published public var availableProducts: [Product]
    @Published public var isLoading: Bool
    @Published public var lastError: SubscriptionError?
}
```

**Key Methods**:
- `initialize()` - Load products and check subscription status
- `purchase(_ product: Product)` - Purchase subscription with parent gate
- `restorePurchases()` - Restore previous purchases
- `hasActiveSubscription` - Check if user has valid subscription

#### 2. SubscriptionStatus Enum
Comprehensive status tracking:
```swift
public enum SubscriptionStatus {
    case notSubscribed
    case subscribed(Product, Transaction)
    case expired(Product, Transaction)
    case inTrialPeriod(Product, Transaction)
    case inGracePeriod(Product, Transaction)
    case pending(Product)
}
```

#### 3. PremiumManager Integration
**Location**: `BabySounds/Data/PremiumManager.swift`

Updated to use new StoreKit 2 service:
```swift
public func hasAccess(to feature: PremiumFeature) -> Bool {
    return subscriptionService.hasActiveSubscription
}
```

#### 4. PaywallView Updates
**Location**: `BabySounds/Views/PaywallView.swift`

- Real StoreKit product integration
- Dynamic pricing display
- Trial information
- Loading states
- Error handling
- Parent gate protection

#### 5. SubscriptionCardStoreKit Component
**Location**: `BabySounds/Views/SubscriptionCardStoreKit.swift`

New component for displaying real Product objects with:
- Dynamic pricing from StoreKit
- Automatic savings calculation
- Trial period display
- Selection states

## Configuration Files

### 1. StoreKit Configuration
**Location**: `BabySounds/StoreKit Configuration.storekit`

Development configuration with:
- Product IDs: `baby.monthly`, `baby.annual`
- 7-day free trial setup
- Pricing configuration
- Subscription group setup

### 2. Info.plist Update
Added StoreKit configuration reference:
```xml
<key>SKStoreKitConfiguration</key>
<string>StoreKit Configuration</string>
```

### 3. Localization
**English** (`Localizable.strings`):
```
"subscription_monthly_name" = "Monthly Premium";
"subscription_annual_name" = "Annual Premium";
"subscription_trial_info" = "%d-day free trial";
```

**Russian** (`ru.lproj/Localizable.strings`):
```
"subscription_monthly_name" = "Ежемесячная премиум-подписка";
"subscription_annual_name" = "Годовая премиум-подписка";
"subscription_trial_info" = "%d дней бесплатно";
```

## Usage Flow

### 1. App Initialization
```swift
// BabySoundsApp.swift
@StateObject private var subscriptionService = SubscriptionServiceSK2.shared

.onAppear {
    Task {
        await subscriptionService.initialize()
    }
}
```

### 2. Purchase Flow
1. User taps subscription plan in PaywallView
2. Parent gate appears for verification
3. After parent gate success, purchase is initiated
4. StoreKit 2 handles the transaction
5. Receipt validation and status update
6. UI updates with premium access

### 3. Restore Flow
1. User taps "Restore Purchases"
2. Parent gate verification
3. StoreKit sync and entitlement check
4. Status update and UI refresh

### 4. Premium Feature Access
```swift
// Check access in any view
if premiumManager.hasAccess(to: .premiumSounds) {
    // Show premium content
} else {
    // Show premium gate or paywall
}
```

## Child Safety Features

### 1. Parent Gate Protection
- Required for all subscription actions
- Math challenges for purchases
- Reading challenges for restore
- Attempt limiting and timeouts

### 2. COPPA Compliance
- No personal data collection
- Parental consent for purchases
- Safe external link handling
- Minimal analytics

## Error Handling

### Subscription Errors
```swift
public enum SubscriptionError: LocalizedError {
    case storeKitNotAvailable
    case productNotFound(String)
    case purchaseFailed(String)
    case restoreFailed(String)
    case receiptValidationFailed
    case networkError
    case userCancelled
}
```

### Error Recovery
- Automatic retry on network errors
- User-friendly error messages
- Fallback states for loading failures
- Debug logging for troubleshooting

## Testing

### 1. Development Testing
- Use StoreKit Configuration file
- Test both subscription plans
- Verify trial periods
- Test restore functionality
- Parent gate integration

### 2. TestFlight Testing
- Real App Store environment
- Actual payment processing
- Receipt validation
- Cross-device sync testing

### 3. Production Testing
- Monitor subscription metrics
- Track conversion rates
- Error rate monitoring
- Customer support integration

## App Store Connect Setup

### Required Steps
1. **Create Subscription Group**: "BabySoundsPremium"
2. **Add Products**:
   - Monthly: `baby.monthly` ($4.99/month)
   - Annual: `baby.annual` ($29.99/year)
3. **Configure Trials**: 7-day free trial for both
4. **Set Availability**: All territories
5. **Review Guidelines**: Kids Category compliance
6. **Tax Setup**: Configure appropriate tax categories

### Metadata Requirements
- Clear subscription terms
- Trial period disclosure
- Feature descriptions
- Privacy policy updates
- Age-appropriate content rating

## Monitoring & Analytics

### Key Metrics
- Trial conversion rates
- Subscription retention
- Feature usage by tier
- Parent gate completion rates
- Error rates and types

### Debug Information
Available in DataDebugView:
- Current subscription status
- Product availability
- Trial/premium state
- Error logs

## Security Considerations

### 1. Receipt Validation
- Local StoreKit 2 validation
- Transaction verification
- Automatic receipt refresh
- Secure transaction handling

### 2. Premium Content Protection
- Server-side validation (future)
- Regular entitlement checks
- Graceful degradation
- Offline mode handling

## Future Enhancements

### Planned Features
1. **Family Sharing**: Enable family plan support
2. **Promotional Offers**: Seasonal discounts
3. **Server Validation**: Enhanced security
4. **Analytics**: Detailed subscription metrics
5. **A/B Testing**: Paywall optimization

### Technical Debt
- Add comprehensive unit tests
- Implement subscription analytics
- Server-side receipt validation
- Enhanced error recovery

## Support

### Common Issues
1. **Products not loading**: Check network, StoreKit config
2. **Purchase fails**: Verify payment methods, parent restrictions
3. **Restore doesn't work**: Check Apple ID, previous purchases
4. **Premium features locked**: Check subscription status, restart app

### Debug Tools
- DataDebugView for real-time status
- Console logs with [SubscriptionService] prefix
- Parent gate test modes
- StoreKit transaction log

---

**Last Updated**: Task 6 Implementation
**Next Task**: Task 7 - Safe Volume / Child Safety 