import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `ItineraryFeature` を `TestStore` で検証する
@Suite(
    .dependencies {
        $0.uuid = .incrementing
    }
)
@MainActor
struct ItineraryFeatureTests {
    @Dependency(\.uuid) var uuid
    
    private func makeSpot(
        id: UUID,
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
        let day1ID = uuid()
        let day2ID = uuid()
        let day2Spot = makeSpot(id: uuid(), title: "Day2Only", hour: 9, minute: 0, durationMinutes: 30)
        let initial = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: day1ID,
                    spots: [
                        makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
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
        let dayID = uuid()
        let initial = Itinerary(
            candidateSpots: [],
            itineraryDays: [
                ItineraryDay(
                    id: dayID,
                    spots: [
                        makeSpot(id: uuid(), title: "A", hour: 10, minute: 0, durationMinutes: 90),
                        makeSpot(id: uuid(), title: "B", hour: 11, minute: 0, durationMinutes: 60),
                    ]
                ),
            ]
        )
        let store = TestStore(initialState: ItineraryFeature.State(itinerary: initial)) {
            ItineraryFeature()
        }

        await store.send(.autoShiftButtonTapped(dayID: uuid()))
    }

    @Test func 候補追加でタイトルを候補へ追加すること() async {
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]) // ここのuuid()で0番が採られる
            )
        ) {
            ItineraryFeature()
        }
        let implicitSpotID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")! // makeSpotで生成されるSpotのIDを推測。0の次なので1のはず

        let newTitle = "新候補"
        await store.send(.addCandidateButtonTapped(title: newTitle)) {
            $0.itinerary.candidateSpots.append(makeSpot(id: implicitSpotID, title: newTitle))
        }
        #expect(store.state.itinerary.candidateSpots.map(\.title) == ["新候補"])
        #expect(store.state.itinerary.candidateSpots.count == 1)
        #expect(store.state.itinerary.candidateSpots[0].memo == "")
        #expect(store.state.itinerary.candidateSpots[0].startTime == nil)
    }
    


    @Test func 確定で日IDに対応する日へ候補を移すこと() async {
        let candidateID = uuid()
        let day0ID = uuid()
        let day1ID = uuid()
        let candidate = makeSpot(id: candidateID, title: "候補")
        let day0Spot = makeSpot(id: uuid(), title: "Day0")
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
        let spotID = uuid()


        let spot = makeSpot(id: spotID, title: "A")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [spot])]
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
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA, spotB]),
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
        let spotAID = uuid()
        let spotBID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA, spotB]),
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
        let spotBID = uuid()
        let spotA = makeSpot(id: uuid(), title: "A")
        let spotB = makeSpot(id: spotBID, title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA]),
                        ItineraryDay(id: uuid(), spots: [spotB]),
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
        let spotAID = uuid()
        let spotA = makeSpot(id: spotAID, title: "A")
        let spotB = makeSpot(id: uuid(), title: "B")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [
                        ItineraryDay(id: uuid(), spots: [spotA]),
                        ItineraryDay(id: uuid(), spots: [spotB]),
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
        let spotID = uuid()
        let updated = makeSpot(id: spotID, title: "新")
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [makeSpot(id: spotID, title: "旧")],
                    itineraryDays: [ItineraryDay(id: uuid())]
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
        let spotID = uuid()
        let store = TestStore(
            initialState: ItineraryFeature.State(
                itinerary: Itinerary(
                    candidateSpots: [],
                    itineraryDays: [ItineraryDay(id: uuid(), spots: [makeSpot(id: spotID, title: "A")])]
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
