import Foundation
import ComposableArchitecture
/// 旅行
nonisolated struct Trip: Identifiable, Codable, Equatable {
    var id: UUID {
        info.id
    }
    /// 旅行情報
    var info: TripInfo
    
    /// 旅程
    var itinerary: Itinerary
}

nonisolated struct TripDraft: Equatable {
    var id: UUID {
        info.id
    }
    var info: TripInfo
    var numDays: Int
    
    init(from trip: Trip) {
        self.info = trip.info
        self.numDays = trip.itinerary.itineraryDays.count
    }
}

extension Trip {
    nonisolated static var previewTrip: Trip {
        @Dependency(\.date) var date
        
        return Trip(info: TripInfo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "東京観光",
            startDate: date.now.date),
            itinerary:
                Itinerary(candidateSpots: [
                    Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!, title: "東京タワー")
                ], itineraryDays: [
                    ItineraryDay(id: UUID(uuidString: "00000000-0000-0000-0000-000000000100")!, spots: [
                        Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!, title: "浅草寺", startTime: SpotTime(hour: 10, minute: 30), durationMinutes: 30 ,memo: "お土産を買う"),
                        Spot(id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!, title: "スカイツリー")
                    ])
                ]))
    }
    
    nonisolated static var uiTestTrip: Trip {
        @Dependency(\.date) var date
        
        return Trip(info: TripInfo(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
            title: "東京観光",
            startDate: date.now.date),
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
}
