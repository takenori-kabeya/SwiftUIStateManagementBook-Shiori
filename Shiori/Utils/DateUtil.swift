import Foundation

extension Date {
    nonisolated var date: Date {
        let calendar = Calendar.current
        let day = calendar.dateComponents([.year, .month, .day], from: self)
        return DateComponents(calendar: calendar, year: day.year, month: day.month, day: day.day).date!
    }
    
    nonisolated static func makeDate(year: Int, month: Int, day: Int) -> Date {
        return DateComponents(calendar: .current, year: year, month: month, day: day).date!
    }
}
