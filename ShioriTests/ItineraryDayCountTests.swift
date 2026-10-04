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
struct ItineraryDayCountTests {
    @Dependency(\.uuid) var uuid
    
    private func makeSpot(id: UUID, title: String) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: "")
    }

    private func makeItinerary(days: [[Spot]]) -> Itinerary {
        Itinerary(
            candidateSpots: [],
            itineraryDays: days.map { spots in
                ItineraryDay(id: uuid(), spots: spots)
            }
        )
    }

    @Test func 二日から三日に増やすとき空の三日目が増えること() {
        let day1SpotID = uuid()
        let day2SpotID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: day1SpotID, title: "Day1")],
            [makeSpot(id: day2SpotID, title: "Day2")],
        ])

        itinerary.setDayCount(3)

        #expect(itinerary.itineraryDays.count == 3)
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [day1SpotID])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [day2SpotID])
        #expect(itinerary.itineraryDays[2].spots.isEmpty)
    }

    @Test func 三日から二日に減らすとき三日目の行き先が二日目の末尾へ順序を保って移ること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        let spotDID = uuid()
        let spotEID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B"), makeSpot(id: spotCID, title: "C")],
            [makeSpot(id: spotDID, title: "D"), makeSpot(id: spotEID, title: "E")],
        ])

        itinerary.setDayCount(2)

        #expect(itinerary.itineraryDays.count == 2)
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotAID])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotBID, spotCID, spotDID, spotEID])
    }

    @Test func 三日から一日に減らすとき二日目と三日目の行き先が順番どおり一日目の末尾へ来ること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        let spotDID = uuid()
        let spotEID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B"), makeSpot(id: spotCID, title: "C")],
            [makeSpot(id: spotDID, title: "D"), makeSpot(id: spotEID, title: "E")],
        ])

        itinerary.setDayCount(1)

        #expect(itinerary.itineraryDays.count == 1)
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotAID, spotBID, spotCID, spotDID, spotEID])
    }

    @Test func 零日を指定しても一日残ること() {
        let spotAID = uuid()
        let spotBID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.setDayCount(0)

        #expect(itinerary.itineraryDays.count == 1)
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotAID, spotBID])
    }
}
