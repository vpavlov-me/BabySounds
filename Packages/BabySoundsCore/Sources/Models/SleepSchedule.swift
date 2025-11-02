import Foundation

// MARK: - SleepSchedule Model

public struct SleepSchedule: Identifiable, Codable, Hashable {
    public let id: UUID
    public var name: String
    public var isEnabled: Bool
    public var bedTime: Date
    public var wakeTime: Date
    public var selectedDays: Set<Weekday>
    public var reminderMinutes: Int
    public var selectedSounds: [String]
    public var autoFadeMinutes: Int
    public let dateCreated: Date
    public var lastModified: Date

    public init(
        id: UUID = UUID(),
        name: String = "Мое расписание сна",
        isEnabled: Bool = true,
        bedTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
        wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        selectedDays: Set<Weekday> = Set(Weekday.allCases),
        reminderMinutes: Int = 30,
        selectedSounds: [String] = [],
        autoFadeMinutes: Int = 45,
        dateCreated: Date = Date()
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
        self.lastModified = Date()
    }
    
    // MARK: - Computed Properties

    public var nextBedTime: Date? {
        guard isEnabled && !selectedDays.isEmpty else { return nil }
        
        let calendar = Calendar.current
        let now = Date()
        
        // Проверяем каждый день недели начиная с сегодня
        for dayOffset in 0..<7 {
            guard let targetDate = calendar.date(byAdding: .day, value: dayOffset, to: now) else { continue }
            let weekday = Weekday(from: calendar.component(.weekday, from: targetDate))
            
            guard selectedDays.contains(weekday) else { continue }
            
            // Создаем время сна для этого дня
            let bedTimeComponents = calendar.dateComponents([.hour, .minute], from: bedTime)
            guard let scheduledBedTime = calendar.date(bySettingHour: bedTimeComponents.hour ?? 20, 
                                                      minute: bedTimeComponents.minute ?? 0, 
                                                      second: 0, 
                                                      of: targetDate) else { continue }
            
            // Если это сегодня и время еще не прошло, или это будущий день
            if scheduledBedTime > now {
                return scheduledBedTime
            }
        }
        
        return nil
    }
    
    public var nextReminderTime: Date? {
        guard let bedTime = nextBedTime else { return nil }
        return Calendar.current.date(byAdding: .minute, value: -reminderMinutes, to: bedTime)
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
        if selectedDays.count == 7 {
            return "Каждый день"
        } else if selectedDays.count == 5 && selectedDays.isSuperset(of: [.monday, .tuesday, .wednesday, .thursday, .friday]) {
            return "Будни"
        } else if selectedDays.count == 2 && selectedDays.isSuperset(of: [.saturday, .sunday]) {
            return "Выходные"
        } else {
            return selectedDays.sorted().map { $0.shortName }.joined(separator: ", ")
        }
    }
    
    // MARK: - Notification Identifiers
    
    public var reminderNotificationId: String {
        return "sleep_reminder_\(id.uuidString)"
    }
    
    public var bedtimeNotificationId: String {
        return "sleep_bedtime_\(id.uuidString)"
    }
}

// MARK: - Weekday Enum

public enum Weekday: Int, CaseIterable, Codable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday

    public init(from weekdayComponent: Int) {
        self = Weekday(rawValue: weekdayComponent) ?? .sunday
    }

    public var name: String {
        switch self {
        case .sunday: return "Воскресенье"
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        }
    }
    
    public var shortName: String {
        switch self {
        case .sunday: return "Вс"
        case .monday: return "Пн"
        case .tuesday: return "Вт"
        case .wednesday: return "Ср"
        case .thursday: return "Чт"
        case .friday: return "Пт"
        case .saturday: return "Сб"
        }
    }
    
    public static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        // Сортировка: Понедельник первый, Воскресенье последний
        let lhsOrder = lhs == .sunday ? 7 : lhs.rawValue
        let rhsOrder = rhs == .sunday ? 7 : rhs.rawValue
        return lhsOrder < rhsOrder
    }
}

// MARK: - SleepScheduleError

public enum SleepScheduleError: LocalizedError {
    case notificationPermissionDenied
    case invalidTimeConfiguration
    case scheduleNotFound
    case maxSchedulesReached
    
    var errorDescription: String? {
        switch self {
        case .notificationPermissionDenied:
            return "Разрешение на уведомления не предоставлено"
        case .invalidTimeConfiguration:
            return "Неверная конфигурация времени"
        case .scheduleNotFound:
            return "Расписание не найдено"
        case .maxSchedulesReached:
            return "Достигнуто максимальное количество расписаний"
        }
    }
} 