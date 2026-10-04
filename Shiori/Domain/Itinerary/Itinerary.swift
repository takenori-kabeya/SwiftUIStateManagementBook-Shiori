import Foundation

/// 日別行き先
nonisolated struct ItineraryDay: Identifiable, Codable, Equatable {
    let id: UUID
    var spots: [Spot] = []
}


/// 旅程
nonisolated struct Itinerary: Codable, Equatable {
    /// 行き先候補
    var candidateSpots: [Spot] = []
    
    /// 確定行き先
    var itineraryDays: [ItineraryDay] = [ItineraryDay(id: UUID())]

    enum CodingKeys: String, CodingKey {
        case candidateSpots
        case itineraryDays
    }

    init(candidateSpots: [Spot] = [], itineraryDays: [ItineraryDay] = [ItineraryDay(id: UUID())]) {
        self.candidateSpots = candidateSpots
        self.itineraryDays = itineraryDays.isEmpty ? [ItineraryDay(id: UUID())] : itineraryDays
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        candidateSpots = try container.decode([Spot].self, forKey: .candidateSpots)

        let days = try container.decode([ItineraryDay].self, forKey: .itineraryDays)
        itineraryDays = days.isEmpty ? [ItineraryDay(id: UUID())] : days
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
        let newCount = max(1, count)
        let currentCount = itineraryDays.count

        guard newCount != currentCount else { return }

        if newCount > currentCount {
            let additional = (currentCount..<newCount).map { _ in ItineraryDay(id: UUID(), spots: []) }
            itineraryDays.append(contentsOf: additional)
            return
        }

        // newCount < currentCount
        let lastKeptIndex = newCount - 1
        let spotsToMove = itineraryDays[(lastKeptIndex + 1)..<currentCount].flatMap { $0.spots }
        itineraryDays.removeLast(currentCount - newCount)
        itineraryDays[lastKeptIndex].spots.append(contentsOf: spotsToMove)
    }

    /// 候補の `spotID` を指定した日の末尾へ確定する
    ///
    /// - Parameters:
    ///   - spotID: 候補にある `Spot` の ID
    ///   - toDayIndex: 追加先の日インデックス
    ///
    /// 日インデックスは範囲外の場合はクランプする。未知の ID の場合は何もしない
    mutating func confirmCandidate(spotID: UUID, toDayIndex: Int) {
        guard let index = candidateSpots.firstIndex(where: { $0.id == spotID }) else {
            return
        }

        let toDay = min(max(0, toDayIndex), itineraryDays.count - 1)
        let spot = candidateSpots.remove(at: index)
        itineraryDays[toDay].spots.append(spot)
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

    private func locationOfSpot(spotID: UUID) -> (dayIndex: Int, spotIndex: Int)? {
        for (dayIndex, day) in itineraryDays.enumerated() {
            if let spotIndex = day.spots.firstIndex(where: { $0.id == spotID }) {
                return (dayIndex: dayIndex, spotIndex: spotIndex)
            }
        }
        return nil
    }
}
