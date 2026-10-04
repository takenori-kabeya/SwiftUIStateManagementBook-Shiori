import Foundation

/// 旅行全日程と API 取得結果をマージし、過去日・期間外・取得済みを分類する
nonisolated enum WeatherForecastTripDaysBuilder {
    static func build(
        tripStartDate: Date,
        numDays: Int,
        today: Date,
        fetched: [DailyWeatherForecast],
        calendar: Calendar = .current
    ) throws -> [DailyWeatherForecast] {
        guard numDays >= 1 else {
            return []
        }

        let todayDay = calendar.startOfDay(for: today)
        let tripStart = calendar.startOfDay(for: tripStartDate)
        guard let forecastEnd = calendar.date(byAdding: .day, value: 15, to: todayDay) else {
            throw WeatherForecastError.invalidResponse
        }

        var fetchedByDay: [Date: DailyWeatherForecast] = [:]
        for forecast in fetched {
            let day = calendar.startOfDay(for: forecast.date)
            guard case .available = forecast.availability else {
                continue
            }
            fetchedByDay[day] = forecast
        }

        var result = [DailyWeatherForecast]()
        result.reserveCapacity(numDays)

        for offset in 0..<numDays {
            guard let date = calendar.date(byAdding: .day, value: offset, to: tripStart) else {
                throw WeatherForecastError.invalidResponse
            }
            let day = calendar.startOfDay(for: date)

            if day < todayDay {
                result.append(.pastDay(date: day))
            } else if day > forecastEnd {
                result.append(.outsideForecastPeriod(date: day))
            } else if let forecast = fetchedByDay[day] {
                result.append(forecast)
            } else {
                throw WeatherForecastError.invalidResponse
            }
        }

        return result
    }
}
