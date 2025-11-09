import XCTest
@testable import BabySounds

@MainActor
final class SafeVolumeManagerTests: XCTestCase {
    var sut: SafeVolumeManager!

    override func setUp() async throws {
        // Create a fresh instance for each test
        sut = SafeVolumeManager.shared
        // Reset to defaults
        sut.setVolumeLimit(0.75)
        sut.setEnabled(true)
    }

    override func tearDown() async throws {
        sut = nil
    }

    // MARK: - Volume Limit Tests

    func testVolumeLimitApplied() {
        // Given
        sut.setVolumeLimit(0.5)

        // When
        let safeVolume = sut.applySafeVolume(to: 1.0)

        // Then
        XCTAssertEqual(safeVolume, 0.5, "Safe volume should match the limit")
    }

    func testVolumeBelowLimitUnchanged() {
        // Given
        sut.setVolumeLimit(0.75)

        // When
        let safeVolume = sut.applySafeVolume(to: 0.5)

        // Then
        XCTAssertEqual(safeVolume, 0.5, "Volume below limit should not be changed")
    }

    func testSafeVolumeDisabled() {
        // Given
        sut.setEnabled(false)

        // When
        let safeVolume = sut.applySafeVolume(to: 1.0)

        // Then
        XCTAssertEqual(safeVolume, 1.0, "Volume should not be limited when disabled")
    }

    // MARK: - WHO Compliance Tests

    func testWHOVolumeLimitNotExceeded() {
        // Given
        let maxSafeVolume: Float = 0.75 // 75% per WHO guidelines

        // When
        sut.setVolumeLimit(1.0) // Try to set higher
        let actualLimit = sut.currentVolumeLimit

        // Then
        XCTAssertLessThanOrEqual(actualLimit, maxSafeVolume,
                                 "Volume limit should not exceed WHO safe level")
    }

    func testListeningTimeTracking() async {
        // Given
        sut.startListeningSession()

        // When
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertGreaterThan(sut.currentSessionDuration, 0,
                             "Session duration should be tracked")
    }

    func testListeningSessionEnds() {
        // Given
        sut.startListeningSession()
        let initialDuration = sut.currentSessionDuration

        // When
        sut.endListeningSession()

        // Then
        XCTAssertEqual(sut.currentSessionDuration, 0,
                       "Session duration should reset after ending")
    }

    // MARK: - Headphone Safety Tests

    func testHeadphoneModeReducesVolume() {
        // Given
        sut.setHeadphonesConnected(true)
        sut.setVolumeLimit(0.75)

        // When
        let safeVolume = sut.applySafeVolume(to: 1.0)

        // Then
        XCTAssertLessThan(safeVolume, 0.75,
                          "Headphone mode should reduce volume below speaker limit")
    }

    // MARK: - Volume Conversion Tests

    func testDbToLinearConversion() {
        // Given
        let zeroDb: Float = 0.0

        // When
        let linear = sut.convertFromDb(zeroDb)

        // Then
        XCTAssertEqual(linear, 1.0, accuracy: 0.01,
                       "0 dB should equal linear volume of 1.0")
    }

    func testLinearToDbConversion() {
        // Given
        let fullVolume: Float = 1.0

        // When
        let db = sut.convertToDb(fullVolume)

        // Then
        XCTAssertEqual(db, 0.0, accuracy: 0.01,
                       "Linear 1.0 should equal 0 dB")
    }

    func testNegativeDbReducesVolume() {
        // Given
        let minusSixDb: Float = -6.0

        // When
        let linear = sut.convertFromDb(minusSixDb)

        // Then
        XCTAssertLessThan(linear, 1.0,
                          "Negative dB should result in volume < 1.0")
        XCTAssertGreaterThan(linear, 0.0,
                             "Negative dB should still be audible")
    }
}
