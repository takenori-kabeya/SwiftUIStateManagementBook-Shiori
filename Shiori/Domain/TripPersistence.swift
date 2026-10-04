import Foundation

/// 旅行の永続化
nonisolated struct TripPersistence {
    var load: () async throws -> [Trip]
    var save: ([Trip]) async throws -> Void
}

extension TripPersistence {
    static let local = TripPersistence(
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
        }
    )

    static let mock = TripPersistence(
        load: { [defaultTrip] },
        save: { trips in
            print("保存:", trips)
        }
    )
    
    nonisolated static var defaultTrip: Trip {
        return Trip(id: UUID(), title: "東京観光", itinerary:
                        Itinerary(candidateSpots: [
                            Spot(id: UUID(), title: "東京タワー")
                        ], confirmedSpots: [
                            Spot(id: UUID(), title: "浅草寺", startTime: getTime(hour: 10, minute: 30), durationMinutes: 30 ,memo: "お土産を買う"),
                            Spot(id: UUID(), title: "スカイツリー")
                        ]))
    }
    
    nonisolated static func getTime(hour: Int, minute: Int) -> Date {
        if let date = DateComponents(calendar: .current, year: 2000, hour: hour, minute: minute).date {
            return date
        }
        return Date.now
    }
    
    nonisolated private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("itinerary.json")
    }
}
