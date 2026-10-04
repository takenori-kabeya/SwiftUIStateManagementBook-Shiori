import Foundation
import Testing
@testable import Shiori

/// `ItineraryFeature.autoShiftButtonTapped` が呼ぶドメイン処理の検証
struct ItineraryFeatureTests {
    private func makeSpot(
        id: UUID = UUID(),
        title: String,
        hour: Int? = nil,
        minute: Int = 0,
        durationMinutes: Int? = nil
    ) -> Spot {
        let startTime: SpotTime? = hour.map { SpotTime(hour: $0, minute: minute) }
        return Spot(
            id: id,
            title: title,
            startTime: startTime,
            durationMinutes: durationMinutes,
            memo: ""
        )
    }

    @Test func 指定した日の時間重なりだけを解消し他の日は変えないこと() {
        let day1ID = UUID()
        let day2ID = UUID()
        var itinerary = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: day1ID,
                    spots: [
                        makeSpot(title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
                ItineraryDay(
                    id: day2ID,
                    spots: [
                        makeSpot(title: "Day2Only", hour: 9, minute: 0, durationMinutes: 30),
                    ]
                ),
            ]
        )
        let day2Before = itinerary.itineraryDays[1]

        itinerary.resolveScheduleConflicts(dayID: day1ID)

        #expect(ItineraryScheduleChecker.conflictingSpotIDs(in: itinerary.itineraryDays[0].spots).isEmpty)
        #expect(itinerary.itineraryDays[0].spots[1].startTime == SpotTime(hour: 11, minute: 30))
        #expect(itinerary.itineraryDays[1] == day2Before)
    }

    @Test func 未知の日IDのときは何もしないこと() {
        let dayID = UUID()
        var itinerary = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: dayID,
                    spots: [
                        makeSpot(title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
            ]
        )
        let before = itinerary

        itinerary.resolveScheduleConflicts(dayID: UUID())

        #expect(itinerary == before)
    }
}
