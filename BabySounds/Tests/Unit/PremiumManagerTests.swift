import XCTest
@testable import BabySounds

@MainActor
final class PremiumManagerTests: XCTestCase {
    var sut: PremiumManager!

    override func setUp() async throws {
        sut = PremiumManager.shared
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Feature Access Tests

    func testFreeUserCannotAccessPremiumSounds() {
        // Given - assume user is not premium (default state)

        // When
        let canPlayPremium = sut.canPlayPremiumSound()

        // Then
        XCTAssertFalse(canPlayPremium,
                       "Free users should not access premium sounds")
    }

    func testFreeUserHasLimitedFavorites() {
        // Given
        let freeFavoritesCount = 3

        // When
        let canAddMore = sut.canAddFavorite(currentCount: freeFavoritesCount)

        // Then
        XCTAssertTrue(canAddMore,
                      "Free users should be able to add favorites under limit")
    }

    func testFreeUserCannotExceedFavoriteLimit() {
        // Given
        let maxFreeCount = PremiumManager.Limits.maxFavoritesForFree

        // When
        let canAddMore = sut.canAddFavorite(currentCount: maxFreeCount)

        // Then
        XCTAssertFalse(canAddMore,
                       "Free users should not exceed \(maxFreeCount) favorites")
    }

    func testFreeUserHasTimerLimit() {
        // Given
        let freeTimerMax = PremiumManager.Limits.maxTimerMinutesForFree

        // When
        let canUseExtended = sut.canUseTimerMinutes(45)

        // Then
        XCTAssertFalse(canUseExtended,
                       "Free users should be limited to \(freeTimerMax) minutes")
    }

    func testFreeUserCanUseBasicTimer() {
        // Given
        let basicTimerMinutes = 15

        // When
        let canUse = sut.canUseTimerMinutes(basicTimerMinutes)

        // Then
        XCTAssertTrue(canUse,
                      "Free users should use timers within limit")
    }

    // MARK: - Premium Gate Tests

    func testPremiumSoundShowsPaywall() {
        // Given
        let feature = PremiumManager.PremiumFeature.premiumSounds

        // When
        let action = sut.gateFeature(feature)

        // Then
        if case .showPaywall = action {
            XCTAssert(true, "Premium sounds should show paywall")
        } else {
            XCTFail("Expected showPaywall action")
        }
    }

    func testMultiTrackMixingShowsPaywall() {
        // Given
        let feature = PremiumManager.PremiumFeature.multiTrackMixing

        // When
        let action = sut.gateFeature(feature)

        // Then
        if case .showPaywall = action {
            XCTAssert(true, "Multi-track mixing should show paywall")
        } else {
            XCTFail("Expected showPaywall action")
        }
    }

    func testExtendedTimerShowsMessage() {
        // Given
        let feature = PremiumManager.PremiumFeature.extendedTimer

        // When
        let action = sut.gateFeature(feature)

        // Then
        if case let .showMessage(message) = action {
            XCTAssertFalse(message.isEmpty,
                           "Timer gate should show informative message")
        } else {
            XCTFail("Expected showMessage action")
        }
    }

    // MARK: - Feature Limits Tests

    func testFreeUserSingleTrackLimit() {
        // Given
        let currentTracks = 1
        let maxFreeTracks = PremiumManager.Limits.maxSimultaneousTracksForFree

        // When
        let canAddMore = sut.canPlaySimultaneousTracks(currentTracks + 1)

        // Then
        XCTAssertFalse(canAddMore,
                       "Free users limited to \(maxFreeTracks) simultaneous track(s)")
    }

    func testFreeUserNoGainAdjustment() {
        // Given
        let requestedGain: Float = 3.0
        let maxFreeGain = PremiumManager.Limits.maxGainAdjustmentForFree

        // When
        let allowedGain = sut.allowedGainAdjustment(requestedGain)

        // Then
        XCTAssertEqual(allowedGain, maxFreeGain,
                       "Free users should have no gain adjustment")
    }

    func testFreeUserNoPanAdjustment() {
        // Given
        let requestedPan: Float = 0.5
        let maxFreePan = PremiumManager.Limits.maxPanAdjustmentForFree

        // When
        let allowedPan = sut.allowedPanAdjustment(requestedPan)

        // Then
        XCTAssertEqual(allowedPan, maxFreePan,
                       "Free users should have no pan adjustment")
    }

    // MARK: - Feature Info Tests

    func testAllFeaturesHaveNames() {
        // When/Then
        for feature in PremiumManager.PremiumFeature.allCases {
            XCTAssertFalse(feature.localizedName.isEmpty,
                           "\(feature) should have a localized name")
        }
    }

    func testAllFeaturesHaveDescriptions() {
        // When/Then
        for feature in PremiumManager.PremiumFeature.allCases {
            XCTAssertFalse(feature.description.isEmpty,
                           "\(feature) should have a description")
        }
    }

    func testAllFeaturesHaveIcons() {
        // When/Then
        for feature in PremiumManager.PremiumFeature.allCases {
            XCTAssertFalse(feature.icon.isEmpty,
                           "\(feature) should have an icon")
        }
    }
}
