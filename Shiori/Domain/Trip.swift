import Foundation

/// 旅行
nonisolated struct Trip: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    
    /// 旅程
    var itinerary: Itinerary
}
