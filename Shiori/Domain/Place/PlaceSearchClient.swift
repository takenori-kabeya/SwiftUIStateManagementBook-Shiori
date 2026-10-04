import Foundation
import MapKit
import ComposableArchitecture

@DependencyClient
nonisolated struct PlaceSearchClient: Sendable {
    var search: @Sendable (_ query: String) async throws -> [PlaceCandidate]
}

nonisolated extension PlaceSearchClient: DependencyKey {
    public static let liveValue = Self(
        search: { query in
            let request = MKLocalSearch.Request()
            request.naturalLanguageQuery = query

            do {
                @Dependency(\.uuid) var uuid

                let response = try await MKLocalSearch(request: request).start()
                let places = response.mapItems.enumerated().compactMap { index, item -> PlaceCandidate? in
                    let name = item.name?.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let name, !name.isEmpty else {
                        return nil
                    }
                    
                    let coordinate: CLLocationCoordinate2D = {
                        if #available(iOS 26, *) {
                            return item.location.coordinate
                        }
                        else {
                            return item.placemark.location?.coordinate ?? .init()
                        }
                    }()
                    let address: String = {
                        if #available(iOS 26, *) {
                            return item.addressRepresentations?.fullAddress(includingRegion: true, singleLine: true) ?? ""
                        }
                        else {
                            return (item.placemark.administrativeArea ?? "") +
                            (item.placemark.locality ?? "") +
                            (item.placemark.thoroughfare ?? "") +
                            (item.placemark.subThoroughfare ?? "")
                        }
                    }()
                    return PlaceCandidate(
                        id: uuid(),
                        place: Place(
                            name: name,
                            address: address,
                            latitude: coordinate.latitude,
                            longitude: coordinate.longitude)
                    )
                }

                guard !places.isEmpty else {
                    throw PlaceSearchError.notFound
                }
                return places
            } catch let error as PlaceSearchError {
                throw error
            } catch {
                throw PlaceSearchError.searchFailed
            }
        }
    )

    public static let testValue = Self(
        search: { _ in [] }
    )

    public static let previewValue = Self(
        search: { _ in
            [
                PlaceCandidate(
                    id: UUID(uuidString: "00000000-0000-0000-0000-000000001001")!,
                    place: Place(
                        name: "東京駅",
                        address: "東京都千代田区",
                        latitude: 35.6812,
                        longitude: 139.7671)
                )
            ]
        }
    )
}

extension DependencyValues {
    nonisolated var placeSearch: PlaceSearchClient {
        get { self[PlaceSearchClient.self] }
        set { self[PlaceSearchClient.self] = newValue }
    }
}
