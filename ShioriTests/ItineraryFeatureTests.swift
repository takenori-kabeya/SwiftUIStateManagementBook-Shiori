import Foundation
import Testing
@testable import Shiori

/// `ItineraryFeature` を `TestStore` で検証する
@MainActor
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

    @Test func 指定した日の時間重なりだけを解消し他の日は変えないこと() async {
        let day1ID = UUID()
        let day2ID = UUID()
        let day2Spot = makeSpot(title: "Day2Only", hour: 9, minute: 0, durationMinutes: 30)
        let initial = Itinerary(
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
                    spots: [day2Spot]
                ),
            ]
        )
        let store = TestStore(initialState: ItineraryFeature.State(itinerary: initial)) {
            ItineraryFeature()
        }

        await store.send(.autoShiftButtonTapped(dayID: day1ID)) {
            $0.itinerary.itineraryDays[0].spots[1].startTime = SpotTime(hour: 11, minute: 30)
        }
    }

    @Test func 未知の日IDのときは何もしないこと() async {
        let dayID = UUID()
        let initial = Itinerary(
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
        let store = TestStore(initialState: ItineraryFeature.State(itinerary: initial)) {
            ItineraryFeature()
        }

        await store.send(.autoShiftButtonTapped(dayID: UUID()))
    }

    @Test func 確定で日IDに対応する日へ候補を移すこと() async {
        let candidateID = UUID()
        let day0ID = UUID()
        let day1ID = UUID()
        let candidate = makeSpot(id: candidateID, title: "候補")
        let day0Spot = makeSpot(title: "Day0")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [candidate],
                    itineraryDays: [
                        ItineraryDay(id: day0ID, spots: [day0Spot]),
                        ItineraryDay(id: day1ID, spots: []),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.confirmButtonTapped(spotID: candidateID, dayID: day1ID)) {
            $0.itinerary.candidateSpots = []
            $0.itinerary.itineraryDays[1].spots = [candidate]
        }
    }

    @Test func 候補へ戻すと確定済み行き先を候補へ戻すこと() async {
        let spotID = UUID()
        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: UUID(), spots: [spot])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.returnToCandidateButtonTapped(spotID: spotID)) {
            $0.itinerary.itineraryDays[0].spots = []
            $0.itinerary.candidateSpots = [spot]
        }
    }

    @Test func 上へ移動で前の行き先と入れ替えること() async {
        let spotAID = UUID()
        let spotBID = UUID()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: UUID(), spots: [spotA, spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveUpButtonTapped(spotID: spotBID)) {
            $0.itinerary.itineraryDays[0].spots = [spotB, spotA]
        }
    }

    @Test func 下へ移動で次の行き先と入れ替えること() async {
        let spotAID = UUID()
        let spotBID = UUID()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: UUID(), spots: [spotA, spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveDownButtonTapped(spotID: spotAID)) {
            $0.itinerary.itineraryDays[0].spots = [spotB, spotA]
        }
    }

    @Test func 前日へ移動で前日の末尾へ追加すること() async {
        let spotBID = UUID()
        let spotA = makeSpot(title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: UUID(), spots: [spotA]),
                        ItineraryDay(id: UUID(), spots: [spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveToPreviousDayButtonTapped(spotID: spotBID)) {
            $0.itinerary.itineraryDays[0].spots = [spotA, spotB]
            $0.itinerary.itineraryDays[1].spots = []
        }
    }

    @Test func 翌日へ移動で翌日の末尾へ追加すること() async {
        let spotAID = UUID()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: UUID(), spots: [spotA]),
                        ItineraryDay(id: UUID(), spots: [spotB]),
                    ]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.moveToNextDayButtonTapped(spotID: spotAID)) {
            $0.itinerary.itineraryDays[0].spots = []
            $0.itinerary.itineraryDays[1].spots = [spotB, spotA]
        }
    }

    @Test func 行き先更新で一致する行き先を置き換えること() async {
        let spotID = UUID()
        let updated = makeSpot(id: spotID, title: "新")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [makeSpot(id: spotID, title: "旧")],
                    itineraryDays: [ItineraryDay(id: UUID())]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.spotUpdated(updated)) {
            $0.itinerary.candidateSpots = [updated]
        }
    }

    @Test func 削除で確定済み行き先を取り除くこと() async {
        let spotID = UUID()
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: UUID(), spots: [makeSpot(id: spotID, title: "A")])]
                )
            )
        ) {
            ItineraryFeature()
        }

        await store.send(.deleteButtonTapped(spotID: spotID)) {
            $0.itinerary.itineraryDays[0].spots = []
        }
    }
}
