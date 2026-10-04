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
struct ItineraryScheduleAdjusterTests {
    @Dependency(\.uuid) var uuid
    
    private func makeSpot(
        id: UUID,
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil,
        memo: String = ""
    ) -> Spot {
        let startTime: SpotTime? = hour.map { SpotTime(hour: $0, minute: minute) }
        return Spot(
            id: id,
            title: title,
            startTime: startTime,
            durationMinutes: durationMinutes,
            memo: memo
        )
    }

    @Test func 時間重なりがないとき行き先を変えないこと() {
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 60),
            makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted == spots)
    }

    @Test func 二つの滞在時間帯が重なるとき後ろの開始時刻を前の終了へずらすこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 90), // 10:00 - 11:30
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60), // 11:00 - 12:00
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted[0].id == idA)
        #expect(adjusted[0].startTime == SpotTime(hour: 10, minute: 0))
        #expect(adjusted[0].durationMinutes == 90)
        #expect(adjusted[1].id == idB)
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(adjusted[1].durationMinutes == 60)
        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: adjusted).isEmpty)
    }

    @Test func 二つの滞在時間帯が境界で接するときずらさないこと() {
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 60), // 10:00 - 11:00
            makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60), // 11:00 - 12:00
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted == spots)
    }

    @Test func 一つずらすと次も重なるとき連鎖してずらすこと() {
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 90), // 10:00 - 11:30
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60), // 11:00 - 12:00 → 11:30 - 12:30
            makeSpot(id: idC, title: "C", hour: 12, minute: 0, durationMinutes: 60), // 12:00 - 13:00 → 12:30 - 13:30
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted.map(\.id) == [idA, idB, idC])
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(adjusted[2].startTime == SpotTime(hour: 12, minute: 30))
        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: adjusted).isEmpty)
    }

    @Test func 到着時刻がない行き先は変えず調整対象から外すこと() {
        let timedAID = uuid()
        let untimedID = uuid()
        let timedBID = uuid()
        let spots = [
            makeSpot(id: timedAID, title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: untimedID, title: "Untimed"),
            makeSpot(id: timedBID, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted[1] == spots[1])
        #expect(adjusted[1].startTime == nil)
        #expect(adjusted[2].startTime == SpotTime(hour: 11, minute: 30))
        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: adjusted).isEmpty)
    }

    @Test func 到着時刻のみの行き先が前の滞在時間帯の内側のとき開始をずらすこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 60), // 10:00 - 11:00
            makeSpot(id: idB, title: "B", hour: 10, minute: 30), // 10:30
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted[1].id == idB)
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 0))
        #expect(adjusted[1].durationMinutes == nil)
        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: adjusted).isEmpty)
    }

    @Test func 並び順と到着時刻がずれていても重ならなければずらさないこと() {
        let spots = [
            makeSpot(id: uuid(), title: "LaterFirst", hour: 12, minute: 0, durationMinutes: 60), // 12:00 - 13:00
            makeSpot(id: uuid(), title: "EarlierSecond", hour: 10, minute: 0, durationMinutes: 60), // 10:00 - 11:00
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted == spots)
    }

    @Test func ずらしてもIDと滞在時間とメモは保つこと() {
        let id = uuid()
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: id, title: "B", hour: 11, minute: 0, durationMinutes: 45, memo: "メモ\n2行目"),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots)

        #expect(adjusted[1].id == id)
        #expect(adjusted[1].title == "B")
        #expect(adjusted[1].durationMinutes == 45)
        #expect(adjusted[1].memo == "メモ\n2行目")
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
    }

    @Test func 指定インデックス以降で直後だけ重なるとき直後だけずらすこと() {
        let idA = uuid()
        let idB = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots, fromIndex: 1)

        #expect(adjusted[0].startTime == SpotTime(hour: 10, minute: 0))
        #expect(adjusted[0].durationMinutes == 90)
        #expect(adjusted[1].id == idB)
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(adjusted[1].durationMinutes == 60)
    }

    @Test func 指定インデックス以降で連鎖してずらすこと() {
        let idA = uuid()
        let idB = uuid()
        let idC = uuid()
        let spots = [
            makeSpot(id: idA, title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: idB, title: "B", hour: 11, minute: 0, durationMinutes: 60),
            makeSpot(id: idC, title: "C", hour: 12, minute: 0, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots, fromIndex: 1)

        #expect(adjusted[0].id == idA)
        #expect(adjusted[0].startTime == SpotTime(hour: 10, minute: 0))
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(adjusted[2].startTime == SpotTime(hour: 12, minute: 30))
    }

    @Test func 指定インデックス以降で連鎖が切れたらその先の重なりは解消しないこと() {
        let idC = uuid()
        let idD = uuid()
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
            makeSpot(id: idC, title: "C", hour: 13, minute: 0, durationMinutes: 60),
            makeSpot(id: idD, title: "D", hour: 13, minute: 30, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots, fromIndex: 1)

        #expect(adjusted[0].startTime == SpotTime(hour: 10, minute: 0))
        #expect(adjusted[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(adjusted[2].id == idC)
        #expect(adjusted[2].startTime == SpotTime(hour: 13, minute: 0))
        #expect(adjusted[3].id == idD)
        #expect(adjusted[3].startTime == SpotTime(hour: 13, minute: 30))
    }

    @Test func 指定インデックス以降で時刻未設定は変えず後ろの判定を続けること() {
        let untimedID = uuid()
        let spots = [
            makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
            makeSpot(id: untimedID, title: "Untimed"),
            makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
        ]

        let adjusted = ItineraryScheduleAdjuster.resolvingConflictsByShiftingStartTimes(in: spots, fromIndex: 1)

        #expect(adjusted[1].id == untimedID)
        #expect(adjusted[1].startTime == nil)
        #expect(adjusted[2].startTime == SpotTime(hour: 11, minute: 30))
    }
}
