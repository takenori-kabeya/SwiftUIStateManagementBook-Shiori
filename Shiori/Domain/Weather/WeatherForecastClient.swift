import Foundation
import ComposableArchitecture

@DependencyClient
nonisolated struct WeatherForecastClient: Sendable {
    var fetchForecast: @Sendable (_ latitude: Double, _ longitude: Double, _ fromDate: Date, _ forecastDays: Int) async throws -> [DailyWeatherForecast]
}

nonisolated extension WeatherForecastClient: DependencyKey {
    public static let liveValue = Self(
        fetchForecast: { latitude, longitude, fromDate, forecastDays in
            let today = Date()
            let fetched: [DailyWeatherForecast]
            if let window = WeatherForecastAPIDateWindow.make(
                tripStartDate: fromDate,
                numDays: forecastDays,
                today: today
            ) {
                var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")
                components?.queryItems = [
                    URLQueryItem(name: "latitude", value: String(latitude)),
                    URLQueryItem(name: "longitude", value: String(longitude)),
                    URLQueryItem(
                        name: "daily",
                        value: "weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max"
                    ),
                    URLQueryItem(
                        name: "start_date",
                        value: window.startDate.ISO8601Format(.iso8601Date(timeZone: .current))
                    ),
                    URLQueryItem(
                        name: "end_date",
                        value: window.endDate.ISO8601Format(.iso8601Date(timeZone: .current))
                    ),
                    URLQueryItem(name: "timezone", value: "auto"),
                ]

                guard let url = components?.url else {
                    throw WeatherForecastError.requestFailed
                }

                let data: Data
                let response: URLResponse
                do {
                    (data, response) = try await URLSession.shared.data(from: url)
                } catch {
                    if Task.isCancelled {
                        throw CancellationError()
                    }
                    throw WeatherForecastError.requestFailed
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode)
                else {
                    throw WeatherForecastError.requestFailed
                }

                let decoded: OpenMeteoForecastResponse
                do {
                    decoded = try JSONDecoder().decode(OpenMeteoForecastResponse.self, from: data)
                } catch {
                    throw WeatherForecastError.invalidResponse
                }

                fetched = try decoded.makeDailyForecasts()
            } else {
                fetched = []
            }

            return try WeatherForecastTripDaysBuilder.build(
                tripStartDate: fromDate,
                numDays: forecastDays,
                today: today,
                fetched: fetched
            )
        }
    )

    public static let testValue = Self(
        fetchForecast: { _, _, _, _ in [] }
    )

    public static let previewValue = Self(
        fetchForecast: { _, _, fromDate, numDays in
            let today = Date()
            let calendar = Calendar.current
            let todayDay = calendar.startOfDay(for: today)
            guard let forecastEnd = calendar.date(byAdding: .day, value: 15, to: todayDay) else {
                return []
            }

            var fetched = [DailyWeatherForecast]()
            for offset in 0..<numDays {
                guard let date = calendar.date(byAdding: .day, value: offset, to: fromDate) else {
                    continue
                }
                let day = calendar.startOfDay(for: date)
                guard day >= todayDay, day <= forecastEnd else {
                    continue
                }
                let max = Double.random(in: -10...40)
                let min = Double.random(in: -15...max)
                fetched.append(
                    .available(
                        date: day,
                        condition: .allCases.randomElement()!,
                        maxTemperature: max,
                        minTemperature: min,
                        precipitationProbability: Int.random(in: 0...10) * 10
                    )
                )
            }

            return (try? WeatherForecastTripDaysBuilder.build(
                tripStartDate: fromDate,
                numDays: numDays,
                today: today,
                fetched: fetched
            )) ?? []
        }
    )
}

extension DependencyValues {
    nonisolated var weatherForecast: WeatherForecastClient {
        get { self[WeatherForecastClient.self] }
        set { self[WeatherForecastClient.self] = newValue }
    }
}

nonisolated enum WeatherForecastResponseMapper {
    static func makeDailyForecasts(
        times: [String],
        weatherCodes: [Int],
        maxTemperatures: [Double],
        minTemperatures: [Double],
        precipitationProbabilities: [Int]
    ) throws -> [DailyWeatherForecast] {
        let count = times.count
        guard
            weatherCodes.count == count,
            maxTemperatures.count == count,
            minTemperatures.count == count,
            precipitationProbabilities.count == count,
            count > 0
        else {
            throw WeatherForecastError.invalidResponse
        }

        return try (0..<count).map { index in
            let date: Date
            do {
                date = try Date(times[index], strategy: .iso8601.year().month().day())
            } catch {
                throw WeatherForecastError.invalidResponse
            }
            return DailyWeatherForecast.available(
                date: date,
                condition: WeatherCondition(weatherCode: weatherCodes[index]),
                maxTemperature: maxTemperatures[index],
                minTemperature: minTemperatures[index],
                precipitationProbability: precipitationProbabilities[index]
            )
        }
    }
}

private nonisolated struct OpenMeteoForecastResponse: Decodable, Sendable {
    let daily: OpenMeteoDailyPayload

    func makeDailyForecasts() throws -> [DailyWeatherForecast] {
        try WeatherForecastResponseMapper.makeDailyForecasts(
            times: daily.time,
            weatherCodes: daily.weatherCode,
            maxTemperatures: daily.temperature2mMax,
            minTemperatures: daily.temperature2mMin,
            precipitationProbabilities: daily.precipitationProbabilityMax
        )
    }
}

private nonisolated struct OpenMeteoDailyPayload: Decodable, Sendable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]
    let precipitationProbabilityMax: [Int]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
        case precipitationProbabilityMax = "precipitation_probability_max"
    }
}
