import Foundation

nonisolated struct ForecastCondition: Equatable, Sendable {
    var latitude: Double?
    var longitude: Double?
    var fromDate: Date
    var numDays: Int
}
