import Foundation

nonisolated struct TripDraft: Equatable {
    var id: UUID {
        info.id
    }
    var info: TripInfo
    var newNumDays: Int
    var dayTitles: [[String]]
    var currentNumDays: Int {
        dayTitles.count
    }
    
    init(info: TripInfo, itinerary: Itinerary) {
        self.info = info
        self.newNumDays = itinerary.itineraryDays.count
        self.dayTitles = itinerary.itineraryDays.map {
            Array(Array($0.spots.map { $0.title }))
        }
    }
    
    func spotTitlesToMoveWhenReducingDayCount(to count: Int) -> [String] {
        let newCount = max(1, count)
        let currentCount = dayTitles.count
        guard newCount < currentCount else { return [] }
        return dayTitles[newCount ..< currentCount].flatMap { $0 }
    }
}

