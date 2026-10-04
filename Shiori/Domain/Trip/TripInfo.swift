import Foundation

/// 旅行情報
nonisolated struct TripInfo: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var startDate: Date
    var weatherPlace: Place?
}
