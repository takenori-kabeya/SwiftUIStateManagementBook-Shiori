import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

@Suite(
    .dependencies {
        $0.uuid = .incrementing
    }
)
struct ItineraryCurrentNextResolverTests {
    @Dependency(\.uuid) var uuid

    private func makeSpot(
        id: UUID,
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil
    ) -> Spot {
        let startTime: SpotTime? = hour.map { hour in
            SpotTime(hour: hour, minute: minute)
        }
        return Spot(id: id, title: title, startTime: startTime, durationMinutes: durationMinutes, memo: "")
    }

    private func makeDate(year: Int, month: Int, day: Int, hour: Int = 0, minute: Int = 0) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)!
    }

    private func makeItinerary(days: [[Spot]]) -> Itinerary {
        let itineraryDays = days.map { spots in
            ItineraryDay(id: uuid(), spots: spots)
        }
        return Itinerary(candidateSpots: [], itineraryDays: itineraryDays)
    }

    private func highlight(
        in itinerary: Itinerary,
        tripStart: Date,
        now: Date
    ) -> ItineraryCurrentNextResolver.TripSpotHighlight {
        ItineraryCurrentNextResolver.highlight(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )
    }

    // MARK: - 旅行開始日前日以前

    @Test func 旅行開始日前日以前は現在の予定を表示せず予定時刻が逆転していても並び順の先頭を最初の予定とすること() {
        let first = makeSpot(id: uuid(), title: "浅草寺", hour: 13, minute: 30, durationMinutes: 30)
        let earlierClock = makeSpot(id: uuid(), title: "スカイツリー", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [first, earlierClock],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 10)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 9)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .hidden)
        #expect(result.next == .firstSpot(first))
    }

    @Test func 旅行開始日前日以前は先頭の空日を飛ばして予定がある日の先頭を最初の予定とすること() {
        let first = makeSpot(id: uuid(), title: "浅草寺", hour: 13, minute: 30, durationMinutes: 30)
        let later = makeSpot(id: uuid(), title: "スカイツリー", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [],
            [],
            [first, later],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 10)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 9)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .hidden)
        #expect(result.next == .firstSpot(first))
    }

    @Test func 旅行開始日前日以前に確定済み行き先が一件もなければ予定なしとすること() {
        let itinerary = makeItinerary(days: [
            [],
            [],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 10)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 9)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .hidden)
        #expect(result.next == .noneRegistered)
    }

    // MARK: - 旅行開始日〜最終日・現在の予定

    @Test func 現在日時が滞在時間帯の内側のときその行き先を現在の予定とすること() {
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(spot))
    }

    @Test func 現在日時が予定日時と一致するときその行き先を現在の予定とすること() {
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 30)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(spot))
    }

    @Test func 現在日時が予定日時より前のときは現在の予定にせず移動中とすること() {
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .moving)
        #expect(result.next == .spot(spot))
    }

    @Test func 現在日時が滞在終了と一致するときは現在の予定にしないこと() {
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .scheduleFinished)
        #expect(result.next == .scheduleFinished)
    }

    @Test func 滞在時間がない行き先は現在の予定にしないこと() {
        let spot = makeSpot(id: uuid(), title: "スカイツリー", hour: 10, minute: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .scheduleFinished)
        #expect(result.next == .scheduleFinished)
    }

    @Test func 同じ到着時刻でも一日目と二日目の行き先を混同しないこと() {
        let day1 = makeSpot(id: uuid(), title: "一日目", hour: 10, minute: 0, durationMinutes: 60)
        let day2 = makeSpot(id: uuid(), title: "二日目", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [day1],
            [day2],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let day1Now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 30)
        let day2Now = makeDate(year: 2024, month: 1, day: 2, hour: 10, minute: 30)

        let day1Result = highlight(in: itinerary, tripStart: tripStart, now: day1Now)
        let day2Result = highlight(in: itinerary, tripStart: tripStart, now: day2Now)

        #expect(day1Result.current == .spot(day1))
        #expect(day1Result.next == .spot(day2))
        #expect(day2Result.current == .spot(day2))
        #expect(day2Result.next == .scheduleFinished)
    }

    @Test func 滞在が重なるときは並び順が最後の行き先を現在の予定としその次を次の予定とすること() {
        let earlier = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 0, durationMinutes: 120)
        let later = makeSpot(id: uuid(), title: "上野", hour: 11, minute: 0, durationMinutes: 60)
        let following = makeSpot(id: uuid(), title: "スカイツリー", hour: 13, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [earlier, later, following],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 30)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(later))
        #expect(result.next == .spot(following))
    }

    // MARK: - 旅行開始日〜最終日・次の予定

    @Test func 現在の予定があるとき並び順で直後の行き先を次の予定とすること() {
        let current = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 0, durationMinutes: 60)
        let immediate = makeSpot(id: uuid(), title: "上野", hour: 15, minute: 0, durationMinutes: 60)
        let earlierClock = makeSpot(id: uuid(), title: "スカイツリー", hour: 12, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [current, immediate, earlierClock],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 30)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(current))
        #expect(result.next == .spot(immediate))
    }

    @Test func 現在の予定がその日の最後であるとき空日を飛ばした次の日の先頭を次の予定とすること() {
        let current = makeSpot(id: uuid(), title: "上野", hour: 14, minute: 0, durationMinutes: 60)
        let nextDayFirst = makeSpot(id: uuid(), title: "スカイツリー", hour: 12, minute: 0, durationMinutes: 60)
        let nextDayEarlierClock = makeSpot(id: uuid(), title: "新宿御苑", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [
                makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 0, durationMinutes: 60),
                current,
            ],
            [],
            [nextDayFirst, nextDayEarlierClock],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 14, minute: 20)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(current))
        #expect(result.next == .spot(nextDayFirst))
    }

    @Test func 現在の予定が旅程の最後であるとき次の予定を予定終了とすること() {
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .spot(spot))
        #expect(result.next == .scheduleFinished)
    }

    @Test func 現在の予定がないとき現在日時以降でもっとも予定日時が早い行き先を次の予定とすること() {
        let finished = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 0, durationMinutes: 30)
        let laterClock = makeSpot(id: uuid(), title: "上野", hour: 14, minute: 0, durationMinutes: 60)
        let earliest = makeSpot(id: uuid(), title: "スカイツリー", hour: 12, minute: 0, durationMinutes: 60)
        let nextDayEarlyClock = makeSpot(id: uuid(), title: "新宿御苑", hour: 9, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [finished, laterClock, earliest],
            [nextDayEarlyClock],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .moving)
        #expect(result.next == .spot(earliest))
    }

    @Test func 予定日時が現在日時と一致し滞在時間がないときはその行き先を次の予定とすること() {
        let spot = makeSpot(id: uuid(), title: "スカイツリー", hour: 10, minute: 0)
        let itinerary = makeItinerary(days: [[spot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .moving)
        #expect(result.next == .spot(spot))
    }

    @Test func 時刻設定のある予定が現在日時以降に一件もないときは現在の予定も次の予定も予定終了とすること() {
        let finished = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)
        let untimed = makeSpot(id: uuid(), title: "スカイツリー")
        let itinerary = makeItinerary(days: [
            [finished, untimed],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .scheduleFinished)
        #expect(result.next == .scheduleFinished)
    }

    // MARK: - 旅行最終日翌日以降

    @Test func 旅行最終日翌日以降は現在の予定を表示せず次の予定を予定終了とすること() {
        let day1 = makeSpot(id: uuid(), title: "一日目", hour: 10, minute: 0, durationMinutes: 60)
        let day2 = makeSpot(id: uuid(), title: "二日目", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [day1],
            [day2],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1)
        let now = makeDate(year: 2024, month: 1, day: 3, hour: 10, minute: 0)

        let result = highlight(in: itinerary, tripStart: tripStart, now: now)

        #expect(result.current == .hidden)
        #expect(result.next == .scheduleFinished)
    }
}
