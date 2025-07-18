import Foundation

// MARK: - SleepSchedule Model

struct SleepSchedule: Identifiable, Codable, Equatable {
    let id = UUID()
    var name: String
    var bedtimeHour: Int
    var bedtimeMinute: Int
    var weekdays: [Bool] // [Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday]
    var reminderMinutes: Int // Minutes before bedtime for reminder
    var selectedSounds: [String] // Sound IDs for playback
    var autoFadeMinutes: Int // Auto fade after X minutes
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date
    
    init(
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
    
    var nextBedTime: Date? {
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
    
    var nextReminderTime: Date? {
        guard let bedTime = nextBedTime else { return nil }
        return Calendar.current.date(byAdding: .minute, value: -reminderMinutes, to: bedTime)
    }
    
    var formattedBedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: bedTime)
    }
    
    var formattedWakeTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: wakeTime)
    }
    
    var selectedDaysText: String {
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
    
    var reminderNotificationId: String {
        return "sleep_reminder_\(id.uuidString)"
    }
    
    var bedtimeNotificationId: String {
        return "sleep_bedtime_\(id.uuidString)"
    }
}

// MARK: - Weekday Enum

enum Weekday: Int, CaseIterable, Codable, Comparable {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    init(from weekdayComponent: Int) {
        self = Weekday(rawValue: weekdayComponent) ?? .sunday
    }
    
    var name: String {
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
    
    var shortName: String {
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
    
    static func < (lhs: Weekday, rhs: Weekday) -> Bool {
        // Сортировка: Понедельник первый, Воскресенье последний
        let lhsOrder = lhs == .sunday ? 7 : lhs.rawValue
        let rhsOrder = rhs == .sunday ? 7 : rhs.rawValue
        return lhsOrder < rhsOrder
    }
}

// MARK: - SleepScheduleError

enum SleepScheduleError: LocalizedError {
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