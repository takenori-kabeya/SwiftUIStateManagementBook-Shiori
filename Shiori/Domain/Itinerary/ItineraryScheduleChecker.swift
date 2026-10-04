import Foundation

nonisolated enum ItineraryScheduleChecker {
    static func isTimeOrderConsistent(in spots: [Spot]) -> Bool {
        misalignedSpotIDs(in: spots).isEmpty
    }

    static func misalignedSpotIDs(in spots: [Spot]) -> Set<UUID> {
        let timedInArrayOrder = spots.filter { $0.startTime != nil }
        guard timedInArrayOrder.count >= 2 else {
            return []
        }

        let timedByTime = timedInArrayOrder.enumerated().sorted { lhs, rhs in
            let leftMinutes = minutesSinceMidnight(from: lhs.element.startTime!)
            let rightMinutes = minutesSinceMidnight(from: rhs.element.startTime!)
            if leftMinutes != rightMinutes {
                return leftMinutes < rightMinutes
            }
            return lhs.offset < rhs.offset
        }.map(\.element)

        var misaligned = Set<UUID>()
        for index in timedInArrayOrder.indices {
            let arrayID = timedInArrayOrder[index].id
            let timeSortedID = timedByTime[index].id
            if arrayID != timeSortedID {
                misaligned.insert(arrayID)
                misaligned.insert(timeSortedID)
            }
        }
        return misaligned
    }

    static func hasTimeConflicts(in spots: [Spot]) -> Bool {
        !conflictingSpotIDs(in: spots).isEmpty
    }

    static func conflictingSpotIDs(in spots: [Spot]) -> Set<UUID> {
        let scheduled = spots.compactMap { spot -> (UUID, ScheduleSlot)? in
            guard let slot = scheduleSlot(for: spot) else {
                return nil
            }
            return (spot.id, slot)
        }

        var conflicting = Set<UUID>()
        for leftIndex in scheduled.indices {
            for rightIndex in scheduled.indices where leftIndex < rightIndex {
                let left = scheduled[leftIndex]
                let right = scheduled[rightIndex]
                if slotsConflict(left.1, right.1) {
                    conflicting.insert(left.0)
                    conflicting.insert(right.0)
                }
            }
        }
        return conflicting
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

    private static func minutesSinceMidnight(from date: SpotTime) -> Int {
        return (date.hour * 60 + date.minute)
    }
}
