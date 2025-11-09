import XCTest
@testable import BabySounds

@MainActor
final class SleepScheduleTests: XCTestCase {
    // MARK: - Model Tests

    func testScheduleCreatedWithDefaults() {
        // When
        let schedule = SleepSchedule()

        // Then
        XCTAssertEqual(schedule.name, "My Sleep Schedule")
        XCTAssertTrue(schedule.isEnabled)
        XCTAssertEqual(schedule.selectedDays.count, 7, "Should default to all days")
        XCTAssertEqual(schedule.reminderMinutes, 30)
        XCTAssertEqual(schedule.autoFadeMinutes, 45)
    }

    func testScheduleWithCustomData() {
        // Given
        let customName = "Weekend Schedule"
        let customDays: Set<Weekday> = [.saturday, .sunday]

        // When
        let schedule = SleepSchedule(
            name: customName,
            selectedDays: customDays
        )

        // Then
        XCTAssertEqual(schedule.name, customName)
        XCTAssertEqual(schedule.selectedDays, customDays)
    }

    // MARK: - Next Bedtime Calculation Tests

    func testNextBedTimeCalculation() {
        // Given
        let calendar = Calendar.current
        let today = Date()
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        let bedtimeHour = 20
        let bedTime = calendar.date(bySettingHour: bedtimeHour, minute: 0, second: 0, of: today)!

        let schedule = SleepSchedule(
            bedTime: bedTime,
            selectedDays: Set(Weekday.allCases)
        )

        // When
        let nextBedTime = schedule.nextBedTime

        // Then
        XCTAssertNotNil(nextBedTime, "Should calculate next bedtime")

        if let next = nextBedTime {
            let components = calendar.dateComponents([.hour], from: next)
            XCTAssertEqual(components.hour, bedtimeHour,
                           "Next bedtime should be at scheduled hour")
        }
    }

    func testDisabledScheduleHasNoNextBedtime() {
        // Given
        var schedule = SleepSchedule()
        schedule.isEnabled = false

        // When
        let nextBedTime = schedule.nextBedTime

        // Then
        XCTAssertNil(nextBedTime,
                     "Disabled schedule should have no next bedtime")
    }

    func testEmptyDaysHasNoNextBedtime() {
        // Given
        let schedule = SleepSchedule(selectedDays: [])

        // When
        let nextBedTime = schedule.nextBedTime

        // Then
        XCTAssertNil(nextBedTime,
                     "Schedule with no days should have no next bedtime")
    }

    // MARK: - Formatted Time Tests

    func testFormattedBedTime() {
        // Given
        let calendar = Calendar.current
        let bedTime = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: Date())!
        let schedule = SleepSchedule(bedTime: bedTime)

        // When
        let formatted = schedule.formattedBedTime

        // Then
        XCTAssertFalse(formatted.isEmpty, "Should format bedtime")
        XCTAssertTrue(formatted.contains("20") || formatted.contains("8"),
                      "Should contain hour")
    }

    func testFormattedWakeTime() {
        // Given
        let calendar = Calendar.current
        let wakeTime = calendar.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
        let schedule = SleepSchedule(wakeTime: wakeTime)

        // When
        let formatted = schedule.formattedWakeTime

        // Then
        XCTAssertFalse(formatted.isEmpty, "Should format wake time")
        XCTAssertTrue(formatted.contains("7"),
                      "Should contain hour")
    }

    // MARK: - Selected Days Text Tests

    func testAllDaysText() {
        // Given
        let schedule = SleepSchedule(selectedDays: Set(Weekday.allCases))

        // When
        let text = schedule.selectedDaysText

        // Then
        XCTAssertEqual(text, "Every day")
    }

    func testWeekdaysText() {
        // Given
        let weekdays: Set<Weekday> = [.monday, .tuesday, .wednesday, .thursday, .friday]
        let schedule = SleepSchedule(selectedDays: weekdays)

        // When
        let text = schedule.selectedDaysText

        // Then
        XCTAssertEqual(text, "Weekdays")
    }

    func testWeekendsText() {
        // Given
        let weekends: Set<Weekday> = [.saturday, .sunday]
        let schedule = SleepSchedule(selectedDays: weekends)

        // When
        let text = schedule.selectedDaysText

        // Then
        XCTAssertEqual(text, "Weekends")
    }

    func testCustomDaysText() {
        // Given
        let customDays: Set<Weekday> = [.monday, .wednesday, .friday]
        let schedule = SleepSchedule(selectedDays: customDays)

        // When
        let text = schedule.selectedDaysText

        // Then
        XCTAssertTrue(text.contains("Mon"))
        XCTAssertTrue(text.contains("Wed"))
        XCTAssertTrue(text.contains("Fri"))
    }

    // MARK: - Notification ID Tests

    func testUniqueNotificationIds() {
        // Given
        let schedule1 = SleepSchedule()
        let schedule2 = SleepSchedule()

        // Then
        XCTAssertNotEqual(schedule1.reminderNotificationId,
                          schedule2.reminderNotificationId,
                          "Different schedules should have unique reminder IDs")

        XCTAssertNotEqual(schedule1.bedtimeNotificationId,
                          schedule2.bedtimeNotificationId,
                          "Different schedules should have unique bedtime IDs")
    }

    func testNotificationIdFormat() {
        // Given
        let schedule = SleepSchedule()

        // Then
        XCTAssertTrue(schedule.reminderNotificationId.contains("reminder"),
                      "Reminder ID should contain 'reminder'")
        XCTAssertTrue(schedule.bedtimeNotificationId.contains("bedtime"),
                      "Bedtime ID should contain 'bedtime'")
    }

    // MARK: - Weekday Tests

    func testWeekdayNames() {
        XCTAssertEqual(Weekday.monday.name, "Monday")
        XCTAssertEqual(Weekday.sunday.name, "Sunday")
    }

    func testWeekdayShortNames() {
        XCTAssertEqual(Weekday.monday.shortName, "Mon")
        XCTAssertEqual(Weekday.sunday.shortName, "Sun")
    }

    func testWeekdaySorting() {
        // Given
        let unsorted: [Weekday] = [.sunday, .wednesday, .monday]

        // When
        let sorted = unsorted.sorted()

        // Then
        XCTAssertEqual(sorted.first, .monday,
                       "Monday should be first when sorted")
        XCTAssertEqual(sorted.last, .sunday,
                       "Sunday should be last when sorted")
    }

    // MARK: - Error Tests

    func testScheduleErrors() {
        XCTAssertNotNil(SleepScheduleError.notificationPermissionDenied.errorDescription)
        XCTAssertNotNil(SleepScheduleError.invalidTimeConfiguration.errorDescription)
        XCTAssertNotNil(SleepScheduleError.scheduleNotFound.errorDescription)
        XCTAssertNotNil(SleepScheduleError.maxSchedulesReached.errorDescription)
    }
}
