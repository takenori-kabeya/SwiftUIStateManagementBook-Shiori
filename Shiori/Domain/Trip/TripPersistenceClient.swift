import Foundation
import ComposableArchitecture

/// 旅行の永続化
@DependencyClient
nonisolated struct TripPersistenceClient: Sendable {
    var load: @Sendable () async throws -> [Trip]
    var save: @Sendable ([Trip]) async throws -> Void
}

nonisolated extension TripPersistenceClient: DependencyKey {
    static let liveValue = Self(
        load: {
            let url = Self.fileURL

            guard FileManager.default.fileExists(atPath: url.path) else {
                return []
            }

            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([Trip].self, from: data)
        },
        save: { trips in
            let data = try JSONEncoder().encode(trips)
            try data.write(to: Self.fileURL, options: [.atomic])
            print("save!")
        }
    )

    static let previewValue = Self(
        load: { [Trip.previewTrip] },
        save: { trips in
            print("保存:", trips)
        }
    )
    
    static let testValue = Self(
        load: { [] },
        save: { _ in }
    )
    
    static let uiTest = Self(
        load: { [Trip.uiTestTrip] },
        save: { _ in }
    )

    nonisolated private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("itinerary.json")
    }
}

extension DependencyValues {
    nonisolated var tripPersistence: TripPersistenceClient {
        get { self[TripPersistenceClient.self] }
        set { self[TripPersistenceClient.self] = newValue }
    }
}
