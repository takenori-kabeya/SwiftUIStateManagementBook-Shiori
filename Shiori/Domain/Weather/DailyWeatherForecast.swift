import Foundation

nonisolated struct DailyWeatherForecast: Identifiable, Equatable, Sendable {
    enum Availability: Equatable, Sendable {
        case available(
            condition: WeatherCondition,
            maxTemperature: Double,
            minTemperature: Double,
            precipitationProbability: Int
        )
        case pastDay
        case outsideForecastPeriod
        case notYet
    }

    let date: Date
    let availability: Availability

    var id: String { dateText }

    var dateText: String {
        date.ISO8601Format(.iso8601Date(timeZone: .current))
    }

    static func available(
        date: Date,
        condition: WeatherCondition,
        maxTemperature: Double,
        minTemperature: Double,
        precipitationProbability: Int
    ) -> Self {
        Self(
            date: date,
            availability: .available(
                condition: condition,
                maxTemperature: maxTemperature,
                minTemperature: minTemperature,
                precipitationProbability: precipitationProbability
            )
        )
    }

    static func pastDay(date: Date) -> Self {
        Self(date: date, availability: .pastDay)
    }

    static func outsideForecastPeriod(date: Date) -> Self {
        Self(date: date, availability: .outsideForecastPeriod)
    }
}
