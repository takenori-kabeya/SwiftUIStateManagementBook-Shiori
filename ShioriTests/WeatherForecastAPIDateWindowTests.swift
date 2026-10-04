import Foundation
import Testing
@testable import Shiori

/// Open-Meteo に渡す start_date / end_date の算出を検証する
struct WeatherForecastAPIDateWindowTests {
    private let calendar = Calendar.current

    private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Date.makeDate(year: year, month: month, day: day)
    }

    @Test func 旅行が今日始まるとき開始日と終了日をそのまま使うこと() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 10),
            numDays: 3,
            today: today,
            calendar: calendar
        )

        #expect(window == WeatherForecastAPIDateWindow(
            startDate: date(2026, 8, 10),
            endDate: date(2026, 8, 12)
        ))
    }

    @Test func 旅行がすでに始まっているとき開始日を今日に揃えること() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 8),
            numDays: 5,
            today: today,
            calendar: calendar
        )

        #expect(window == WeatherForecastAPIDateWindow(
            startDate: date(2026, 8, 10),
            endDate: date(2026, 8, 12)
        ))
    }

    @Test func 予報期間内の未来旅行は旅行の日付を使うこと() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 20),
            numDays: 3,
            today: today,
            calendar: calendar
        )

        #expect(window == WeatherForecastAPIDateWindow(
            startDate: date(2026, 8, 20),
            endDate: date(2026, 8, 22)
        ))
    }

    @Test func 旅行が予報終了を超えるとき終了日を予報終了に揃えること() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 20),
            numDays: 10,
            today: today,
            calendar: calendar
        )

        #expect(window == WeatherForecastAPIDateWindow(
            startDate: date(2026, 8, 20),
            endDate: date(2026, 8, 25)
        ))
    }

    @Test func 予報最終日の一日旅行が含まれること() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 25),
            numDays: 1,
            today: today,
            calendar: calendar
        )

        #expect(window == WeatherForecastAPIDateWindow(
            startDate: date(2026, 8, 25),
            endDate: date(2026, 8, 25)
        ))
    }

    @Test func 予報期間後に始まる旅行はnilを返すこと() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 26),
            numDays: 3,
            today: today,
            calendar: calendar
        )

        #expect(window == nil)
    }

    @Test func すでに終了した旅行はnilを返すこと() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 1),
            numDays: 3,
            today: today,
            calendar: calendar
        )

        #expect(window == nil)
    }

    @Test func numDaysが零以下のときnilを返すこと() {
        let today = date(2026, 8, 10)
        let window = WeatherForecastAPIDateWindow.make(
            tripStartDate: date(2026, 8, 10),
            numDays: 0,
            today: today,
            calendar: calendar
        )

        #expect(window == nil)
    }
}
