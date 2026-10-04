import Foundation

enum SpotTimeFormatter {
    static func stayTimeText(for spot: Spot) -> String {
        // "(時刻未定)" / "10:30" / "10:30〜13:00" を返す
        guard let startTime = spot.startTime else {
            return "（時刻未定）"
        }
        let startTimeText = startTime.formattedTime
        guard let endTime = spot.endTime else {
            return startTimeText
        }
        let endTimeText = endTime.formattedTime
        return startTimeText + "〜" + endTimeText
    }
}

extension Spot {
    var stayTimeDisplayText: String {
        SpotTimeFormatter.stayTimeText(for: self)
    }
}
