import Foundation
import ComposableArchitecture

/// 日別行き先
nonisolated struct ItineraryDay: Identifiable, Codable, Equatable {
    let id: UUID
    var spots: [Spot] = []
}


/// 旅程
nonisolated struct Itinerary: Codable, Equatable {
    /// 行き先候補
    var candidateSpots: [Spot]
    
    /// 確定行き先
    var itineraryDays: [ItineraryDay]
    
    enum CodingKeys: String, CodingKey {
        case candidateSpots
        case itineraryDays
    }

    init(candidateSpots: [Spot], itineraryDays: [ItineraryDay]) {
        @Dependency(\.uuid) var uuid
        
        self.candidateSpots = candidateSpots
        self.itineraryDays = itineraryDays.isEmpty ? [ItineraryDay(id: uuid())] : itineraryDays
    }

    init(from decoder: Decoder) throws {
        @Dependency(\.uuid) var uuid
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candidateSpots = try container.decode([Spot].self, forKey: .candidateSpots)

        let days = try container.decode([ItineraryDay].self, forKey: .itineraryDays)
        itineraryDays = days.isEmpty ? [ItineraryDay(id: uuid())] : days
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(candidateSpots, forKey: .candidateSpots)
        try container.encode(itineraryDays, forKey: .itineraryDays)
    }

    /// 旅程の日数を増減する
    ///
    /// - 増やす: 末尾に空の `ItineraryDay` を追加する
    /// - 減らす: 削除される日の `Spot` を、残る最終日の末尾へ移動する
    ///
    /// 最低日数は 1 に固定する
    mutating func setDayCount(_ count: Int) {
        @Dependency(\.uuid) var uuid
        let newCount = max(1, count)
        let currentCount = itineraryDays.count

        guard newCount != currentCount else { return }

        if newCount > currentCount {
            let additional = (currentCount..<newCount).map { _ in ItineraryDay(id: uuid(), spots: []) }
            itineraryDays.append(contentsOf: additional)
            return
        }

        // newCount < currentCount
        let lastKeptIndex = newCount - 1
        let spotsToMove = itineraryDays[(lastKeptIndex + 1)..<currentCount].flatMap { $0.spots }
        itineraryDays.removeLast(currentCount - newCount)
        itineraryDays[lastKeptIndex].spots.append(contentsOf: spotsToMove)
    }

    /// 指定日の予定重なりを、開始時刻を後ろへずらして解消する
    ///
    /// 未知の `dayID` の場合は何もしない
    mutating func resolveScheduleConflicts(dayID: ItineraryDay.ID) {
        guard let dayIndex = itineraryDays.firstIndex(where: { $0.id == dayID }) else {
            return
        }
        itineraryDays[dayIndex].spots = ItineraryScheduleAdjuster
            .resolvingConflictsByShiftingStartTimes(in: itineraryDays[dayIndex].spots)
    }

    /// 指定日の、指定 Spot 以降の予定重なりだけを開始時刻を後ろへずらして解消する
    ///
    /// 指定 Spot より前の予定は変更しない。未知の `dayID` / `spotID` の場合は何もしない
    mutating func resolveScheduleConflicts(dayID: ItineraryDay.ID, fromSpotID: Spot.ID) {
        guard let dayIndex = itineraryDays.firstIndex(where: { $0.id == dayID }),
              let fromIndex = itineraryDays[dayIndex].spots.firstIndex(where: { $0.id == fromSpotID }) else {
            return
        }
        itineraryDays[dayIndex].spots = ItineraryScheduleAdjuster
            .resolvingConflictsByShiftingStartTimes(
                in: itineraryDays[dayIndex].spots,
                fromIndex: fromIndex
            )
    }

    /// 候補の末尾に行き先を追加する
    ///
    /// タイトルは前後空白を除去する。空文字の場合は何もしない
    mutating func addCandidate(title: String) {
        @Dependency(\.uuid) var uuid
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        candidateSpots.append(
            Spot(
                id: uuid(),
                title: trimmed,
                memo: ""
            )
        )
    }

    /// 候補の `spotID` を指定した日の末尾へ確定する
    ///
    /// - Parameters:
    ///   - spotID: 候補にある `Spot` の ID
    ///   - toDayID: 追加先の日 ID
    ///
    /// 未知の `spotID` または `toDayID` の場合は何もしない
    mutating func confirmCandidate(spotID: UUID, toDayID: ItineraryDay.ID) {
        guard let candidateIndex = candidateSpots.firstIndex(where: { $0.id == spotID }) else {
            return
        }
        guard let toDay = itineraryDays.firstIndex(where: { $0.id == toDayID }) else {
            return
        }

        let spot = candidateSpots.remove(at: candidateIndex)
        itineraryDays[toDay].spots.append(spot)
    }

    /// 確定済みの `spotID` を候補の末尾へ戻す
    ///
    /// 未知の ID の場合は何もしない
    mutating func returnSpotToCandidates(spotID: UUID) {
        guard let location = locationOfSpot(spotID: spotID) else { return }

        let spot = itineraryDays[location.dayIndex].spots.remove(at: location.spotIndex)
        candidateSpots.append(spot)
    }

    /// 候補・確定の両方から `spotID` を削除する
    ///
    /// 未知の ID の場合は何もしない
    mutating func deleteSpot(spotID: UUID) {
        candidateSpots.removeAll { $0.id == spotID }
        for dayIndex in itineraryDays.indices {
            itineraryDays[dayIndex].spots.removeAll { $0.id == spotID }
        }
    }

    /// 同 ID の行き先を候補または確定内で置換する
    ///
    /// タイトル（前後空白除去後）が空、または未知の ID の場合は何もしない
    mutating func updateSpot(_ spot: Spot) {
        let trimmedTitle = spot.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        var updated = spot
        updated.title = trimmedTitle

        if let index = candidateSpots.firstIndex(where: { $0.id == spot.id }) {
            candidateSpots[index] = updated
            return
        }

        if let location = locationOfSpot(spotID: spot.id) {
            itineraryDays[location.dayIndex].spots[location.spotIndex] = updated
        }
    }

    /// 確定行き先をフラット順で1つ上と入れ替える
    ///
    /// 先頭、または未知の ID の場合は何もしない
    mutating func moveConfirmedSpotUp(spotID: UUID) {
        guard let globalIndex = globalIndexOfConfirmedSpot(spotID: spotID) else { return }
        guard globalIndex > 0 else { return }

        swapConfirmedSpots(from: globalIndex, to: globalIndex - 1)
    }

    /// 確定行き先をフラット順で1つ下と入れ替える
    ///
    /// 末尾、または未知の ID の場合は何もしない
    mutating func moveConfirmedSpotDown(spotID: UUID) {
        guard let globalIndex = globalIndexOfConfirmedSpot(spotID: spotID) else { return }
        let flatCount = itineraryDays.reduce(0) { $0 + $1.spots.count }
        guard globalIndex < flatCount - 1 else { return }

        swapConfirmedSpots(from: globalIndex, to: globalIndex + 1)
    }

    /// 確定行き先を前日の末尾へ移動する
    ///
    /// 初日、または未知の ID の場合は何もしない
    mutating func moveSpotToPreviousDay(spotID: UUID) {
        guard let location = locationOfSpot(spotID: spotID) else { return }
        let previousDayIndex = location.dayIndex - 1
        guard previousDayIndex >= 0 else { return }

        moveSpot(spotID: spotID, toDayIndex: previousDayIndex, toSpotIndex: nil)
    }

    /// 確定行き先を翌日の末尾へ移動する
    ///
    /// 最終日、または未知の ID の場合は何もしない
    mutating func moveSpotToNextDay(spotID: UUID) {
        guard let location = locationOfSpot(spotID: spotID) else { return }
        let nextDayIndex = location.dayIndex + 1
        guard nextDayIndex < itineraryDays.count else { return }

        moveSpot(spotID: spotID, toDayIndex: nextDayIndex, toSpotIndex: nil)
    }

    /// `spotID` を指定した日に移動する（必要なら挿入位置も指定する）
    ///
    /// - Parameters:
    ///   - spotID: 移動対象の `Spot` の ID
    ///   - toDayIndex: 移動先の日インデックス
    ///   - toSpotIndex: 移動先における挿入位置。nil の場合は末尾に追加する
    ///
    /// 移動先インデックスは範囲外の場合は末尾へ寄せる
    mutating func moveSpot(
        spotID: UUID,
        toDayIndex: Int,
        toSpotIndex: Int? = nil
    ) {
        guard let fromLocation = locationOfSpot(spotID: spotID) else { return }

        // 移動先 day index をクランプ
        let toDay = min(max(0, toDayIndex), itineraryDays.count - 1)

        let movingSpot = itineraryDays[fromLocation.dayIndex].spots.remove(at: fromLocation.spotIndex)

        let destinationSpotsCount = itineraryDays[toDay].spots.count
        let insertIndex: Int = {
            guard let toSpotIndex else { return destinationSpotsCount }
            return min(max(0, toSpotIndex), destinationSpotsCount)
        }()

        // 同一日内の移動で、削除位置より後ろへ挿入する場合はインデックス調整が必要
        if fromLocation.dayIndex == toDay && insertIndex > fromLocation.spotIndex {
            // remove 済みなので挿入位置を 1 減らす
            let adjusted = max(0, insertIndex - 1)
            itineraryDays[toDay].spots.insert(movingSpot, at: adjusted)
        } else {
            itineraryDays[toDay].spots.insert(movingSpot, at: insertIndex)
        }
    }

    /// 候補または確定内から ID 一致の Spot を返す
    func spot(id: Spot.ID) -> Spot? {
        if let candidate = candidateSpots.first(where: { $0.id == id }) {
            return candidate
        }
        for day in itineraryDays {
            if let spot = day.spots.first(where: { $0.id == id }) {
                return spot
            }
        }
        return nil
    }

    /// 確定旅程内の Spot 位置（日 ID と日内 index）
    func confirmedSpotLocation(spotID: Spot.ID) -> (dayID: ItineraryDay.ID, spotIndex: Int)? {
        guard let location = locationOfSpot(spotID: spotID) else {
            return nil
        }
        return (dayID: itineraryDays[location.dayIndex].id, spotIndex: location.spotIndex)
    }

    private func locationOfSpot(spotID: UUID) -> (dayIndex: Int, spotIndex: Int)? {
        for (dayIndex, day) in itineraryDays.enumerated() {
            if let spotIndex = day.spots.firstIndex(where: { $0.id == spotID }) {
                return (dayIndex: dayIndex, spotIndex: spotIndex)
            }
        }
        return nil
    }

    private func globalIndexOfConfirmedSpot(spotID: UUID) -> Int? {
        var index = 0
        for day in itineraryDays {
            for element in day.spots {
                if element.id == spotID {
                    return index
                }
                index += 1
            }
        }
        return nil
    }

    private mutating func swapConfirmedSpots(from i: Int, to j: Int) {
        guard i != j else { return }

        let dayCounts = itineraryDays.map { $0.spots.count }
        var flat = itineraryDays.flatMap(\.spots)
        flat.swapAt(i, j)

        var cursor = 0
        for dayIndex in itineraryDays.indices {
            let count = dayCounts[dayIndex]
            itineraryDays[dayIndex].spots = Array(flat[cursor..<(cursor + count)])
            cursor += count
        }
    }
}
