import Foundation

/// 旅行
nonisolated struct Trip: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var startDate: Date
    
    /// 旅程
    var itinerary: Itinerary
}
