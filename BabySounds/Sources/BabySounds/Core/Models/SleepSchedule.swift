import Foundation

public struct SleepSchedule: Identifiable, Codable, Equatable {
    public let id: UUID
    public var name: String
    public var isEnabled: Bool
    public var bedTime: Date
    public var wakeTime: Date
    public var selectedDays: Set<Weekday>
    public var reminderMinutes: Int
    public var selectedSounds: [String]
    public var autoFadeMinutes: Int
    public var dateCreated: Date
    public var lastModified: Date

    public init(
        id: UUID = UUID(),
        name: String = "My Sleep Schedule",
        isEnabled: Bool = true,
        bedTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
        wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        selectedDays: Set<Weekday> = Set(Weekday.allCases),
        reminderMinutes: Int = 30,
        selectedSounds: [String] = [],
        autoFadeMinutes: Int = 45,
        dateCreated: Date = Date(),
        lastModified: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.bedTime = bedTime
        self.wakeTime = wakeTime
        self.selectedDays = selectedDays
        self.reminderMinutes = reminderMinutes
        self.selectedSounds = selectedSounds
        self.autoFadeMinutes = autoFadeMinutes
        self.dateCreated = dateCreated
        self.lastModified = lastModified
    }

    public var nextBedTime: Date? {
        guard isEnabled, !selectedDays.isEmpty else { return nil }
        let calendar = Calendar.current
        let now = Date()

        for dayOffset in 0 ..< 8 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = Weekday(from: calendar.component(.weekday, from: date))
            guard selectedDays.contains(weekday) else { continue }

            let components = calendar.dateComponents([.hour, .minute], from: bedTime)
            guard let candidate = calendar.date(bySettingHour: components.hour ?? 20,
                                                minute: components.minute ?? 0,
                                                second: 0,
                                                of: date) else { continue }
            if candidate > now { return candidate }
        }
        return nil
    }

    public var formattedBedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedTime)
    }

    public var formattedWakeTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }

    public var selectedDaysText: String {
        if selectedDays == Set(Weekday.allCases) { return "Every day" }
        if selectedDays == Set([.monday, .tuesday, .wednesday, .thursday, .friday]) { return "Weekdays" }
        if selectedDays == Set([.saturday, .sunday]) { return "Weekends" }
        return selectedDays.sorted().map(\.shortName).joined(separator: ", ")
    }

    public var reminderNotificationId: String { "sleep_reminder_\(id.uuidString)" }
    public var bedtimeNotificationId: String { "sleep_bedtime_\(id.uuidString)" }
}

public enum Weekday: Int, CaseIterable, Codable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public init(from weekdayComponent: Int) {
        self = Weekday(rawValue: weekdayComponent) ?? .sunday
    }

    public var name: String {
        switch self {
        case .sunday: return "Sunday"
        case .monday: return "Monday"
        case .tuesday: return "Tuesday"
        case .wednesday: return "Wednesday"
        case .thursday: return "Thursday"
        case .friday: return "Friday"
        case .saturday: return "Saturday"
        }
    }

    public var shortName: String {
        switch self {
        case .sunday: return "Sun"
        case .monday: return "Mon"
        case .tuesday: return "Tue"
        case .wednesday: return "Wed"
        case .thursday: return "Thu"
        case .friday: return "Fri"
        case .saturday: return "Sat"
        }
    }

    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        (lhs == .sunday ? 8 : lhs.rawValue) < (rhs == .sunday ? 8 : rhs.rawValue)
    }
}

public enum SleepScheduleError: LocalizedError {
    case notificationPermissionDenied, invalidTimeConfiguration, scheduleNotFound, maxSchedulesReached

    public var errorDescription: String? {
        switch self {
        case .notificationPermissionDenied: return "Notification permission not granted"
        case .invalidTimeConfiguration: return "Invalid time configuration"
        case .scheduleNotFound: return "Schedule not found"
        case .maxSchedulesReached: return "Maximum number of schedules reached"
        }
    }
}
