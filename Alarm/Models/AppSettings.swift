import Foundation

struct AppSettings: Codable, Equatable {
    var legalHolidayEnabled: Bool
    var makeUpWorkdayEnabled: Bool
    var customSkipDates: [Date]
    var customWorkDates: [Date]

    static let `default` = AppSettings(
        legalHolidayEnabled: true,
        makeUpWorkdayEnabled: true,
        customSkipDates: [],
        customWorkDates: []
    )
}
