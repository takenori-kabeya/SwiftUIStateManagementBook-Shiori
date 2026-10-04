import Foundation

nonisolated enum ItineraryCurrentNextResolver {
    enum CurrentSchedule: Equatable {
        /// 非表示
        case hidden
        /// 移動中
        case moving
        /// 予定終了
        case scheduleFinished
        /// 現在の予定
        case spot(Spot)
    }
    
    enum NextSchedule: Equatable {
        /// 予定なし
        case noneRegistered
        /// 予定終了
        case scheduleFinished
        /// 次の予定
        case spot(Spot)
        /// 最初の予定
        case firstSpot(Spot)
    }
    
    struct TripSpotHighlight: Equatable {
        var current: CurrentSchedule
        var next: NextSchedule
    }

    // MARK: - Multi-day API (Itinerary + tripStartDate)

    static func highlight(
        in itinerary: Itinerary,
        tripStartDate: Date,
        now: Date = .now
    ) -> TripSpotHighlight {
        let dayIndex = rawDayIndex(tripStartDate: tripStartDate, now: now)

        // 旅行開始日前日以前
        if dayIndex < 0 {
            if let first = firstConfirmedSpot(in: itinerary) {
                return TripSpotHighlight(current: .hidden, next: .firstSpot(first))
            }
            return TripSpotHighlight(current: .hidden, next: .noneRegistered)
        }

        // 旅行終了日翌日以降
        if itinerary.itineraryDays.count <= dayIndex {
            return TripSpotHighlight(current: .hidden, next: .scheduleFinished)
        }

        // 旅行中
        if let current = currentSpot(in: itinerary, tripStartDate: tripStartDate, now: now) {
            if let next = nextSpotInGlobalOrder(after: current, in: itinerary) {
                return TripSpotHighlight(current: .spot(current), next: .spot(next))
            }
            return TripSpotHighlight(current: .spot(current), next: .scheduleFinished)
        }

        if let next = earliestFutureTimedSpot(
            in: itinerary,
            tripStartDate: tripStartDate,
            now: now
        ) {
            return TripSpotHighlight(current: .moving, next: .spot(next))
        }

        return TripSpotHighlight(current: .scheduleFinished, next: .scheduleFinished)
    }

    static func currentSpot(
        in itinerary: Itinerary,
        tripStartDate: Date,
        now: Date = .now
    ) -> Spot? {
        let dayIndex = rawDayIndex(tripStartDate: tripStartDate, now: now)
        guard 0 <= dayIndex, dayIndex < itinerary.itineraryDays.count else { return nil }

        let nowTime = SpotTime.fromDate(now)
        return itinerary.itineraryDays[dayIndex].spots.last { spot in
            isCurrentlyAt(spot, at: nowTime)
        }
    }

    // MARK: - Shared helpers

    private static func firstConfirmedSpot(in itinerary: Itinerary) -> Spot? {
        for day in itinerary.itineraryDays {
            if let first = day.spots.first {
                return first
            }
        }
        return nil
    }

    private static func spotContexts(
        in itinerary: Itinerary
    ) -> [(dayIndex: Int, globalIndex: Int, spot: Spot)] {
        var result: [(dayIndex: Int, globalIndex: Int, spot: Spot)] = []
        var globalIndex = 0
        for (dayIndex, day) in itinerary.itineraryDays.enumerated() {
            for spot in day.spots {
                result.append((dayIndex: dayIndex, globalIndex: globalIndex, spot: spot))
                globalIndex += 1
            }
        }
        return result
    }

    private static func nextSpotInGlobalOrder(after current: Spot, in itinerary: Itinerary) -> Spot? {
        let contexts = spotContexts(in: itinerary)
        guard let currentContext = contexts.first(where: { $0.spot.id == current.id }) else {
            return nil
        }
        return contexts.first(where: { $0.globalIndex == currentContext.globalIndex + 1 })?.spot
    }

    private static func earliestFutureTimedSpot(
        in itinerary: Itinerary,
        tripStartDate: Date,
        now: Date
    ) -> Spot? {
        var best: (spot: Spot, date: Date)?
        for (dayIndex, day) in itinerary.itineraryDays.enumerated() {
            for spot in day.spots {
                guard let startTime = spot.startTime,
                      let absolute = absoluteStartDate(
                        tripStartDate: tripStartDate,
                        dayIndex: dayIndex,
                        startTime: startTime
                      ),
                      absolute >= now else {
                    continue
                }
                if best == nil || absolute < best!.date {
                    best = (spot, absolute)
                }
            }
        }
        return best?.spot
    }

    private static func absoluteStartDate(
        tripStartDate: Date,
        dayIndex: Int,
        startTime: SpotTime,
        calendar: Calendar = .current
    ) -> Date? {
        let startOfTrip = calendar.startOfDay(for: tripStartDate)
        guard let day = calendar.date(byAdding: .day, value: dayIndex, to: startOfTrip) else {
            return nil
        }
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = startTime.hour
        components.minute = startTime.minute
        return calendar.date(from: components)
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
