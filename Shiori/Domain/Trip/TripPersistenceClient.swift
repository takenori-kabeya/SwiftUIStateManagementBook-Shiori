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
                return [defaultTrip]
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

    static let mock = Self(
        load: { [defaultTrip] },
        save: { trips in
            print("保存:", trips)
        }
    )
    
    static let uiTest = Self(
        load: { [uiTestTrip] },
        save: { _ in }
    )

    nonisolated static var defaultTrip: Trip {
        Trip(info: TripInfo(
            id: UUID(),
            title: "東京観光",
            startDate: Date.now.date),
            itinerary:
                Itinerary(candidateSpots: [
                    Spot(id: UUID(), title: "東京タワー")
                ], itineraryDays: [
                    ItineraryDay(id: UUID(), spots: [
                        Spot(id: UUID(), title: "浅草寺", startTime: SpotTime(hour: 10, minute: 30), durationMinutes: 30 ,memo: "お土産を買う"),
                        Spot(id: UUID(), title: "スカイツリー")
                    ])
                ]))
    }
    
    nonisolated static var uiTestTrip: Trip {
        Trip(info: TripInfo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "東京観光",
            startDate: Date.now.date),
            itinerary:
                Itinerary(
                    candidateSpots: [
                        Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, title: "東京タワー", memo: "")
                    ],
                    itineraryDays: [
                        ItineraryDay(id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!, spots: [
                            Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!, title: "上野", startTime: SpotTime(hour: 14, minute: 0), durationMinutes: 60, memo: ""),
                            Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, title: "浅草寺", startTime: SpotTime(hour: 10, minute: 0), durationMinutes: 120, memo: ""),
                            Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!, title: "スカイツリー", startTime: SpotTime(hour: 11, minute: 0), durationMinutes: 60, memo: "")
                        ])
                    ]
                )
        )
    }

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
