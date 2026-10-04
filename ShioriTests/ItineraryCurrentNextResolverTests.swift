import Foundation
import Testing
@testable import Shiori

struct ItineraryCurrentNextResolverTests {
    private func makeSpot(
        id: UUID = UUID(),
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
            ItineraryDay(id: UUID(), spots: spots)
        }
        return Itinerary(candidateSpots: [], itineraryDays: itineraryDays)
    }

    // MARK: - Current spot

    @Test func 現在時刻が滞在時間帯の内側のとき現在の予定を返すこと() {
        let id = UUID()
        let itinerary = makeItinerary(days: [
            [makeSpot(id: id, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current?.id == id)
    }

    @Test func 現在時刻が滞在開始より前のとき現在の予定を返さないこと() {
        let itinerary = makeItinerary(days: [
            [makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 0)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
    }

    @Test func 現在時刻が滞在終了と一致するとき現在の予定を返さないこと() {
        let itinerary = makeItinerary(days: [
            [makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
    }

    @Test func 現在の予定の検索では滞在時間がない行き先を無視すること() {
        let itinerary = makeItinerary(days: [
            [makeSpot(title: "スカイツリー", hour: 10, minute: 30)],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
    }

    // MARK: - Next spot

    @Test func 現在の予定があるとき並び順で次の予定を返すこと() {
        let nextID = UUID()
        let itinerary = makeItinerary(days: [
            [
                makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
                makeSpot(id: nextID, title: "スカイツリー"),
            ],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == nextID)
    }

    @Test func 現在の予定が最後の行き先のとき次の予定を返さないこと() {
        let itinerary = makeItinerary(days: [
            [makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30)],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 45)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next == nil)
    }

    @Test func 現在の予定がないとき旅程順で最初のこれからの予定を返すこと() {
        let idB = UUID()
        let itinerary = makeItinerary(days: [
            [
                makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
                makeSpot(id: idB, title: "上野", hour: 14, minute: 0, durationMinutes: 60),
                makeSpot(title: "スカイツリー", hour: 12, minute: 0, durationMinutes: 60),
            ],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == idB)
    }

    @Test func 時刻指定の行き先がすべて終了しているとき最後に終了した行き先の次を返すこと() {
        let nextID = UUID()
        let itinerary = makeItinerary(days: [
            [
                makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
                makeSpot(id: nextID, title: "スカイツリー"),
            ],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 11, minute: 0)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == nextID)
    }

    @Test func 最初の滞在開始より前のときこれからの到着時刻でもっとも早い行き先を返すこと() {
        let nextID = UUID()
        let itinerary = makeItinerary(days: [
            [
                makeSpot(id: nextID, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
                makeSpot(title: "スカイツリー", hour: 13, minute: 0, durationMinutes: 60),
            ],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 9, minute: 0)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == nextID)
    }

    // MARK: - Multi-day

    @Test func 旅行開始日を基準にした当日の行き先を現在の予定として返すこと() {
        let day1Spot = makeSpot(title: "Day1", hour: 10, minute: 0, durationMinutes: 60)
        let day2SpotID = UUID()
        let day2Spot = makeSpot(id: day2SpotID, title: "Day2", hour: 10, minute: 0, durationMinutes: 60)

        let itinerary = makeItinerary(days: [
            [day1Spot],
            [day2Spot],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 2, hour: 10, minute: 30)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current?.id == day2SpotID)
    }

    @Test func 当日の行き先がすべて終了しているとき翌日の行き先を次の予定として返すこと() {
        let day1Spot = makeSpot(title: "Day1", hour: 10, minute: 0, durationMinutes: 60)
        let day2NextID = UUID()
        let day2Spot = makeSpot(id: day2NextID, title: "Day2", hour: 9, minute: 0, durationMinutes: 60)

        let itinerary = makeItinerary(days: [
            [day1Spot],
            [day2Spot],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 1, hour: 12, minute: 0)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == day2NextID)
    }

    @Test func 旅行開始前なら現在の予定を返さないこと() {
        let firstSpot = makeSpot(title: "First", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [[firstSpot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2023, month: 12, day: 31, hour: 15, minute: 0)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
    }

    @Test func 旅行開始前なら最初の行き先を次の予定として返すこと() {
        let firstSpotID = UUID()
        let firstSpot = makeSpot(id: firstSpotID, title: "First", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [[firstSpot]])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2023, month: 12, day: 31, hour: 15, minute: 0)

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(next?.id == firstSpotID)
    }

    @Test func 旅行終了後なら現在の予定も次の予定も返さないこと() {
        let day1Spot = makeSpot(title: "Day1", hour: 10, minute: 0, durationMinutes: 60)
        let day2Spot = makeSpot(title: "Day2", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [day1Spot],
            [day2Spot],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 3, hour: 10, minute: 0)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )
        let next = ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
        #expect(next == nil)
    }

    @Test func 同じ到着時刻でも一日目と二日目の行き先を混同しないこと() {
        let day1SpotID = UUID()
        let day2SpotID = UUID()
        let day1Spot = makeSpot(id: day1SpotID, title: "Day1", hour: 10, minute: 0, durationMinutes: 60)
        let day2Spot = makeSpot(id: day2SpotID, title: "Day2", hour: 10, minute: 0, durationMinutes: 60)
        let itinerary = makeItinerary(days: [
            [day1Spot],
            [day2Spot],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let day1Now = makeDate(year: 2024, month: 1, day: 1, hour: 10, minute: 30)
        let day2Now = makeDate(year: 2024, month: 1, day: 2, hour: 10, minute: 30)

        let day1Current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: day1Now
        )
        let day2Current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: day2Now
        )

        #expect(day1Current?.id == day1SpotID)
        #expect(day1Current?.id != day2SpotID)
        #expect(day2Current?.id == day2SpotID)
        #expect(day2Current?.id != day1SpotID)
    }

    // β版制限: 日をまたぐ滞在は現在の予定にしない
    @Test func 前日二十三時開始の行き先を翌日一時に現在の予定としないこと() {
        let overnightSpot = makeSpot(title: "Overnight", hour: 23, minute: 0, durationMinutes: 180)
        let itinerary = makeItinerary(days: [
            [overnightSpot],
        ])

        let tripStart = makeDate(year: 2024, month: 1, day: 1, hour: 0, minute: 0)
        let now = makeDate(year: 2024, month: 1, day: 2, hour: 1, minute: 0)

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStart,
            now: now
        )

        #expect(current == nil)
    }
}
