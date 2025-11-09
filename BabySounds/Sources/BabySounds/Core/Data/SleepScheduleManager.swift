import Foundation
import SwiftUI
import UserNotifications

// MARK: - SleepScheduleManager

@MainActor
class SleepScheduleManager: ObservableObject {
    static let shared = SleepScheduleManager()

    // MARK: - Published Properties

    @Published var schedules: [SleepSchedule] = []
    @Published var isNotificationPermissionGranted = false
    @Published var isLoadingSchedules = false
    @Published var lastError: Error?

    // MARK: - Constants

    private let maxFreeSchedules = 1 // Free tier allows only 1 schedule
    private let userDefaultsKey = "SavedSleepSchedules"

    // MARK: - Dependencies

    private let premiumManager = PremiumManager.shared
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Initialization

    private init() {
        loadSchedules()
        checkNotificationPermission()

        // Listen to premium status changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(premiumStatusChanged),
            name: NSNotification.Name("PremiumStatusChanged"),
            object: nil
        )
    }

    // MARK: - Schedule Management

    func addSchedule(_ schedule: SleepSchedule) async throws {
        // Check premium limits
        if !premiumManager.hasFeature(.sleepSchedules), schedules.count >= maxFreeSchedules {
            throw SleepScheduleError.maxSchedulesReached
        }

        var newSchedule = schedule
        newSchedule.lastModified = Date()

        schedules.append(newSchedule)
        saveSchedules()

        if newSchedule.isEnabled {
            try await scheduleNotifications(for: newSchedule)
        }

        print("✅ [SleepScheduleManager] Added schedule: \(newSchedule.name)")
    }

    func updateSchedule(_ schedule: SleepSchedule) async throws {
        guard let index = schedules.firstIndex(where: { $0.id == schedule.id }) else {
            throw SleepScheduleError.scheduleNotFound
        }

        var updatedSchedule = schedule
        updatedSchedule.lastModified = Date()

        // Remove old notifications
        await removeNotifications(for: schedules[index])

        schedules[index] = updatedSchedule
        saveSchedules()

        if updatedSchedule.isEnabled {
            try await scheduleNotifications(for: updatedSchedule)
        }

        print("✅ [SleepScheduleManager] Updated schedule: \(updatedSchedule.name)")
    }

    func deleteSchedule(_ schedule: SleepSchedule) async {
        await removeNotifications(for: schedule)
        schedules.removeAll { $0.id == schedule.id }
        saveSchedules()

        print("🗑️ [SleepScheduleManager] Deleted schedule: \(schedule.name)")
    }

    func toggleSchedule(_ schedule: SleepSchedule) async throws {
        var updatedSchedule = schedule
        updatedSchedule.isEnabled.toggle()
        updatedSchedule.lastModified = Date()

        if updatedSchedule.isEnabled {
            try await scheduleNotifications(for: updatedSchedule)
        } else {
            await removeNotifications(for: updatedSchedule)
        }

        try await updateSchedule(updatedSchedule)
    }

    // MARK: - Notification Management

    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                self.isNotificationPermissionGranted = granted
            }

            if granted {
                print("✅ [SleepScheduleManager] Notification permission granted")
                // Reschedule all active schedules
                for schedule in schedules.filter({ $0.isEnabled }) {
                    try? await scheduleNotifications(for: schedule)
                }
            } else {
                print("❌ [SleepScheduleManager] Notification permission denied")
            }

            return granted
        } catch {
            print("❌ [SleepScheduleManager] Error requesting permissions: \(error)")
            return false
        }
    }

    private func checkNotificationPermission() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.isNotificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }

    private func scheduleNotifications(for schedule: SleepSchedule) async throws {
        guard isNotificationPermissionGranted else {
            throw SleepScheduleError.notificationPermissionDenied
        }

        // Remove existing notifications for this schedule
        await removeNotifications(for: schedule)

        let calendar = Calendar.current
        let now = Date()

        // Schedule notifications for next 30 days
        for dayOffset in 0 ..< 30 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = Weekday(from: calendar.component(.weekday, from: targetDate))

            guard schedule.selectedDays.contains(weekday) else { continue }

            let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: schedule.bedTime)
            guard let scheduledBedTime = calendar.date(bySettingHour: bedTimeComponents.hour ?? 20,
                                                       minute: bedTimeComponents.minute ?? 0,
                                                       second: 0,
                                                       of: targetDate) else { continue }

            // Reminder notification
            if let reminderTime = calendar.date(
                byAdding: .minute,
                value: -schedule.reminderMinutes,
                to: scheduledBedTime
            ),
                reminderTime > now
            {
                let reminderContent = UNMutableNotificationContent()
                reminderContent.title = "Bedtime soon"
                reminderContent.body = "Через \(schedule.reminderMinutes) мин. schedule starts \"\(schedule.name)\""
                reminderContent.sound = .default
                reminderContent.userInfo = [
                    "scheduleId": schedule.id.uuidString,
                    "type": "reminder",
                ]

                let reminderTrigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminderTime),
                    repeats: false
                )

                let reminderRequest = UNNotificationRequest(
                    identifier: "\(schedule.reminderNotificationId)_\(dayOffset)",
                    content: reminderContent,
                    trigger: reminderTrigger
                )

                try await notificationCenter.add(reminderRequest)
            }

            // Bedtime notification
            if scheduledBedTime > now {
                let bedtimeContent = UNMutableNotificationContent()
                bedtimeContent.title = "Bedtime!"
                bedtimeContent.body = "Schedule \"\(schedule.name)\" starts now"
                bedtimeContent.sound = .default
                bedtimeContent.userInfo = [
                    "scheduleId": schedule.id.uuidString,
                    "type": "bedtime",
                    "selectedSounds": schedule.selectedSounds,
                ]

                let bedtimeTrigger = UNCalendarNotificationTrigger(
                    dateMatching: calendar.dateComponents(
                        [.year, .month, .day, .hour, .minute],
                        from: scheduledBedTime
                    ),
                    repeats: false
                )

                let bedtimeRequest = UNNotificationRequest(
                    identifier: "\(schedule.bedtimeNotificationId)_\(dayOffset)",
                    content: bedtimeContent,
                    trigger: bedtimeTrigger
                )

                try await notificationCenter.add(bedtimeRequest)
            }
        }

        print("📅 [SleepScheduleManager] Scheduled notifications for: \(schedule.name)")
    }

    private func removeNotifications(for schedule: SleepSchedule) async {
        var identifiersToRemove: [String] = []

        // Collect all identifiers for this schedule
        for dayOffset in 0 ..< 30 {
            identifiersToRemove.append("\(schedule.reminderNotificationId)_\(dayOffset)")
            identifiersToRemove.append("\(schedule.bedtimeNotificationId)_\(dayOffset)")
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiersToRemove)
        print("🗑️ [SleepScheduleManager] Removed notifications for: \(schedule.name)")
    }

    // MARK: - Persistence

    private func saveSchedules() {
        do {
            let data = try JSONEncoder().encode(schedules)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("💾 [SleepScheduleManager] Saved \(schedules.count) schedules")
        } catch {
            print("❌ [SleepScheduleManager] Save error: \(error)")
            lastError = error
        }
    }

    private func loadSchedules() {
        isLoadingSchedules = true

        defer {
            isLoadingSchedules = false
        }

        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("📱 [SleepScheduleManager] No saved schedules")
            return
        }

        do {
            schedules = try JSONDecoder().decode([SleepSchedule].self, from: data)
            print("📖 [SleepScheduleManager] Loaded \(schedules.count) schedules")
        } catch {
            print("❌ [SleepScheduleManager] Load error: \(error)")
            lastError = error
        }
    }

    // MARK: - Premium Integration

    @objc
    private func premiumStatusChanged() {
        // If user lost premium and has more than the limit - deactivate excess
        if !premiumManager.hasFeature(.sleepSchedules), schedules.count > maxFreeSchedules {
            Task {
                let schedulesToDisable = Array(schedules.suffix(schedules.count - maxFreeSchedules))
                for schedule in schedulesToDisable {
                    var disabledSchedule = schedule
                    disabledSchedule.isEnabled = false
                    try? await updateSchedule(disabledSchedule)
                }
            }
        }
    }

    // MARK: - Computed Properties

    var activeSchedules: [SleepSchedule] {
        schedules.filter { $0.isEnabled }
    }

    var nextScheduledEvent: (schedule: SleepSchedule, time: Date, type: String)? {
        let now = Date()
        var nextEvent: (schedule: SleepSchedule, time: Date, type: String)?

        for schedule in activeSchedules {
            if let reminderTime = schedule.nextReminderTime, reminderTime > now {
                if nextEvent == nil || reminderTime < nextEvent!.time {
                    nextEvent = (schedule, reminderTime, "reminder")
                }
            }

            if let bedTime = schedule.nextBedTime, bedTime > now {
                if nextEvent == nil || bedTime < nextEvent!.time {
                    nextEvent = (schedule, bedTime, "bedtime")
                }
            }
        }

        return nextEvent
    }

    var canAddMoreSchedules: Bool {
        premiumManager.hasFeature(.sleepSchedules) || schedules.count < maxFreeSchedules
    }

    // MARK: - Action Handlers

    func handleBedtimeNotification(scheduleId: String, selectedSounds: [String]) {
        // This method will be called from AppDelegate when notification received
        guard let schedule = schedules.first(where: { $0.id.uuidString == scheduleId }) else {
            print("❌ [SleepScheduleManager] Schedule not found: \(scheduleId)")
            return
        }

        print("🌙 [SleepScheduleManager] Processing bedtime notification: \(schedule.name)")
        print("🌙 [SleepScheduleManager] Selected sounds: \(selectedSounds)")

        // Verify we have sounds to play
        guard !selectedSounds.isEmpty else {
            print("❌ [SleepScheduleManager] No sounds selected for schedule")
            return
        }

        // Automatically start selected sounds
        Task { @MainActor in
            do {
                await AudioEngineManager.shared.startSleepSchedule(
                    sounds: selectedSounds,
                    fadeMinutes: schedule.autoFadeMinutes
                )
                print("✅ [SleepScheduleManager] Sleep schedule playback started successfully")
            }
        }
    }
}
