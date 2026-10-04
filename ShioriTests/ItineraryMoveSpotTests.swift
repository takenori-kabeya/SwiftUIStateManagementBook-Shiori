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
struct ItineraryMoveSpotTests {
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

    @Test func 挿入位置を指定しないとき別の日の末尾へ移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A"), makeSpot(id: spotBID, title: "B")],
            [makeSpot(id: spotCID, title: "C")],
        ])

        itinerary.moveSpot(spotID: spotAID, toDayIndex: 1)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotBID])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotCID, spotAID])
    }

    @Test func 別の日の指定位置へ行き先を移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()



        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B"), makeSpot(id: spotCID, title: "C")],
        ])
        itinerary.moveSpot(spotID: spotAID, toDayIndex: 1, toSpotIndex: 1)
        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotBID, spotAID, spotCID])
    }
    @Test func 同じ日内で後ろへ行き先を移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        var itinerary = makeItinerary(days: [
            [
                makeSpot(id: spotAID, title: "A"),
                makeSpot(id: spotBID, title: "B"),
                makeSpot(id: spotCID, title: "C"),
            ],
        ])

        // A を index 2（C の位置）へ。削除後にインデックス調整され、B, A, C になる
        itinerary.moveSpot(spotID: spotAID, toDayIndex: 0, toSpotIndex: 2)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotBID, spotAID, spotCID])
    }

    @Test func 同じ日内で前へ行き先を移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        var itinerary = makeItinerary(days: [
            [
                makeSpot(id: spotAID, title: "A"),
                makeSpot(id: spotBID, title: "B"),
                makeSpot(id: spotCID, title: "C"),
            ],
        ])

        itinerary.moveSpot(spotID: spotCID, toDayIndex: 0, toSpotIndex: 0)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotCID, spotAID, spotBID])
    }

    @Test func 日インデックスが範囲外のとき最終日の末尾へ移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.moveSpot(spotID: spotAID, toDayIndex: 99)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotBID, spotAID])
    }

    @Test func 日インデックスが負のとき一日目の末尾へ移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])

        itinerary.moveSpot(spotID: spotBID, toDayIndex: -1)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [spotAID, spotBID])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [])
    }

    @Test func 行き先インデックスが範囲外のときその日の末尾へ移動すること() {
        let spotAID = uuid()
        let spotBID = uuid()
        let spotCID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B"), makeSpot(id: spotCID, title: "C")],
        ])

        itinerary.moveSpot(spotID: spotAID, toDayIndex: 1, toSpotIndex: 100)

        #expect(itinerary.itineraryDays[0].spots.map(\.id) == [])
        #expect(itinerary.itineraryDays[1].spots.map(\.id) == [spotBID, spotCID, spotAID])
    }

    @Test func 未知の行き先IDのときは何もしないこと() {
        let spotAID = uuid()
        let spotBID = uuid()
        var itinerary = makeItinerary(days: [
            [makeSpot(id: spotAID, title: "A")],
            [makeSpot(id: spotBID, title: "B")],
        ])
        let before = itinerary

        itinerary.moveSpot(spotID: uuid(), toDayIndex: 1)

        #expect(itinerary == before)
    }
}
