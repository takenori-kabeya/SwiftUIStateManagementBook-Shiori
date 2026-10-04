import Foundation

nonisolated enum ItineraryCurrentNextResolver {
    static func currentSpot(
        in spots: [Spot],
        at now: Date = .now,
        calendar: Calendar = .current
    ) -> Spot? {
        spots.first { spot in
            isCurrentlyAt(spot, at: now, calendar: calendar)
        }
    }

    static func nextSpot(
        in spots: [Spot],
        at now: Date = .now,
        calendar: Calendar = .current
    ) -> Spot? {
        if let current = currentSpot(in: spots, at: now, calendar: calendar) {
            return nextInArray(after: current, in: spots)
        }

        if let nextAfterLastCompleted = nextAfterLastCompleted(in: spots, at: now, calendar: calendar) {
            return nextAfterLastCompleted
        }
        return spots.first
    }

    private static func isCurrentlyAt(_ spot: Spot, at now: Date, calendar: Calendar) -> Bool {
        guard let startTime = spot.startTime,
              let durationMinutes = spot.durationMinutes else {
            return false
        }

        let start = timeOfDay(on: now, from: startTime, calendar: calendar)
        let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
        return start <= now && now < end
    }

    private static func nextInArray(after spot: Spot, in spots: [Spot]) -> Spot? {
        guard let index = spots.firstIndex(where: { $0.id == spot.id }) else {
            return nil
        }

        let nextIndex = index + 1
        guard nextIndex < spots.count else {
            return nil
        }

        return spots[nextIndex]
    }

    private static func earliestFutureTimedSpot(
        in spots: [Spot],
        at now: Date,
        calendar: Calendar
    ) -> Spot? {
        let nowMinutes = minutesSinceMidnight(from: now, calendar: calendar)

        return spots.enumerated()
            .compactMap { index, spot -> (Int, Spot)? in
                guard let startTime = spot.startTime else {
                    return nil
                }

                let startMinutes = minutesSinceMidnight(from: startTime, calendar: calendar)
                guard nowMinutes < startMinutes else {
                    return nil
                }

                return (index, spot)
            }
            .sorted { lhs, rhs in
                let leftMinutes = minutesSinceMidnight(from: lhs.1.startTime!, calendar: calendar)
                let rightMinutes = minutesSinceMidnight(from: rhs.1.startTime!, calendar: calendar)
                if leftMinutes != rightMinutes {
                    return leftMinutes < rightMinutes
                }
                return lhs.0 < rhs.0
            }
            .first?.1
    }

    private static func nextAfterLastCompleted(
        in spots: [Spot],
        at now: Date,
        calendar: Calendar
    ) -> Spot? {
        var lastCompletedIndex: Int?

        for (index, spot) in spots.enumerated() {
            guard let startTime = spot.startTime,
                  let durationMinutes = spot.durationMinutes else {
                continue
            }

            let start = timeOfDay(on: now, from: startTime, calendar: calendar)
            let end = start.addingTimeInterval(TimeInterval(durationMinutes * 60))
            if end <= now {
                lastCompletedIndex = index
            }
        }

        guard let lastCompletedIndex else {
            return nil
        }

        let nextIndex = lastCompletedIndex + 1
        guard nextIndex < spots.count else {
            return nil
        }

        return spots[nextIndex]
    }

    private static func timeOfDay(on referenceDay: Date, from dateTime: Date, calendar: Calendar) -> Date {
        let day = calendar.dateComponents([.year, .month, .day], from: referenceDay)
        let time = calendar.dateComponents([.hour, .minute], from: dateTime)
        return DateComponents(
            calendar: calendar,
            year: day.year,
            month: day.month,
            day: day.day,
            hour: time.hour,
            minute: time.minute
        ).date!
    }

    private static func minutesSinceMidnight(from date: Date, calendar: Calendar) -> Int {
        let components = calendar.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
