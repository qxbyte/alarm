import Foundation

struct AlarmItem: Identifiable, Codable, Equatable {
    var id: UUID
    var time: Date
    var repeatRule: AlarmRepeatRule
    var label: String
    var soundName: String
    var snoozeEnabled: Bool
    var snoozeMinutes: Int
    var skipHolidayEnabled: Bool
    var smartMakeUpEnabled: Bool
    var isEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        time: Date,
        repeatRule: AlarmRepeatRule = .weekdays,
        label: String = "闹钟",
        soundName: String = "雷达",
        snoozeEnabled: Bool = true,
        snoozeMinutes: Int = 9,
        skipHolidayEnabled: Bool = true,
        smartMakeUpEnabled: Bool = false,
        isEnabled: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.time = time
        self.repeatRule = repeatRule
        self.label = label
        self.soundName = soundName
        self.snoozeEnabled = snoozeEnabled
        self.snoozeMinutes = min(max(snoozeMinutes, 1), 30)
        self.skipHolidayEnabled = skipHolidayEnabled
        self.smartMakeUpEnabled = smartMakeUpEnabled
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case time
        case repeatRule
        case label
        case soundName
        case snoozeEnabled
        case snoozeMinutes
        case skipHolidayEnabled
        case smartMakeUpEnabled
        case isEnabled
        case createdAt
        case updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        time = try container.decode(Date.self, forKey: .time)
        repeatRule = try container.decode(AlarmRepeatRule.self, forKey: .repeatRule)
        label = try container.decode(String.self, forKey: .label)
        soundName = try container.decode(String.self, forKey: .soundName)
        snoozeEnabled = try container.decodeIfPresent(Bool.self, forKey: .snoozeEnabled) ?? true
        snoozeMinutes = min(max(try container.decodeIfPresent(Int.self, forKey: .snoozeMinutes) ?? 9, 1), 30)
        skipHolidayEnabled = try container.decode(Bool.self, forKey: .skipHolidayEnabled)
        smartMakeUpEnabled = try container.decode(Bool.self, forKey: .smartMakeUpEnabled)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }
}

enum AlarmRepeatPreset: String, Codable, CaseIterable, Identifiable {
    case everyDay
    case weekdays
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .everyDay:
            return "每天"
        case .weekdays:
            return "工作日"
        case .custom:
            return "自定义"
        }
    }
}

struct AlarmRepeatRule: Codable, Equatable {
    var preset: AlarmRepeatPreset
    var weekdays: Set<Int>

    static var everyDay: AlarmRepeatRule {
        AlarmRepeatRule(preset: .everyDay, weekdays: Set(1 ... 7))
    }

    static var weekdays: AlarmRepeatRule {
        AlarmRepeatRule(preset: .weekdays, weekdays: [2, 3, 4, 5, 6])
    }

    static func custom(_ days: Set<Int>) -> AlarmRepeatRule {
        AlarmRepeatRule(preset: .custom, weekdays: days)
    }

    var displayText: String {
        switch preset {
        case .everyDay:
            return "每天"
        case .weekdays:
            return "工作日"
        case .custom:
            if weekdays.isEmpty {
                return "不重复"
            }
            return weekdays
                .sorted()
                .map { Self.weekdayTitle($0) }
                .joined(separator: "、")
        }
    }

    static func weekdayTitle(_ day: Int) -> String {
        switch day {
        case 1: return "周日"
        case 2: return "周一"
        case 3: return "周二"
        case 4: return "周三"
        case 5: return "周四"
        case 6: return "周五"
        case 7: return "周六"
        default: return "-"
        }
    }
}
