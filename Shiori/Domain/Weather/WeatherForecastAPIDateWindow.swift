import Foundation

/// Open-Meteo Forecast API に渡す start_date / end_date
nonisolated struct WeatherForecastAPIDateWindow: Equatable, Sendable {
    var startDate: Date
    var endDate: Date

    /// 旅行期間と予報可能期間（今日〜今日+15日）の交差を返す。交差が空なら nil。
    static func make(
        tripStartDate: Date,
        numDays: Int,
        today: Date,
        calendar: Calendar = .current
    ) -> Self? {
        guard numDays >= 1 else {
            return nil
        }

        let todayDay = calendar.startOfDay(for: today)
        let tripStart = calendar.startOfDay(for: tripStartDate)
        guard
            let tripEnd = calendar.date(byAdding: .day, value: numDays - 1, to: tripStart),
            let forecastEnd = calendar.date(byAdding: .day, value: 15, to: todayDay)
        else {
            return nil
        }

        let startDate = max(todayDay, tripStart)
        let endDate = min(forecastEnd, tripEnd)
        guard startDate <= endDate else {
            return nil
        }

        return Self(startDate: startDate, endDate: endDate)
    }
}
