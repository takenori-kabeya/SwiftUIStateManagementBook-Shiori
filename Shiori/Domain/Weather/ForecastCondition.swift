import Foundation

nonisolated struct ForecastCondition: Equatable, Sendable {
    var latitude: Double?
    var longitude: Double?
    var fromDate: Date
    var numDays: Int
}

extension ForecastCondition {
    static func makeCondition(from trip: Trip) -> ForecastCondition {
        ForecastCondition(
            latitude: trip.info.weatherPlace?.latitude,
            longitude: trip.info.weatherPlace?.longitude,
            fromDate: trip.info.startDate,
            numDays: trip.itinerary.itineraryDays.count
        )
    }
}
