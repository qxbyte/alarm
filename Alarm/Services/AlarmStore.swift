import Foundation
import Combine

@MainActor
final class AlarmStore: ObservableObject {
    @Published private(set) var alarms: [AlarmItem] = []
    @Published var settings: AppSettings = .default
    @Published var holidayEntries: [HolidayEntry] = []
    @Published var lastErrorMessage: String?

    private let storageKey = "alarm.items.v1"
    private let settingsKey = "alarm.settings.v1"
    private let defaults: UserDefaults
    private let scheduler: AlarmScheduler
    private let holidayService: HolidayServiceProtocol
    private let calendar = Calendar.current

    init(
        defaults: UserDefaults = .standard,
        scheduler: AlarmScheduler = NoopAlarmScheduler(),
        holidayService: HolidayServiceProtocol = HolidayService()
    ) {
        self.defaults = defaults
        self.scheduler = scheduler
        self.holidayService = holidayService
        load()

        Task {
            await refreshHolidayEntries()
            await rescheduleEnabledAlarms()
        }
    }

    func requestAlarmAuthorization() async {
        do {
            try await scheduler.requestAuthorization()
        } catch {
            lastErrorMessage = friendlyAlarmErrorMessage(prefix: "闹钟权限请求失败", error: error)
        }
    }

    func refreshHolidayEntries() async {
        holidayEntries = await holidayService.refreshEntries(settings: settings)
    }

    func addAlarm(_ item: AlarmItem) {
        alarms.append(item)
        save()

        Task {
            await scheduleIfNeeded(item)
        }
    }

    func updateAlarm(_ item: AlarmItem) {
        guard let index = alarms.firstIndex(where: { $0.id == item.id }) else { return }

        var copy = item
        copy.updatedAt = Date()
        alarms[index] = copy
        save()

        Task {
            await scheduleIfNeeded(copy)
        }
    }

    func toggleAlarm(id: UUID, isOn: Bool) {
        guard let index = alarms.firstIndex(where: { $0.id == id }) else { return }
        alarms[index].isEnabled = isOn
        alarms[index].updatedAt = Date()
        let item = alarms[index]
        save()

        Task {
            if isOn {
                await scheduleIfNeeded(item)
            } else {
                do {
                    try await scheduler.cancel(item)
                } catch {
                    lastErrorMessage = friendlyAlarmErrorMessage(prefix: "取消闹钟失败", error: error)
                }
            }
        }
    }

    func removeAlarm(id: UUID) {
        guard let item = alarms.first(where: { $0.id == id }) else { return }
        alarms.removeAll { $0.id == id }
        save()

        Task {
            do {
                try await scheduler.cancel(item)
            } catch {
                lastErrorMessage = friendlyAlarmErrorMessage(prefix: "删除闹钟失败", error: error)
            }
        }
    }

    func saveSettings(_ newSettings: AppSettings) {
        settings = newSettings
        save()

        Task {
            await refreshHolidayEntries()
            await rescheduleEnabledAlarms()
        }
    }

    func nextTriggerText(for item: AlarmItem) -> String {
        guard item.isEnabled else { return "已关闭" }

        guard let nextDate = nextTriggerDate(for: item, from: Date()) else {
            return "暂无下次提醒"
        }

        return "下次：\(nextDate.alarmDisplayText()) · 节假日跳过 \(item.skipHolidayEnabled ? "🟢" : "🔴")"
    }

    private func rescheduleEnabledAlarms() async {
        for item in alarms where item.isEnabled {
            await scheduleIfNeeded(item)
        }
    }

    private func scheduleIfNeeded(_ item: AlarmItem) async {
        guard item.isEnabled else { return }
        guard let nextDate = nextTriggerDate(for: item, from: Date()) else { return }

        do {
            try await scheduler.schedule(item, nextDate: nextDate)
        } catch {
            lastErrorMessage = friendlyAlarmErrorMessage(prefix: "调度闹钟失败", error: error)
        }
    }

    private func friendlyAlarmErrorMessage(prefix: String, error: Error) -> String {
        let nsError = error as NSError
        if nsError.domain == "com.apple.AlarmKit.Alarm", nsError.code == 1 {
            return "\(prefix)：系统拒绝了 AlarmKit 请求（错误码 1）。请在 Xcode > Signing & Capabilities 中启用 AlarmKit 能力，确认真机已开启开发者模式并重新安装应用。原始错误：\(nsError.localizedDescription)"
        }

        return "\(prefix)：\(error.localizedDescription)"
    }

    private func nextTriggerDate(for item: AlarmItem, from baseDate: Date) -> Date? {
        let timeParts = calendar.dateComponents([.hour, .minute], from: item.time)

        for offset in 0 ... 366 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: baseDate) else { continue }
            guard let candidate = calendar.date(bySettingHour: timeParts.hour ?? 7, minute: timeParts.minute ?? 30, second: 0, of: day) else { continue }

            if candidate <= baseDate {
                continue
            }

            let weekday = calendar.component(.weekday, from: candidate)
            let isWorkdayOverride = holidayService.isWorkdayOverride(candidate, settings: settings, entries: holidayEntries)
            let matchRepeat: Bool
            if item.repeatRule.preset == .weekdays {
                matchRepeat = item.repeatRule.weekdays.contains(weekday) || isWorkdayOverride
            } else {
                matchRepeat = item.repeatRule.weekdays.contains(weekday)
            }
            if !matchRepeat {
                continue
            }

            if item.skipHolidayEnabled && holidayService.isSkipDate(candidate, settings: settings, entries: holidayEntries) {
                continue
            }

            return candidate
        }

        return nil
    }

    private func load() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AlarmItem].self, from: data) {
            alarms = decoded
        }

        if let data = defaults.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            defaults.set(data, forKey: storageKey)
        }

        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: settingsKey)
        }
    }
}
