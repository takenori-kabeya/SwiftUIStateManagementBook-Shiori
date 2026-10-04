import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `TripsFeature` を `TestStore` で検証する
@Suite(
    .dependencies {
        $0.uuid = .incrementing
    }
)
@MainActor
struct TripsFeatureTests {
    @Dependency(\.uuid) var uuid
    
    private func makeTrip(
        id: UUID,
        title: String,
        startDate: Date = Date(timeIntervalSince1970: 0),
        itinerary: Itinerary
    ) -> Trip {
        Trip(
            info: TripInfo(id: id, title: title, startDate: startDate),
            itinerary: itinerary
        )
    }

    private func makeSpot(
        id: UUID,
        title: String
    ) -> Spot {
        Spot(id: id, title: title, startTime: nil, durationMinutes: nil, memo: "")
    }

    @Test func 旅行追加で旅行状態を末尾へ追加すること() async {
        let trip = makeTrip(id: uuid(), title: "大阪", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(initialState: TripsFeature.State()) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.addTrip(trip)) {
            $0.trips = [TripFeature.State(trip: trip)]
        }
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }

    @Test func 旅行削除で一致する旅行を取り除くこと() async {
        let tripAID = uuid()
        let tripBID = uuid()
        let tripA = makeTrip(id: tripAID, title: "東京", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripB = makeTrip(id: tripBID, title: "大阪", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(
                trips: [
                    TripFeature.State(trip: tripA),
                    TripFeature.State(trip: tripB),
                ]
            )
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.deleteTrip(tripAID)) {
            $0.trips = [TripFeature.State(trip: tripB)]
        }
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }

    @Test func 未知の旅行IDのとき削除しても一覧は変わらないこと() async {
        let trip = makeTrip(id: uuid(), title: "東京", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: trip)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.deleteTrip(uuid()))
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }

    @Test func 旅行更新で一致する旅行を置き換えること() async {
        let tripID = uuid()
        let original = makeTrip(id: tripID, title: "旧", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let updated = makeTrip(
            id: tripID,
            title: "新",
            itinerary: Itinerary(
                candidateSpots: [makeSpot(id: uuid(), title: "候補")],
                itineraryDays: [ItineraryDay(id: uuid())]
            )
        )
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: original)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.updateTrip(updated)) {
            $0.trips = [TripFeature.State(trip: updated)]
        }
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }

    @Test func 未知の旅行IDのとき更新しても一覧は変わらないこと() async {
        let existing = makeTrip(id: uuid(), title: "東京", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let unknown = makeTrip(id: uuid(), title: "別の旅行", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: existing)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.updateTrip(unknown))
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }

    @Test func 読み込み完了で旅行一覧を置き換えること() async {
        let existing = makeTrip(id: uuid(), title: "既存", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripA = makeTrip(id: uuid(), title: "A", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripB = makeTrip(id: uuid(), title: "B", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: existing)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.tripsLoaded([tripA, tripB])) {
            $0.trips = [
                TripFeature.State(trip: tripA),
                TripFeature.State(trip: tripB),
            ]
            $0.hasLoaded = true
        }
    }

    @Test func 子の旅程アクションで一致する旅行だけ更新すること() async {
        let tripID = uuid() // 0番
        let dayID = uuid()  // 1番
        let trip = makeTrip(
            id: tripID,
            title: "東京",
            itinerary: Itinerary(
                candidateSpots: [],
                itineraryDays: [ItineraryDay(id: dayID)]
            )
        )
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: trip)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        let implicitSpotID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")! // ここは2番になる
        let spotTitle = "候補"
        await store.send(
            .trips(
                .element(
                    id: tripID,
                    action: .itinerary(.addCandidateButtonTapped(title: spotTitle))
                )
            )
        ) {
            $0.trips[id: tripID]?.itinerary.itinerary.candidateSpots.append(makeSpot(id: implicitSpotID, title: spotTitle))
        }
        await store.receive(\.save)
        await store.receive(\.saveCompleted)

        #expect(store.state.trips[id: tripID]?.itinerary.itinerary.candidateSpots.map(\.title) == ["候補"])
        #expect(store.state.trips[id: tripID]?.info.title == "東京")
    }
    
    @Test func Dependencyで差し替えて読み込むと旅行一覧を置き換えること() async {
        let existing = makeTrip(id: uuid(), title: "既存", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripA = makeTrip(id: uuid(), title: "A", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripB = makeTrip(id: uuid(), title: "B", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: [TripFeature.State(trip: existing)])
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
            $0.tripPersistence.load = { [tripA, tripB] }
        }

        await store.send(.load)
        await store.receive(\.tripsLoaded) {
            $0.trips = [
                TripFeature.State(trip: tripA),
                TripFeature.State(trip: tripB),
            ]
            $0.hasLoaded = true
        }
    }
}
