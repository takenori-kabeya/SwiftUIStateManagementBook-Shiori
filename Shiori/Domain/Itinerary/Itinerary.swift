/// 旅程
nonisolated struct Itinerary: Codable, Equatable {
    /// 行き先候補
    var candidateSpots: [Spot] = []
    
    /// 確定行き先
    var confirmedSpots: [Spot] = []
}
