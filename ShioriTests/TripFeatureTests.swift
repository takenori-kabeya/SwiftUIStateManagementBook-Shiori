import Foundation
import Testing
import Dependencies
import DependenciesTestSupport
@testable import Shiori

/// `TripFeature` を `TestStore` で検証する
@Suite(
  .dependencies {
      $0.uuid = .incrementing
  }
)
@MainActor
struct TripFeatureTests {
    @Dependency(\.uuid) var uuid

    private func makeTrip(
        id: UUID,
        title: String = "旅行",
        startDate: Date = Date(timeIntervalSince1970: 0),
        itinerary: Itinerary,
        weatherPlace: Place? = nil
    ) -> Trip {
        Trip(
            info: TripInfo(id: id, title: title, startDate: startDate, weatherPlace: weatherPlace),
            itinerary: itinerary
        )
    }

    private func makePlace(
        name: String = "東京駅",
        latitude: Double = 35.6812,
        longitude: Double = 139.7671
    ) -> Place {
        Place(
            name: name,
            address: "東京都千代田区",
            latitude: latitude,
            longitude: longitude
        )
    }

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

    @Test func State初期化後にmakeTripを実行しても内容が保たれること() {
        let tripID = uuid()
        let dayID = uuid()
        let spot = makeSpot(id: uuid(), title: "浅草寺", hour: 10, minute: 0, durationMinutes: 30)
        let trip = makeTrip(
            id: tripID,
            title: "東京",
            itinerary: Itinerary(
                candidateSpots: [makeSpot(id: uuid(), title: "候補")],
                itineraryDays: [ItineraryDay(id: dayID, spots: [spot])]
            )
        )

        let state = TripFeature.State(trip: Shared(value: trip))
        let restored = state.trip

        #expect(state.id == tripID)
        #expect(state.trip.info == trip.info)
        #expect(restored == trip)
    }

    @Test func 旅程アクションで子の旅程だけ更新すること() async {
        let dayID = uuid()      // 0
        let trip = makeTrip(
            id: uuid(),         // 1
            itinerary: Itinerary(
                candidateSpots: [],
                itineraryDays: [ItineraryDay(id: dayID)]
            )
        )
        let sharedTrip = Shared(value: trip)
        let store = TestStore(initialState: ItineraryFeature.State(
            itinerary: sharedTrip.itinerary,
            tripStartDate: sharedTrip.info.startDate
        )) {
            ItineraryFeature()
        }
        let spotID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!  // 1の次なので2になるはず
        let spotTitle = "新候補"
        await store.send(.addCandidateButtonTapped(title: spotTitle)) {
            $0.$itinerary.withLock {
                $0.candidateSpots.append(Spot(id: spotID, title: spotTitle))
            }
        }
        await store.receive(\.delegate.itineraryUpdated)
        
        #expect(store.state.itinerary.candidateSpots.map(\.title) == ["新候補"])
    }

    @Test func 自動シフトで時間重なりを解消すること() async {
        let dayID = uuid()
        let trip = makeTrip(
            id: uuid(),
            itinerary: Itinerary(
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
        )
        let sharedTrip = Shared(value: trip)
        let store = TestStore(initialState: ItineraryFeature.State(
            itinerary: sharedTrip.itinerary,
            tripStartDate: sharedTrip.info.startDate)) {
            ItineraryFeature()
        }

        await store.send(.autoShiftButtonTapped(dayID: dayID)) {
            $0.$itinerary.withLock {
                $0.itineraryDays[0].spots[1].startTime = SpotTime(hour: 11, minute: 30)
            }
        }
        
        await store.receive(\.delegate.itineraryUpdated)
    }
}
