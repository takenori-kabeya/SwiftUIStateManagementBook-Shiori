import Foundation
import Testing
@testable import Shiori

struct ItineraryScheduleCheckerTests {
    private func makeSpot(
        id: UUID = UUID(),
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil
    ) -> Spot {
        let startTime: Date? = hour.map { hour in
            DateComponents(calendar: .current, year: 2000, hour: hour, minute: minute).date!
        }
        return Spot(id: id, title: title, startTime: startTime, durationMinutes: durationMinutes, memo: "")
    }

    // MARK: - Order checks

    @Test func 到着時刻がない行き先のみのとき順序ずれIDは空になること() {
        let spots = [
            makeSpot(title: "A"),
            makeSpot(title: "B"),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 到着時刻がある行き先が1件のとき順序ずれIDは空になること() {
        let spots = [
            makeSpot(title: "A", hour: 10, minute: 0),
            makeSpot(title: "B"),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 並び順と到着時刻の順が一致するとき順序ずれIDは空になること() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 到着時刻がある2件の行き先の並びが逆のとき両方のIDを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idA, idB]))
        #expect(!ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 中間の行き先だけ順序がずれているときずれているIDのみを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0),
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idB, idC]))
        #expect(!ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 順序検査では到着時刻がない行き先を無視すること() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        let spots = [
            makeSpot(title: "Untimed"),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(title: "Also untimed"),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0),
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idB, idC]))
    }

    @Test func 到着時刻が同じ行き先のとき順序ずれIDは空になること() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 日付が違っても時と分だけで順序を比較すること() {
        let idA = UUID()
        let idB = UUID()
        let startTimeA = DateComponents(calendar: .current, year: 1999, hour: 10, minute: 0).date!
        let startTimeB = DateComponents(calendar: .current, year: 2025, hour: 12, minute: 0).date!
        let spots = [
            Spot(id: idB, title: "B", startTime: startTimeB, durationMinutes: nil, memo: ""),
            Spot(id: idA, title: "A", startTime: startTimeA, durationMinutes: nil, memo: ""),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idA, idB]))
    }

    // MARK: - Conflict checks

    @Test func スケジュール情報がないとき時間重なりIDは空になること() {
        let spots = [
            makeSpot(title: "A"),
            makeSpot(title: "B"),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの2件の行き先のとき時間重なりIDは空になること() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 二つの滞在時間帯が重なるとき両方のIDを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 二つの滞在時間帯が境界で接するとき時間重なりIDは空になること() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が他の滞在時間帯の内側のとき両方のIDを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が滞在時間帯の終了と一致するとき時間重なりIDは空になること() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が滞在時間帯の開始と一致するとき両方のIDを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 三件のうち一部だけ重なるとき重なっているIDのみを返すこと() {
        let idA = UUID()
        let idB = UUID()
        let idC = UUID()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 10, minute: 30, durationMinutes: 60),
            makeSpot(id: idC, title: "C", hour: 12, minute: 0, durationMinutes: 60),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 時間重なり検査では到着時刻がない行き先を無視すること() {
        let idA = UUID()
        let idB = UUID()
        let spots = [
            makeSpot(title: "Untimed"),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(title: "Also untimed"),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
    }
}
