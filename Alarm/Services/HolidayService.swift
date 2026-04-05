import Foundation

#if canImport(EventKit)
import EventKit
#endif

protocol HolidayServiceProtocol {
    func refreshEntries(settings: AppSettings) async -> [HolidayEntry]
    func isSkipDate(_ date: Date, settings: AppSettings, entries: [HolidayEntry]) -> Bool
    func isWorkdayOverride(_ date: Date, settings: AppSettings, entries: [HolidayEntry]) -> Bool
}

struct HolidayService: HolidayServiceProtocol {
    func refreshEntries(settings: AppSettings) async -> [HolidayEntry] {
        var output: [HolidayEntry] = []

        if settings.legalHolidayEnabled {
            output.append(contentsOf: await loadSystemHolidayEntries())
        }

        output.append(contentsOf: settings.customSkipDates.map {
            HolidayEntry(title: "自定义跳过", startDate: $0, endDate: $0, kind: .customSkip)
        })

        output.append(contentsOf: settings.customWorkDates.map {
            HolidayEntry(title: "自定义工作日", startDate: $0, endDate: $0, kind: .customWorkday)
        })

        return output
    }

    func isSkipDate(_ date: Date, settings: AppSettings, entries: [HolidayEntry]) -> Bool {
        if isWorkdayOverride(date, settings: settings, entries: entries) {
            return false
        }

        if entries.contains(where: { ($0.kind == .legalHoliday || $0.kind == .customSkip) && $0.contains(date) }) {
            return true
        }

        let weekday = Calendar.current.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return true
        }

        return false
    }

    func isWorkdayOverride(_ date: Date, settings: AppSettings, entries: [HolidayEntry]) -> Bool {
        if entries.contains(where: { $0.kind == .customWorkday && $0.contains(date) }) {
            return true
        }

        if settings.makeUpWorkdayEnabled,
           entries.contains(where: { $0.kind == .makeUpWorkday && $0.contains(date) }) {
            return true
        }

        return false
    }

    private func loadSystemHolidayEntries() async -> [HolidayEntry] {
        #if canImport(EventKit)
        let eventStore = EKEventStore()

        do {
            if #available(iOS 17.0, *) {
                _ = try await eventStore.requestFullAccessToEvents()
            } else {
                _ = try await eventStore.requestAccess(to: .event)
            }
        } catch {
            return []
        }

        let calendars = eventStore.calendars(for: .event)
        let holidayCalendar = calendars.first { $0.title == "中国大陆节假日" }

        guard let holidayCalendar else { return [] }

        let now = Date()
        let calendar = Calendar.current
        let start = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        let end = calendar.date(byAdding: .year, value: 2, to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: [holidayCalendar])

        return eventStore.events(matching: predicate).compactMap {
            let title = $0.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let kind: HolidayEntry.Kind

            if title.contains("班") {
                kind = .makeUpWorkday
            } else if title.contains("休") {
                kind = .legalHoliday
            } else {
                kind = .legalHoliday
            }

            return HolidayEntry(title: title, startDate: $0.startDate, endDate: $0.endDate, kind: kind)
        }
        #else
        return []
        #endif
    }
}
