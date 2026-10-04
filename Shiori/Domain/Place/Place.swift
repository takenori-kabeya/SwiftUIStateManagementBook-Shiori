import Foundation

/// 地点（確定結果）
nonisolated struct Place: Codable, Equatable, Sendable {
    var name: String
    var address: String
    var latitude: Double
    var longitude: Double
}

/// 地点候補（検索結果の一覧用）
nonisolated struct PlaceCandidate: Identifiable, Equatable, Sendable {
    var id: UUID
    var place: Place
}
