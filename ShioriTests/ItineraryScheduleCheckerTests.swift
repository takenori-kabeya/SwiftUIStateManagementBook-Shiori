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
struct ItineraryScheduleCheckerTests {
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

    // MARK: - Order checks

    @Test func 到着時刻がない行き先のみのとき順序ずれIDは空になること() {
        let spots = [
            makeSpot(id: uuid(), title: "A"),
            makeSpot(id: uuid(), title: "B"),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 到着時刻がある行き先が一件のとき順序ずれIDは空になること() {
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0),
            makeSpot(id: uuid(), title: "B"),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 並び順と到着時刻の順が一致するとき順序ずれIDは空になること() {
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 到着時刻がある二件の行き先の並びが逆のとき両方のIDを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idA, idB]))
        #expect(!ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 中間の行き先だけ順序がずれているときずれているIDのみを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
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
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
        let spots = [
            makeSpot(id: uuid(), title: "Untimed"),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: uuid(), title: "Also untimed"),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0),
            makeSpot(id: idB, title: "B", hour: 12, minute: 0),
        ]

        let misaligned = ItineraryScheduleChecker.misalignedSpotIDs(in: spots)

        #expect(misaligned == Set([idB, idC]))
    }

    @Test func 到着時刻が同じ行き先のとき順序ずれIDは空になること() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.misalignedSpotIDs(in: spots).isEmpty)
        #expect(ItineraryScheduleChecker.isTimeOrderConsistent(in: spots))
    }

    @Test func 日付が違っても時と分だけで順序を比較すること() {
        let idA = uuid()
        let idB = uuid()
        let startTimeA = SpotTime(hour: 10, minute: 0)
        let startTimeB = SpotTime(hour: 12, minute: 0)
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
            makeSpot(id: uuid(), title: "A"),
            makeSpot(id: uuid(), title: "B"),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの二件の行き先のとき時間重なりIDは空になること() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 二つの滞在時間帯が重なるとき両方のIDを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 二つの滞在時間帯が境界で接するとき時間重なりIDは空になること() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が他の滞在時間帯の内側のとき両方のIDを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が滞在時間帯の終了と一致するとき時間重なりIDは空になること() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: spots).isEmpty)
        #expect(!ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 到着時刻のみの行き先が滞在時間帯の開始と一致するとき両方のIDを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: idB, title: "B", hour: 10, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
        #expect(ItineraryScheduleChecker.hasTimeConflicts(in: spots))
    }

    @Test func 三件のうち一部だけ重なるとき重なっているIDのみを返すこと() {
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
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
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: uuid(), title: "Untimed"),
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 120),
            makeSpot(id: uuid(), title: "Also untimed"),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0),
        ]

        let conflicting = ItineraryScheduleChecker.conflictingSpotIDs(in: spots)

        #expect(conflicting == Set([idA, idB]))
    }
}
