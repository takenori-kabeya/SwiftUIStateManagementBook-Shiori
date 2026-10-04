import Foundation

/// 行き先
nonisolated struct Spot: Identifiable, Codable, Equatable  {
    let id: UUID
    var title: String
    var startTime: Date?
    var durationMinutes: Int?
    var memo: String = ""
    var endTime: Date? {
        guard let startTime, let durationMinutes else {
            return nil
        }
        return startTime.addingTimeInterval(TimeInterval(durationMinutes.magnitude * 60))
    }
}

nonisolated struct SpotDraft: Equatable {
    var title: String
    var hasStartTime: Bool
    var hasDurationMinutes: Bool
    var startTime: Date
    var durationMinutes: Int
    var memo: String

    static let empty = SpotDraft(
        title: "",
        hasStartTime: false,
        hasDurationMinutes: false,
        startTime: Date(),
        durationMinutes: 60,
        memo: ""
    )
    
    init(
        title: String,
        hasStartTime: Bool,
        hasDurationMinutes: Bool,
        startTime: Date,
        durationMinutes: Int,
        memo: String) {
            
        self.title = title
        self.hasStartTime = hasStartTime
        self.hasDurationMinutes = hasDurationMinutes
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.memo = memo
    }

    init(spot: Spot) {
        self.title = spot.title
        self.hasStartTime = spot.startTime != nil
        self.hasDurationMinutes = spot.durationMinutes != nil
        self.startTime = spot.startTime ?? Date()
        self.durationMinutes = spot.durationMinutes ?? 60
        self.memo = spot.memo
    }
    
    public func spot() -> Spot {
        return Spot(
            id: .init(),
            title: title,
            startTime: hasStartTime ? startTime : nil,
            durationMinutes: hasDurationMinutes ? durationMinutes : nil,
            memo: memo)
    }
}
