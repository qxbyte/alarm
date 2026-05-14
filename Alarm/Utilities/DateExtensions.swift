import Foundation

extension Date {
    func alarmTimeText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: self)
    }

    func alarmDisplayText() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE HH:mm"
        return formatter.string(from: self)
    }

    func alarmRelativeDisplayText(relativeTo reference: Date = Date()) -> String {
        let calendar = Calendar.current

        if calendar.isDate(self, inSameDayAs: reference) {
            return "今天 \(alarmTimeText())"
        }

        if let tomorrow = calendar.date(byAdding: .day, value: 1, to: reference),
           calendar.isDate(self, inSameDayAs: tomorrow) {
            return "明天 \(alarmTimeText())"
        }

        if let dayAfterTomorrow = calendar.date(byAdding: .day, value: 2, to: reference),
           calendar.isDate(self, inSameDayAs: dayAfterTomorrow) {
            return "后天 \(alarmTimeText())"
        }

        return alarmDisplayText()
    }
}
