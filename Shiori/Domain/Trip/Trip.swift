import Foundation

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

