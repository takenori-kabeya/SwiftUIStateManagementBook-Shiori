import Foundation
import Testing
@testable import Shiori

/// Trip.weatherPlace と Place の Codable / 往復を検証する
struct TripWeatherPlaceTests {
    private func makePlace() -> Place {
        Place(
            name: "東京駅",
            address: "東京都千代田区",
            latitude: 35.6812,
            longitude: 139.7671
        )
    }

    private func makeTrip(weatherPlace: Place? = nil) -> Trip {
        Trip(
            info: TripInfo(
                id: UUID(uuidString: "00000000-0000-0000-0000-000000000099")!,
                title: "テスト旅行",
                startDate: Date(timeIntervalSince1970: 0),
                weatherPlace: weatherPlace
            ),
            itinerary: Itinerary(
                candidateSpots: [],
                itineraryDays: [ItineraryDay(id: UUID(uuidString: "00000000-0000-0000-0000-000000000199")!)]
            ),
        )
    }

    @Test
    func 場所を符号化して復号しても内容が保たれること() throws {
        let place = makePlace()
        let data = try JSONEncoder().encode(place)
        let decoded = try JSONDecoder().decode(Place.self, from: data)
        #expect(decoded == place)
    }

    @Test
    func 天気予報用場所なしの旅行を符号化して復号しても天気予報用場所が空であること() throws {
        let trip = makeTrip(weatherPlace: nil)
        let data = try JSONEncoder().encode(trip)
        let decoded = try JSONDecoder().decode(Trip.self, from: data)
        #expect(decoded.info.weatherPlace == nil)
        #expect(decoded.info.title == "テスト旅行")
    }

    @Test
    func 天気予報用場所ありの旅行を符号化して復号しても天気予報用場所が保たれること() throws {
        let place = makePlace()
        let trip = makeTrip(weatherPlace: place)
        let data = try JSONEncoder().encode(trip)
        let decoded = try JSONDecoder().decode(Trip.self, from: data)
        #expect(decoded.info.weatherPlace == place)
    }

    @Test
    func FeatureのStateからTripを組み立てても天気予報用場所が保たれること() {
        Task {
            let place = makePlace()
            let trip = makeTrip(weatherPlace: place)
            let state = await TripFeature.State(trip: trip)
            let restored = await state.makeTrip()
            #expect(restored.info.weatherPlace == place)
            #expect(restored.info == trip.info)
            #expect(restored.itinerary == trip.itinerary)
        }
    }
}
