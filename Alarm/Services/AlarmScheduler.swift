import Foundation
import UserNotifications
#if canImport(AlarmKit)
import AlarmKit
import ActivityKit
import SwiftUI
#endif

protocol AlarmScheduler {
    func requestAuthorization() async throws
    func schedule(_ item: AlarmItem, nextDate: Date) async throws
    func cancel(_ item: AlarmItem) async throws
}

final class AdaptiveAlarmScheduler: AlarmScheduler {
    private let primary: AlarmScheduler
    private let fallback: AlarmScheduler
    private var useFallback = false

    init(
        primary: AlarmScheduler,
        fallback: AlarmScheduler = NotificationAlarmScheduler()
    ) {
        self.primary = primary
        self.fallback = fallback
    }

    func requestAuthorization() async throws {
        if useFallback {
            try await fallback.requestAuthorization()
            return
        }

        do {
            try await primary.requestAuthorization()
        } catch {
            guard shouldFallback(error) else { throw error }
            useFallback = true
            try await fallback.requestAuthorization()
        }
    }

    func schedule(_ item: AlarmItem, nextDate: Date) async throws {
        if useFallback {
            try await fallback.schedule(item, nextDate: nextDate)
            return
        }

        do {
            try await primary.schedule(item, nextDate: nextDate)
        } catch {
            guard shouldFallback(error) else { throw error }
            useFallback = true
            try await fallback.schedule(item, nextDate: nextDate)
        }
    }

    func cancel(_ item: AlarmItem) async throws {
        if useFallback {
            try await fallback.cancel(item)
            return
        }

        do {
            try await primary.cancel(item)
        } catch {
            guard shouldFallback(error) else { throw error }
            useFallback = true
            try await fallback.cancel(item)
        }
    }

    private func shouldFallback(_ error: Error) -> Bool {
        let nsError = error as NSError
        return nsError.domain == "com.apple.AlarmKit.Alarm" && nsError.code == 1
    }
}

struct AlarmKitScheduler: AlarmScheduler {
    func requestAuthorization() async throws {
        #if canImport(AlarmKit)
        #if targetEnvironment(simulator)
        return
        #else
        if #available(iOS 26.1, *) {
            _ = try await AlarmManager.shared.requestAuthorization()
        }
        #endif
        #endif
    }

    func schedule(_ item: AlarmItem, nextDate: Date) async throws {
        #if canImport(AlarmKit)
        #if targetEnvironment(simulator)
        return
        #else
        if #available(iOS 26.1, *) {
            let alert = AlarmPresentation.Alert(title: .init(stringLiteral: item.label))
            let presentation = AlarmPresentation(alert: alert)
            let attributes = AlarmAttributes<AppAlarmMetadata>(
                presentation: presentation,
                metadata: AppAlarmMetadata(label: item.label),
                tintColor: .orange
            )

            let schedule = buildSchedule(item)
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: schedule ?? .fixed(nextDate),
                attributes: attributes,
                sound: .default
            )

            _ = try await AlarmManager.shared.schedule(id: item.id, configuration: configuration)
        }
        #endif
        #endif
    }

    func cancel(_ item: AlarmItem) async throws {
        #if canImport(AlarmKit)
        #if targetEnvironment(simulator)
        return
        #else
        if #available(iOS 26.1, *) {
            try AlarmManager.shared.cancel(id: item.id)
        }
        #endif
        #endif
    }

    #if canImport(AlarmKit)
    @available(iOS 26.1, *)
    private func buildSchedule(_ item: AlarmItem) -> Alarm.Schedule? {
        let components = Calendar.current.dateComponents([.hour, .minute], from: item.time)
        let hour = components.hour ?? 7
        let minute = components.minute ?? 30
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)

        let recurrence: Alarm.Schedule.Relative.Recurrence
        if item.repeatRule.preset == .custom && item.repeatRule.weekdays.isEmpty {
            recurrence = .never
        } else {
            let weekdays = item.repeatRule.weekdays.compactMap(localeWeekday)
            recurrence = .weekly(weekdays)
        }

        return .relative(.init(time: time, repeats: recurrence))
    }

    @available(iOS 26.1, *)
    private func localeWeekday(_ day: Int) -> Locale.Weekday? {
        switch day {
        case 1: .sunday
        case 2: .monday
        case 3: .tuesday
        case 4: .wednesday
        case 5: .thursday
        case 6: .friday
        case 7: .saturday
        default: nil
        }
    }
    #endif
}

struct NoopAlarmScheduler: AlarmScheduler {
    func requestAuthorization() async throws {}
    func schedule(_ item: AlarmItem, nextDate: Date) async throws {}
    func cancel(_ item: AlarmItem) async throws {}
}

struct NotificationAlarmScheduler: AlarmScheduler {
    func requestAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        if !granted {
            throw NSError(
                domain: "local.notification",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "通知权限未授权，无法发送闹钟提醒"]
            )
        }
    }

    func schedule(_ item: AlarmItem, nextDate: Date) async throws {
        let content = UNMutableNotificationContent()
        content.title = item.label.isEmpty ? "闹钟" : item.label
        content.body = "提醒时间到"
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: nextDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: item.id.uuidString,
            content: content,
            trigger: trigger
        )

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        try await center.add(request)
    }

    func cancel(_ item: AlarmItem) async throws {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [item.id.uuidString])
        center.removeDeliveredNotifications(withIdentifiers: [item.id.uuidString])
    }
}

#if canImport(AlarmKit)
@available(iOS 26.1, *)
private struct AppAlarmMetadata: AlarmMetadata {
    let label: String
}
#endif
