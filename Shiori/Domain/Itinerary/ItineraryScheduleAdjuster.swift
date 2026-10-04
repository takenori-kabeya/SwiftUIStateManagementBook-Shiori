import Foundation

nonisolated enum ItineraryScheduleAdjuster {
    /// 配列順を保ち、重なる行き先の開始時刻だけを後ろへずらした配列を返す
    static func resolvingConflictsByShiftingStartTimes(in spots: [Spot]) -> [Spot] {
        var result = spots

        for index in result.indices {
            guard result[index].startTime != nil else { continue }

            while true {
                let conflictingPreviousSlots = result[..<index].compactMap { previous -> ScheduleSlot? in
                    guard previous.startTime != nil,
                          let previousSlot = scheduleSlot(for: previous),
                          let currentSlot = scheduleSlot(for: result[index]),
                          slotsConflict(previousSlot, currentSlot) else {
                        return nil
                    }
                    return previousSlot
                }

                guard let requiredStart = conflictingPreviousSlots.map(exclusiveEndMinutes(of:)).max() else {
                    break
                }

                result[index].startTime = spotTime(fromMinutesSinceMidnight: requiredStart)
            }
        }

        return result
    }

    private enum ScheduleSlot {
        case point(minutes: Int)
        case interval(start: Int, end: Int)
    }

    private static func scheduleSlot(for spot: Spot) -> ScheduleSlot? {
        guard let startTime = spot.startTime else {
            return nil
        }
        let startMinutes = minutesSinceMidnight(from: startTime)
        if let durationMinutes = spot.durationMinutes {
            return .interval(start: startMinutes, end: startMinutes + durationMinutes)
        }
        return .point(minutes: startMinutes)
    }

    private static func slotsConflict(_ lhs: ScheduleSlot, _ rhs: ScheduleSlot) -> Bool {
        switch (lhs, rhs) {
        case (.interval(let startA, let endA), .interval(let startB, let endB)):
            return startA < endB && startB < endA
        case (.point(let point), .interval(let start, let end)):
            return start <= point && point < end
        case (.interval(let start, let end), .point(let point)):
            return start <= point && point < end
        case (.point, .point):
            return false
        }
    }

    private static func exclusiveEndMinutes(of slot: ScheduleSlot) -> Int {
        switch slot {
        case .interval(_, let end):
            return end
        case .point(let minutes):
            return minutes + 1
        }
    }

    private static func minutesSinceMidnight(from time: SpotTime) -> Int {
        time.hour * 60 + time.minute
    }

    private static func spotTime(fromMinutesSinceMidnight minutes: Int) -> SpotTime {
        SpotTime(hour: minutes / 60, minute: minutes % 60)
    }
}
