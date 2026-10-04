import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori


@MainActor
private func makeStoreWithGate(
    gate: FetchGate<PlaceCandidate>,
    query: String = ""
) -> TestStore<PlaceSearchFeature.State, PlaceSearchFeature.Action> {
    let store = TestStore(initialState: PlaceSearchFeature.State(query: query)) {
        PlaceSearchFeature()
    } withDependencies: {
        $0.placeSearch.search = { _ in
            try await gate.fetch()
        }
    }
    
    return store
}

private func makeCandidate(
    id: UUID,
    name: String = "東京駅",
    latitude: Double = 35.681072,
    longitude: Double = 139.767427
) -> PlaceCandidate {
    PlaceCandidate(
        id: id,
        place: Place(
            name: name,
            address: "東京都千代田区, 丸の内",
            latitude: latitude,
            longitude: longitude)
    )
}

/// `PlaceSearchFeature` を `TestStore` で検証する
@Suite(
    .dependencies {
        $0.uuid = .incrementing
    }
  )
@MainActor
struct PlaceSearchFeatureTests {
    @Dependency(\.uuid) var uuid
    
    private func makeCandidate(
        id: UUID,
        name: String,
        address: String = "",
        latitude: Double = 35.0,
        longitude: Double = 139.0
    ) -> PlaceCandidate {
        PlaceCandidate(
            id: id,
            place: Place(
                name: name,
                address: address,
                latitude: latitude,
                longitude: longitude
            )
        )
    }

    @Test func 空の検索語ではクライアントを呼ばず空クエリエラーにすること() async {
        actor Counter {
            var count: Int = 0
            func increment() { count += 1 }
        }
        let searchCallCount = Counter()
        let store = TestStore(initialState: PlaceSearchFeature.State(query: "   ")) {
            PlaceSearchFeature()
        } withDependencies: {
            $0.placeSearch.search = { _ in
                await searchCallCount.increment()
                return []
            }
        }

        await store.send(.searchButtonTapped) {
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = PlaceSearchError.emptyQuery.localizedDescription
            $0.isSearching = false
        }

        #expect(await searchCallCount.count == 0)
    }

    @Test func 検索結果が複数のとき候補だけ保持し選択しないこと() async {
        let candidates = [
            makeCandidate(id: uuid(), name: "東京駅", address: "東京都千代田区"),
            makeCandidate(id: uuid(), name: "東京タワー", address: "東京都港区"),
        ]
        let store = TestStore(initialState: PlaceSearchFeature.State(query: "東京")) {
            PlaceSearchFeature()
        } withDependencies: {
            $0.placeSearch.search = { query in
                #expect(query == "東京")
                return candidates
            }
        }

        await store.send(.searchButtonTapped) {
            $0.isSearching = true
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = nil
        }
        await store.receive(\.searchResponse.success) {
            $0.isSearching = false
            $0.candidates = .init(uniqueElements: candidates)
            $0.selectedPlace = nil
            $0.errorMessage = nil
        }
    }

    @Test func 検索結果が一件のとき自動で場所を選ぶこと() async {
        let candidate = makeCandidate(id: uuid(), name: "東京駅", address: "東京都千代田区", latitude: 35.6812, longitude: 139.7671)
        let store = TestStore(initialState: PlaceSearchFeature.State(query: "東京駅")) {
            PlaceSearchFeature()
        } withDependencies: {
            $0.placeSearch.search = { _ in [candidate] }
        }

        await store.send(.searchButtonTapped) {
            $0.isSearching = true
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = nil
        }
        await store.receive(\.searchResponse.success) {
            $0.isSearching = false
            $0.candidates = []
            $0.selectedPlace = Place(
                name: "東京駅",
                address: "東京都千代田区",
                latitude: 35.6812,
                longitude: 139.7671
            )
            $0.errorMessage = nil
        }
    }

    @Test func 候補選択で選択中の場所を更新すること() async {
        let uuid1 = uuid()
        let uuid2 = uuid()
        let candidates = [
            makeCandidate(id: uuid1, name: "東京駅", address: "東京都千代田区", latitude: 35.6812, longitude: 139.7671),
            makeCandidate(id: uuid2, name: "東京タワー", address: "東京都港区", latitude: 35.6586, longitude: 139.7454),
        ]
        let store = TestStore(
            initialState: PlaceSearchFeature.State(
                query: "東京",
                candidates: .init(uniqueElements: candidates)
            )
        ) {
            PlaceSearchFeature()
        }

        await store.send(.candidateSelected(uuid2)) {
            $0.selectedPlace = Place(
                name: "東京タワー",
                address: "東京都港区",
                latitude: 35.6586,
                longitude: 139.7454
            )
            $0.errorMessage = nil
        }
    }

    @Test func 確定ボタンでConfirmedDelegateを送ること() async {
        let place = Place(name: "東京駅", address: "東京都千代田区", latitude: 35.6812, longitude: 139.7671)
        let store = TestStore(
            initialState: PlaceSearchFeature.State(
                query: "東京駅",
                selectedPlace: place
            )
        ) {
            PlaceSearchFeature()
        }

        await store.send(.confirmButtonTapped)
        await store.receive(\.delegate.confirmed)
    }

    @Test func キャンセルボタンではDelegateが送られないこと() async {
        let store = TestStore(initialState: PlaceSearchFeature.State(query: "東京")) {
            PlaceSearchFeature()
        }

        await store.send(.cancelButtonTapped)
    }

    @Test func 検索語変更でクエリを更新すること() async {
        let store = TestStore(initialState: PlaceSearchFeature.State()) {
            PlaceSearchFeature()
        }

        await store.send(.queryChanged("京都")) {
            $0.query = "京都"
        }
    }

    @Test func 見つからないときエラーを設定すること() async {
        let store = TestStore(initialState: PlaceSearchFeature.State(query: "存在しない場所")) {
            PlaceSearchFeature()
        } withDependencies: {
            $0.placeSearch.search = { _ in
                throw PlaceSearchError.notFound
            }
        }

        await store.send(.searchButtonTapped) {
            $0.isSearching = true
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = nil
        }
        await store.receive(\.searchResponse.failure) {
            $0.isSearching = false
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = PlaceSearchError.notFound.localizedDescription
        }
    }
    
    @Test func 検索中に再検索すると前の検索がキャンセルされ新しい検索が行われること() async {
        let gate = FetchGate<PlaceCandidate>()
        let firstCandidate = makeCandidate(id: uuid(), name: "東京駅")
        let secondCandidate = makeCandidate(id: uuid(), name: "新宿駅", address: "東京都新宿区, 新宿", latitude: 35689932, longitude: 139.700527)
        let store = makeStoreWithGate(gate: gate, query: "東京駅")

        await store.send(.searchButtonTapped) {
            $0.isSearching = true
            $0.candidates = []
            $0.selectedPlace = nil
            $0.errorMessage = nil
        }
        await store.send(.queryChanged("新宿駅")) {
            $0.query = "新宿駅"
        }
        await store.send(.searchButtonTapped)
        await gate.waitUntilCancelled(at: 0)

        #expect(gate.callCount() == 2)
        #expect(gate.cancelledIndices().contains(0))
        #expect(!gate.cancelledIndices().contains(1))
        
        gate.resume(at: 0, with: .success([firstCandidate]))
        #expect(store.state.isSearching == true)
        #expect(store.state.candidates == [])
        #expect(store.state.errorMessage == nil)

        gate.resume(at: 1, with: .success([secondCandidate]))
        await store.receive(\.searchResponse.success) {
            $0.isSearching = false
            $0.candidates = []
            $0.selectedPlace = secondCandidate.place
            $0.errorMessage = nil
        }
        await store.finish()
    }
    
    @Test func 検索中に地点検索画面を閉じると検索Effectがキャンセルされること() async {
        let gate = FetchGate<PlaceCandidate>()
        let tripDraft = TripDraft(
            info: TripInfo(id: uuid(), title: "旅行", startDate: Date(timeIntervalSince1970: 0)),
            itinerary: Itinerary(candidateSpots: [], itineraryDays: []))
        let store = TestStore(initialState: TripEditFeature.State(draft: tripDraft)) {
            TripEditFeature()
        } withDependencies: {
            $0.placeSearch.search = { _ in
                try await gate.fetch()
            }
        }
        
        await store.send(.placeSearchButtonTapped) {
            $0.placeSearch = PlaceSearchFeature.State()
        }
        await store.send(.placeSearch(.presented(.queryChanged("東京")))) {
            $0.placeSearch?.query = "東京"
        }
        await store.send(.placeSearch(.presented(.searchButtonTapped))) {
            $0.placeSearch?.isSearching = true
        }
        await store.send(.placeSearch(.dismiss)) {
            $0.placeSearch = nil
        }
        #expect(gate.cancelledIndices().contains(0))
    }
}
