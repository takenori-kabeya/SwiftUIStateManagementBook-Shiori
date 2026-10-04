import Foundation

nonisolated struct SpotTime: Codable, Equatable {
    var hour: Int
    var minute: Int

    var formattedTime: String {
        return String(format: "%02d:%02d", hour, minute)
    }
    
    static func now(calendar: Calendar = .current) -> SpotTime {
        let currentDateTime = Date.now
        let time = calendar.dateComponents([.hour, .minute], from: currentDateTime)
        return SpotTime(hour: time.hour!, minute: time.minute!)
    }
    
    static func fromDate(_ date: Date, calendar: Calendar = .current) -> SpotTime {
        let time = calendar.dateComponents([.hour, .minute], from: date)
        return SpotTime(hour: time.hour!, minute: time.minute!)
    }
    
    func date(calendar: Calendar = .current) -> Date {
        let currentDateTime = Date.now
        let day = calendar.dateComponents([.year, .month, .day], from: currentDateTime)
        return calendar.date(from: DateComponents(year: day.year, month: day.month, day: day.day, hour: hour, minute: minute))!
    }
}

/// 行き先
nonisolated struct Spot: Identifiable, Codable, Equatable  {
    let id: UUID
    var title: String
    var startTime: SpotTime?
    var durationMinutes: Int?
    var memo: String = ""
    var endTime: SpotTime? {
        guard let startTime, let durationMinutes, 0 < durationMinutes else {
            return nil
        }
        let totalMinutes = startTime.hour * 60 + startTime.minute + durationMinutes
        
        return SpotTime(
            hour: (totalMinutes / 60),
            minute: totalMinutes % 60
        )
    }
}

nonisolated struct SpotDraft: Equatable {
    var id: UUID
    var title: String
    var hasStartTime: Bool
    var hasDurationMinutes: Bool
    var startTime: Date
    var durationMinutes: Int
    var memo: String

    static let empty = SpotDraft(
        id: .init(),
        title: "",
        hasStartTime: false,
        hasDurationMinutes: false,
        startTime: Date(),
        durationMinutes: 60,
        memo: ""
    )
    
    init(
        id: UUID,
        title: String,
        hasStartTime: Bool,
        hasDurationMinutes: Bool,
        startTime: Date,
        durationMinutes: Int,
        memo: String) {
            
        self.id = id
        self.title = title
        self.hasStartTime = hasStartTime
        self.hasDurationMinutes = hasDurationMinutes
        self.startTime = startTime
        self.durationMinutes = durationMinutes
        self.memo = memo
    }

    init(spot: Spot) {
        self.id = spot.id
        self.title = spot.title
        self.hasStartTime = spot.startTime != nil
        self.hasDurationMinutes = spot.durationMinutes != nil
        self.startTime = spot.startTime == nil ? Date() : spot.startTime!.date()
        self.durationMinutes = spot.durationMinutes ?? 60
        self.memo = spot.memo
    }
    
    public func spot() -> Spot {
        return Spot(
            id: self.id,
            title: self.title,
            startTime: self.hasStartTime ? SpotTime.fromDate(self.startTime) : nil,
            durationMinutes: self.hasDurationMinutes ? self.durationMinutes : nil,
            memo: self.memo)
    }
}
