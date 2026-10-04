import Foundation

nonisolated enum ItineraryCurrentNextResolver {
    static func currentSpot(
        in itinerary: Itinerary,
        tripStartDate: Date,
        now: Date = .now
    ) -> Spot? {
        let dayIndex = rawDayIndex(tripStartDate: tripStartDate, now: now)
        guard 0 <= dayIndex, dayIndex < itinerary.itineraryDays.count else { return nil }

        let nowTime = SpotTime.fromDate(now)
        return itinerary.itineraryDays[dayIndex].spots.first { spot in
            isCurrentlyAt(spot, at: nowTime)
        }
    }

    static func nextSpot(
        in itinerary: Itinerary,
        tripStartDate: Date,
        now: Date = .now
    ) -> Spot? {
        let rawDayIndex = self.rawDayIndex(tripStartDate: tripStartDate, now: now)

        guard rawDayIndex < itinerary.itineraryDays.count else {
        return nil
        }

        let nowTime = SpotTime.fromDate(now)
        let nowMinutes = minutesSinceMidnight(from: nowTime)

        let spotContexts: [(dayIndex: Int, globalIndex: Int, spot: Spot)] = {
            var result: [(Int, Int, Spot)] = []
            var globalIndex = 0
            for (dayIndex, day) in itinerary.itineraryDays.enumerated() {
                for spot in day.spots {
                    result.append((dayIndex, globalIndex, spot))
                    globalIndex += 1
                }
            }
            return result.map { (dayIndex: $0.0, globalIndex: $0.1, spot: $0.2) }
        }()

        if let current = currentSpot(in: itinerary, tripStartDate: tripStartDate, now: now),
           let currentContext = spotContexts.first(where: { $0.spot.id == current.id }) {
            let nextIndex = currentContext.globalIndex + 1
            return spotContexts.first(where: { $0.globalIndex == nextIndex })?.spot
        }

        if let futureTimed = spotContexts.first(where: { ctx in
            guard let startTime = ctx.spot.startTime else { return false }
            let startMinutes = minutesSinceMidnight(from: startTime)
            if ctx.dayIndex > rawDayIndex { return true }
            if ctx.dayIndex == rawDayIndex { return nowMinutes < startMinutes }
            return false
        }) {
            return futureTimed.spot
        }

        var lastCompletedGlobalIndex: Int?
        for ctx in spotContexts {
            guard let startTime = ctx.spot.startTime,
                  let durationMinutes = ctx.spot.durationMinutes else { continue }

            let endMinutes = minutesSinceMidnight(from: startTime) + durationMinutes

            if ctx.dayIndex < rawDayIndex {
                lastCompletedGlobalIndex = ctx.globalIndex
            } else if ctx.dayIndex == rawDayIndex {
                if endMinutes <= nowMinutes {
                    lastCompletedGlobalIndex = ctx.globalIndex
                }
            }
        }

        guard let lastCompletedGlobalIndex,
              lastCompletedGlobalIndex + 1 < spotContexts.count else {
            return nil
        }
        return spotContexts.first(where: { $0.globalIndex == lastCompletedGlobalIndex + 1 })?.spot
    }

    private static func isCurrentlyAt(_ spot: Spot, at now: SpotTime) -> Bool {
        guard let startTime = spot.startTime,
              let durationMinutes = spot.durationMinutes else {
            return false
        }

        let nowMinutes = minutesSinceMidnight(from: now)
        let startMinutes = minutesSinceMidnight(from: startTime)
        let endMinutes = startMinutes + durationMinutes
        return startMinutes <= nowMinutes && nowMinutes < endMinutes
    }

    private static func minutesSinceMidnight(from time: SpotTime) -> Int {
        return time.hour * 60 + time.minute
    }

    private static func rawDayIndex(tripStartDate: Date, now: Date) -> Int {
        let calendar = Calendar.current
        let startOfTrip = calendar.startOfDay(for: tripStartDate)
        let startOfNow = calendar.startOfDay(for: now)
        return calendar.dateComponents([.day], from: startOfTrip, to: startOfNow).day ?? 0
    }
}
