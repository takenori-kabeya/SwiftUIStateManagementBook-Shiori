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
    
    private func stateWithTripDetailOnPath(_ trip: Trip) -> TripsFeature.State {
        var state = TripsFeature.State(trips: Shared(value: [trip]))
        if let sharedTrip = Shared(state.$trips[id: trip.id]) {
            state.path.append(.tripDetail(TripFeature.State(trip: sharedTrip)))
        }
        return state
    }
    private func stateWithItineraryEditorOnPath(_ trip: Trip) -> TripsFeature.State {
        var state = TripsFeature.State(trips: Shared(value: [trip]))
        if let sharedTrip = Shared(state.$trips[id: trip.id]) {
            state.path.append(.itineraryEditor(ItineraryFeature.State(itinerary: sharedTrip.itinerary, tripStartDate: sharedTrip.info.startDate)))
        }
        return state
    }
    
    @Test func 旅行追加で旅行状態を末尾へ追加すること() async {
        let trip = makeTrip(id: uuid(), title: "大阪", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(initialState: TripsFeature.State(trips: Shared(value: []))) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        
        await store.send(.addTrip(trip)) {
            $0.$trips.withLock {
                $0 = [trip]
            }
        }
        await store.receive(\.tripUpdated)
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
                trips: Shared(value: [tripA, tripB])
            )
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        
        await store.send(.deleteTrip(tripAID)) {
            $0.$trips.withLock {
                $0 = [tripB]
            }
        }
        await store.receive(\.tripUpdated)
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }
    
    @Test func 未知の旅行IDのとき削除しても一覧は変わらないこと() async {
        let trip = makeTrip(id: uuid(), title: "東京", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: Shared(value: [trip]))
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        
        await store.send(.deleteTrip(uuid()))
        await store.receive(\.tripUpdated)
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
    }
    
    @Test func 読み込み完了で旅行一覧を置き換えること() async {
        let existing = makeTrip(id: uuid(), title: "既存", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripA = makeTrip(id: uuid(), title: "A", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripB = makeTrip(id: uuid(), title: "B", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: Shared(value: [existing]))
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        
        await store.send(.tripsLoaded([tripA, tripB])) {
            $0.$trips.withLock {
                $0 = [tripA, tripB]
            }
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
            initialState: stateWithItineraryEditorOnPath(trip)
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }
        let spotID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")! // addCandidateButtonTappedで生成されるSpotのIDを推測。1の次なので2のはず
        let spotTitle = "候補"
        await store.send(
            .path(
                .element(
                    id: 0,
                    action: .itineraryEditor(.addCandidateButtonTapped(title: spotTitle))
                )
            )
        ) {
            $0.path[id: 0]?.itineraryEditor?.$itinerary.withLock {
                $0.candidateSpots.append(Spot(id: spotID, title: spotTitle))
            }
        }
        await store.receive(\.path[id: 0].itineraryEditor.delegate.itineraryUpdated)
        await store.receive(\.tripUpdated)
        await store.receive(\.save)
        await store.receive(\.saveCompleted)
        
        #expect(store.state.trips[id: tripID]?.itinerary.candidateSpots.map(\.title) == [spotTitle])
        #expect(store.state.trips[id: tripID]?.info.title == "東京")
        #expect(store.state.trips[id: tripID]?.id == tripID)
    }
    
    @Test func Dependencyで差し替えて読み込むと旅行一覧を置き換えること() async {
        let existing = makeTrip(id: uuid(), title: "既存", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripA = makeTrip(id: uuid(), title: "A", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let tripB = makeTrip(id: uuid(), title: "B", itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())]))
        let store = TestStore(
            initialState: TripsFeature.State(trips: Shared(value: [existing]))
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
            $0.tripPersistence.load = { [tripA, tripB] }
        }
        
        await store.send(.load)
        await store.receive(\.tripsLoaded) {
            $0.$trips.withLock {
                $0 = [tripA, tripB]
            }
            $0.hasLoaded = true
        }
    }

    @Test func editTripの保存で一致する旅行に下書きを反映すること() async {
        let tripID = uuid()
        let trip = makeTrip(
            id: tripID,
            title: "旧",
            itinerary: Itinerary(
                candidateSpots: [],
                itineraryDays: [ItineraryDay(id: uuid())]
            )
        )
        let store = TestStore(
            initialState: stateWithTripDetailOnPath(trip)
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.editButtonTapped(tripID)) {
            $0.editTrip = TripEditFeature.State(draft: TripDraft(info: trip.info, itinerary: trip.itinerary))
        }
        await store.send(.editTrip(.presented(.titleChanged("新")))) {
            $0.editTrip?.draft.info.title = "新"
        }

        await store.send(.editTrip(.presented(.saveButtonTapped)))
        await store.receive(\.editTrip.presented.delegate.saveRequested) {
            $0.$trips[id: tripID].withLock {
                $0?.info.title = "新"
            }
        }
        await store.receive(\.tripUpdated)
        await store.receive(\.save)
        await store.receive(\.editTrip.dismiss) {
            $0.editTrip = nil
        }
        await store.receive(\.saveCompleted)

        #expect(store.state.trips[id: tripID]?.info.title == "新")
        #expect(store.state.editTrip == nil)
    }
    
    @Test func editTripのキャンセルで元の旅行を変えないこと() async {
        let tripID = uuid()
        let trip = makeTrip(
            id: tripID,
            title: "元のタイトル",
            itinerary: Itinerary(
                candidateSpots: [],
                itineraryDays: [ItineraryDay(id: uuid())]
            )
        )
        let store = TestStore(
            initialState: stateWithTripDetailOnPath(trip)
        ) {
            TripsFeature()
        } withDependencies: {
            $0.tripPersistence = .testValue
        }

        await store.send(.editButtonTapped(tripID)) {
            $0.editTrip = TripEditFeature.State(draft: TripDraft(info: trip.info, itinerary: trip.itinerary))
        }
        await store.send(.editTrip(.presented(.titleChanged("破棄される変更")))) {
            $0.editTrip?.draft.info.title = "破棄される変更"
        }
        await store.send(.editTrip(.presented(.cancelButtonTapped)))
        await store.receive(\.editTrip.dismiss) {
            $0.editTrip = nil
        }

        #expect(store.state.trips[id: tripID]?.info.title == "元のタイトル")
        #expect(store.state.trips[id: tripID]?.id == trip.id)
        #expect(store.state.editTrip == nil)
    }
}
