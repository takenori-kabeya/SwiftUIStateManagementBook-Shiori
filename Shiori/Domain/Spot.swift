import Foundation

/// 行き先
nonisolated struct Spot: Identifiable, Codable, Equatable  {
    let id: UUID
    var title: String
    var startTime: Date?
    var durationMinutes: Int?
    var memo: String = ""
}
