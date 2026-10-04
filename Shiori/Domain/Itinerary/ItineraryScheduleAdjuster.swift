import Foundation

nonisolated enum ItineraryScheduleAdjuster {
    /// 配列順を保ち、重なる行き先の開始時刻だけを後ろへずらした配列を返す
    ///
    /// 日全体を最後まで走査し、離れた重なりグループも含めて解消する
    static func resolvingConflictsByShiftingStartTimes(in spots: [Spot]) -> [Spot] {
        var result = spots
        for index in result.indices {
            shiftSpotToResolveConflictsWithPrevious(in: &result, at: index)
        }
        return result
    }

    /// 配列順を保ち、`fromIndex` 以降の行き先だけ開始時刻を後ろへずらして重なりを解消する
    ///
    /// `fromIndex` 未満の Spot は変更しない。重なり判定では前半の Spot も参照する。
    /// 連続する重なり連鎖を解消したあと、開始時刻ありで重なりのない Spot に達した時点で打ち切る。
    /// 開始時刻なしはスキップし、打ち切りにはしない。
    /// `fromIndex` が範囲外の場合は入力をそのまま返す。
    static func resolvingConflictsByShiftingStartTimes(in spots: [Spot], fromIndex: Int) -> [Spot] {
        guard fromIndex < spots.count else {
            return spots
        }

        var result = spots
        let startIndex = max(0, fromIndex)
        var hasShiftedInChain = false

        for index in startIndex..<result.count {
            guard result[index].startTime != nil else {
                continue
            }

            let didShift = shiftSpotToResolveConflictsWithPrevious(in: &result, at: index)
            if didShift {
                hasShiftedInChain = true
            } else if hasShiftedInChain {
                break
            }
        }

        return result
    }

    /// 前の Spot との重なりがなくなるまで `index` の開始時刻を後ろへずらす
    ///
    /// - Returns: 1 回以上ずらした場合は `true`。重なりがなく何も変えなかった場合は `false`
    @discardableResult
    private static func shiftSpotToResolveConflictsWithPrevious(
        in result: inout [Spot],
        at index: Int
    ) -> Bool {
        guard result[index].startTime != nil else {
            return false
        }

        var didShift = false
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

            guard let requiredStart = conflictingPreviousSlots.map({ exclusiveEndMinutes(of: $0) }).max() else {
                break
            }

            result[index].startTime = spotTime(fromMinutesSinceMidnight: requiredStart)
            didShift = true
        }
        return didShift
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
