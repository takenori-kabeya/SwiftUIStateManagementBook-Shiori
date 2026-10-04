import Foundation
import Testing
@testable import Shiori

struct ItineraryCurrentNextResolverTests {
    private let calendar = Calendar.current

    private func makeSpot(
        id: UUID = UUID(),
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil,
        year: Int = 2000
    ) -> Spot {
        let startTime: Date? = hour.map { hour in
            DateComponents(calendar: calendar, year: year, hour: hour, minute: minute).date!
        }
        return Spot(id: id, title: title, startTime: startTime, durationMinutes: durationMinutes, memo: "")
    }

    private func makeNow(hour: Int, minute: Int = 0) -> Date {
        let today = calendar.dateComponents([.year, .month, .day], from: Date())
        return DateComponents(
            calendar: calendar,
            year: today.year,
            month: today.month,
            day: today.day,
            hour: hour,
            minute: minute
        ).date!
    }

    // MARK: - Current spot

    @Test func 現在時刻が滞在時間帯の内側のとき現在の予定を返すこと() {
        let id = UUID()
        let spots = [
            makeSpot(id: id, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
        ]

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 45),
            calendar: calendar
        )

        #expect(current?.id == id)
    }

    @Test func 現在時刻が滞在開始より前のとき現在の予定を返さないこと() {
        let spots = [
            makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
        ]

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 0),
            calendar: calendar
        )

        #expect(current == nil)
    }

    @Test func 現在時刻が滞在終了と一致するとき現在の予定を返さないこと() {
        let spots = [
            makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
        ]

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: spots,
            at: makeNow(hour: 11, minute: 0),
            calendar: calendar
        )

        #expect(current == nil)
    }

    @Test func 現在の予定の検索では滞在時間がない行き先を無視すること() {
        let id = UUID()
        let spots = [
            makeSpot(id: id, title: "スカイツリー", hour: 10, minute: 30),
        ]

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 45),
            calendar: calendar
        )

        #expect(current == nil)
    }

    @Test func 現在の予定の検索では日付が違っても時と分だけで比較すること() {
        let id = UUID()
        let spots = [
            makeSpot(id: id, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30, year: 1999),
        ]

        let current = ItineraryCurrentNextResolver.currentSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 45),
            calendar: calendar
        )

        #expect(current?.id == id)
    }

    // MARK: - Next spot

    @Test func 現在の予定があるとき並び順で次の予定を返すこと() {
        let currentID = UUID()
        let nextID = UUID()
        let spots = [
            makeSpot(id: currentID, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
            makeSpot(id: nextID, title: "スカイツリー"),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 45),
            calendar: calendar
        )

        #expect(next?.id == nextID)
    }

    @Test func 現在の予定が最後の行き先のとき次の予定を返さないこと() {
        let spots = [
            makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 10, minute: 45),
            calendar: calendar
        )

        #expect(next == nil)
    }

    @Test func 現在の予定がないとき旅程順で最初のこれからの予定を返すこと() {
        let idB = UUID()
        let idC = UUID()
        let spots = [
            makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
            makeSpot(id: idB, title: "上野", hour: 14, minute: 0, durationMinutes: 60),
            makeSpot(id: idC, title: "スカイツリー", hour: 12, minute: 0, durationMinutes: 60),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 11, minute: 0),
            calendar: calendar
        )

        #expect(next?.id == idB)
    }

    @Test func 時刻指定の行き先がすべて終了しているとき最後に終了した行き先の次を返すこと() {
        let nextID = UUID()
        let spots = [
            makeSpot(title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30),
            makeSpot(id: nextID, title: "スカイツリー"),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 11, minute: 0),
            calendar: calendar
        )

        #expect(next?.id == nextID)
    }

    @Test func 予定時刻が旅程順と逆転していても旅程順を優先すること() {
        let nextID = UUID()
        let spots = [
            makeSpot(id: nextID, title: "浅草寺", hour: 13, minute: 0, durationMinutes: 30),
            makeSpot(title: "スカイツリー", hour: 10, minute: 0, durationMinutes: 60),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 9, minute: 0),
            calendar: calendar
        )

        #expect(next?.id == nextID)
    }

    @Test func 次の予定の検索では日付が違っても時と分だけで比較すること() {
        let nextID = UUID()
        let spots = [
            makeSpot(id: nextID, title: "浅草寺", hour: 10, minute: 30, durationMinutes: 30, year: 2025),
            makeSpot(title: "スカイツリー", hour: 13, minute: 0, durationMinutes: 60, year: 1999),
        ]

        let next = ItineraryCurrentNextResolver.nextSpot(
            in: spots,
            at: makeNow(hour: 9, minute: 0),
            calendar: calendar
        )

        #expect(next?.id == nextID)
    }
}
