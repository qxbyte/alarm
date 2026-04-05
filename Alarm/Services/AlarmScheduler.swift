import Foundation
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

struct AlarmKitScheduler: AlarmScheduler {
    func requestAuthorization() async throws {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            _ = try await AlarmManager.shared.requestAuthorization()
        }
        #endif
    }

    func schedule(_ item: AlarmItem, nextDate: Date) async throws {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
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
    }

    func cancel(_ item: AlarmItem) async throws {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            try AlarmManager.shared.cancel(id: item.id)
        }
        #endif
    }

    #if canImport(AlarmKit)
    @available(iOS 26.0, *)
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

    @available(iOS 26.0, *)
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

#if canImport(AlarmKit)
@available(iOS 26.0, *)
private struct AppAlarmMetadata: AlarmMetadata {
    let label: String
}
#endif
