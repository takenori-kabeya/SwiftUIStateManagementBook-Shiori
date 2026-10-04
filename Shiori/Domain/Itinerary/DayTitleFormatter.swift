import Foundation

nonisolated enum DayTitleFormatter {
    static func dayTitleText(tripStartDate: Date, dayIndex: Int) -> String {
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: dayIndex, to: tripStartDate) ?? tripStartDate
        let components = calendar.dateComponents([.month, .day], from: date)
        let month = components.month ?? 1
        let day = components.day ?? 1
        return String(format: "%d日目: %02d/%02d", dayIndex + 1, month, day)
    }
}
