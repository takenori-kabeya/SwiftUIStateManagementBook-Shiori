import Foundation
import Testing
@testable import Shiori

struct ItineraryConfirmCandidateTests {
    private func makeSpot(id: UUID = UUID(), title: String) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: "")
    }

    private func makeItinerary(
        candidates: [Spot],
        days: [[Spot]]
    ) -> Itinerary {
        Itinerary(
            candidateSpots: candidates,
            itineraryDays: days.map { spots in
                ItineraryDay(id: UUID(), spots: spots)
            }
        )
    }

    @Test func 指定した日の末尾へ候補を確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                [makeSpot(title: "Day1")],
                [makeSpot(id: existingID, title: "Day2")],
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayIndex: 1)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[0].spots.map(\.title) == ["Day1"])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [existingID, candidateID])
    }

    @Test func 一日目を指定したとき一日目の末尾へ候補を確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                [makeSpot(id: existingID, title: "Day1")],
                [makeSpot(title: "Day2")],
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayIndex: 0)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [existingID, candidateID])
        #expect(itinerary.itineraryDays[1].spots.map(\.title) == ["Day2"])
    }

    @Test func 日インデックスが範囲外のとき最終日の末尾へ確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                [makeSpot(title: "Day1")],
                [makeSpot(id: existingID, title: "Day2")],
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayIndex: 99)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [existingID, candidateID])
    }

    @Test func 日インデックスが負のとき一日目の末尾へ確定すること() {
        let candidateID = UUID()
        let existingID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                [makeSpot(id: existingID, title: "Day1")],
                [makeSpot(title: "Day2")],
            ]
        )

        itinerary.confirmCandidate(spotID: candidateID, toDayIndex: -1)

        #expect(itinerary.candidateSpots.map(\.id) == [])
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [existingID, candidateID])
    }

    @Test func 未知の行き先IDのときは何もしないこと() {
        let candidateID = UUID()
        var itinerary = makeItinerary(
            candidates: [makeSpot(id: candidateID, title: "候補")],
            days: [
                [makeSpot(title: "Day1")],
                [],
            ]
        )
        let before = itinerary

        itinerary.confirmCandidate(spotID: UUID(), toDayIndex: 0)

        #expect(itinerary == before)
    }
}
