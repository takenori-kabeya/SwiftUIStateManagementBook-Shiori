import Foundation
import Testing
@testable import Shiori

/// Open-Meteo 応答から日次予報への変換を検証する
struct WeatherForecastResponseMapperTests {
    private func date(_ text: String) throws -> Date {
        try Date(text, strategy: .iso8601.year().month().day())
    }

    @Test func 有効な日付なら予報を返すこと() throws {
        let forecasts = try WeatherForecastResponseMapper.makeDailyForecasts(
            times: ["2026-08-01", "2026-08-02"],
            weatherCodes: [0, 3],
            maxTemperatures: [30.0, 28.0],
            minTemperatures: [22.0, 21.0],
            precipitationProbabilities: [10, 40]
        )

        #expect(forecasts == [
            DailyWeatherForecast.available(
                date: try date("2026-08-01"),
                condition: .clearSky,
                maxTemperature: 30.0,
                minTemperature: 22.0,
                precipitationProbability: 10
            ),
            DailyWeatherForecast.available(
                date: try date("2026-08-02"),
                condition: .overcast,
                maxTemperature: 28.0,
                minTemperature: 21.0,
                precipitationProbability: 40
            ),
        ])
    }

    @Test func 不正な日付でinvalidResponseを投げること() {
        #expect(throws: WeatherForecastError.invalidResponse) {
            try WeatherForecastResponseMapper.makeDailyForecasts(
                times: ["2026-08-01", "not-a-date"],
                weatherCodes: [0, 3],
                maxTemperatures: [30.0, 28.0],
                minTemperatures: [22.0, 21.0],
                precipitationProbabilities: [10, 40]
            )
        }
    }

    @Test func 配列長の不一致でinvalidResponseを投げること() {
        #expect(throws: WeatherForecastError.invalidResponse) {
            try WeatherForecastResponseMapper.makeDailyForecasts(
                times: ["2026-08-01", "2026-08-02"],
                weatherCodes: [0],
                maxTemperatures: [30.0, 28.0],
                minTemperatures: [22.0, 21.0],
                precipitationProbabilities: [10, 40]
            )
        }
    }

    @Test func 空配列でinvalidResponseを投げること() {
        #expect(throws: WeatherForecastError.invalidResponse) {
            try WeatherForecastResponseMapper.makeDailyForecasts(
                times: [],
                weatherCodes: [],
                maxTemperatures: [],
                minTemperatures: [],
                precipitationProbabilities: []
            )
        }
    }
}
