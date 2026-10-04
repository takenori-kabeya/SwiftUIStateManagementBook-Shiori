import Foundation
import Testing
@testable import Shiori

/// 旅行全日程と API 取得結果のマージを検証する
struct WeatherForecastTripDaysBuilderTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Date.makeDate(year: year, month: month, day: day)
    }

    private func availableForecast(date: Date) -> DailyWeatherForecast {
        .available(
            date: date,
            condition: .clearSky,
            maxTemperature: 30.0,
            minTemperature: 22.0,
            precipitationProbability: 10
        )
    }

    private func fetchedRange(from start: Date, count: Int) -> [DailyWeatherForecast] {
        (0..<count).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: start) else {
                return nil
            }
            return availableForecast(date: day)
        }
    }

    @Test func 旅行が今日始まるときすべてavailableを返すこと() throws {
        let today = date(2026, 8, 10)
        let fetched = fetchedRange(from: today, count: 3)

        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: today,
            numDays: 3,
            today: today,
            fetched: fetched,
            calendar: calendar
        )

        #expect(result.count == 3)
        #expect(result.allSatisfy {
            if case .available = $0.availability { return true }
            return false
        })
    }

    @Test func 旅行が過去日を含むときpastDayとavailableを付けること() throws {
        let today = date(2026, 8, 10)
        let tripStart = date(2026, 8, 8)
        let fetched = fetchedRange(from: today, count: 6)

        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: tripStart,
            numDays: 8,
            today: today,
            fetched: fetched,
            calendar: calendar
        )

        #expect(result.count == 8)
        #expect(result[0].availability == .pastDay)
        #expect(result[1].availability == .pastDay)
        #expect(result[2..<8].allSatisfy {
            if case .available = $0.availability { return true }
            return false
        })
    }

    @Test func 旅行が予報外の未来を含むときavailableとoutsideForecastPeriodを付けること() throws {
        let today = date(2026, 8, 10)
        let tripStart = date(2026, 8, 20)
        let fetched = fetchedRange(from: tripStart, count: 6)

        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: tripStart,
            numDays: 10,
            today: today,
            fetched: fetched,
            calendar: calendar
        )

        #expect(result.count == 10)
        #expect(result[0..<6].allSatisfy {
            if case .available = $0.availability { return true }
            return false
        })
        #expect(result[6..<10].allSatisfy {
            $0.availability == .outsideForecastPeriod
        })
    }

    @Test func 旅行がすべて予報期間外のときすべてoutsideForecastPeriodにすること() throws {
        let today = date(2026, 8, 10)
        let tripStart = date(2026, 8, 26)

        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: tripStart,
            numDays: 3,
            today: today,
            fetched: [],
            calendar: calendar
        )

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.availability == .outsideForecastPeriod })
    }

    @Test func 旅行がすべて過去のときすべてpastDayにすること() throws {
        let today = date(2026, 8, 10)
        let tripStart = date(2026, 8, 1)

        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: tripStart,
            numDays: 3,
            today: today,
            fetched: [],
            calendar: calendar
        )

        #expect(result.count == 3)
        #expect(result.allSatisfy { $0.availability == .pastDay })
    }

    @Test func 予報期間内の取得欠けでinvalidResponseを投げること() {
        let today = date(2026, 8, 10)
        let fetched = [availableForecast(date: today)]

        #expect(throws: WeatherForecastError.invalidResponse) {
            try WeatherForecastTripDaysBuilder.build(
                tripStartDate: today,
                numDays: 2,
                today: today,
                fetched: fetched,
                calendar: calendar
            )
        }
    }

    @Test func numDaysが零以下のとき空を返すこと() throws {
        let result = try WeatherForecastTripDaysBuilder.build(
            tripStartDate: date(2026, 8, 10),
            numDays: 0,
            today: date(2026, 8, 10),
            fetched: [],
            calendar: calendar
        )

        #expect(result.isEmpty)
    }
}
