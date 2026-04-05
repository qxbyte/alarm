import Foundation

struct HolidayEntry: Identifiable, Codable, Equatable {
    enum Kind: String, Codable {
        case legalHoliday
        case makeUpWorkday
        case customSkip
        case customWorkday
    }

    var id: UUID
    var title: String
    var startDate: Date
    var endDate: Date
    var kind: Kind

    init(id: UUID = UUID(), title: String, startDate: Date, endDate: Date, kind: Kind) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.kind = kind
    }

    func contains(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= calendar.startOfDay(for: startDate) && day <= calendar.startOfDay(for: endDate)
    }
}
