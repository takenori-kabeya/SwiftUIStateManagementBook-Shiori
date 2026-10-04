import Foundation

enum SpotTimeFormatter {
    static func stayTimeText(for spot: Spot) -> String {
        // "(予定なし)" / "10:30" / "10:30〜13:00" を返す
        guard let startTime = spot.startTime else {
            return "（時刻未定）"
        }
        let startTimeText = startTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        guard let endTime = spot.endTime else {
            return startTimeText
        }
        let endTimeText = endTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        return startTimeText + "〜" + endTimeText
    }
}

extension Spot {
    var stayTimeDisplayText: String {
        SpotTimeFormatter.stayTimeText(for: self)
    }
}
