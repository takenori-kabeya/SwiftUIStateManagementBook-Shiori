import Foundation
import Testing
@testable import Shiori

struct ItineraryConfirmCandidateTests {
    private func makeSpot(id: UUID = UUID(), title: String) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: "")
    }

    private func makeItinerary(
        candidates: [Spot],
        days: [(id: UUID, spots: [Spot])]
    ) -> Itinerary {
        Itinerary(
            candidateSpots: candidates,
            itineraryDays: days.map { day in
                ItineraryDay(id: day.id, spots: day.spots)
            }
        )
    }

    @Test func 指定した日の末尾へ候補を確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        let day1ID = UUID()
        let day2ID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                (id: day1ID, spots: [makeSpot(title: "Day1")]),
                (id: day2ID, spots: [makeSpot(id: existingID, title: "Day2")]),
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayID: day2ID)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[0].spots.map(\.title) == ["Day1"])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [existingID, candidateID])
    }

    @Test func 一日目を指定したとき一日目の末尾へ候補を確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        let day1ID = UUID()
        let day2ID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                (id: day1ID, spots: [makeSpot(id: existingID, title: "Day1")]),
                (id: day2ID, spots: [makeSpot(title: "Day2")]),
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayID: day1ID)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [existingID, candidateID])
        #expect(itinerary.itineraryDays[1].spots.map(\.title) == ["Day2"])
    }

    @Test func 未知の日IDのときは何もしないこと() {
        let candidateID = UUID()
        let day1ID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                (id: day1ID, spots: [makeSpot(title: "Day1")]),
                (id: UUID(), spots: []),
            ]
        )
        let before = itinerary

        itinerary.confirmCandidate(spotID: candidateID, toDayID: UUID())

        #expect(itinerary == before)
    }

    @Test func 未知の行き先IDのときは何もしないこと() {
        let candidateID = UUID()
        let day1ID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                (id: day1ID, spots: [makeSpot(title: "Day1")]),
                (id: UUID(), spots: []),
            ]
        )
        let before = itinerary

        itinerary.confirmCandidate(spotID: UUID(), toDayID: day1ID)

        #expect(itinerary == before)
    }
}
