import SwiftUI

enum ItinerarySpotStatus {
    case none
    case current
    case next
}

struct ItineraryViewerView: View {
    let itinerary: Itinerary
    let tripStartDate: Date

    private var misalignedSpotIDs: Set<UUID> {
        itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.misalignedSpotIDs(in: day.spots))
        }
    }

    private var conflictingSpotIDs: Set<UUID> {
        itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.conflictingSpotIDs(in: day.spots))
        }
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { context in
            content(now: context.date)
        }
        .navigationTitle("旅程を見る")
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        let highlight = ItineraryCurrentNextResolver.highlight(
            in: itinerary,
            tripStartDate: tripStartDate,
            now: now
        )

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                highlightCards(highlight)

                VStack(alignment: .leading, spacing: 12) {
                    Text("旅程全体")
                        .font(.title3)
                    
                    if !conflictingSpotIDs.isEmpty {
                        Text("予定時間が重なっている行き先があります")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    if !misalignedSpotIDs.isEmpty {
                        Text("並び順と到着時刻が一致していない行き先があります")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }

                    VStack(spacing: 12) {
                        let dayOffsets: [Int] = itinerary.itineraryDays.indices.map { dayIndex in
                            itinerary.itineraryDays[..<dayIndex].reduce(0) { $0 + $1.spots.count }
                        }

                        ForEach(Array(itinerary.itineraryDays.enumerated()), id: \.offset) { dayIndex, day in
                            VStack(alignment: .leading, spacing: 12) {
                                Text(dayTitle(dayIndex))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)

                                ForEach(Array(day.spots.enumerated()), id: \.element.id) { spotIndex, spot in
                                    let globalIndex = dayOffsets[dayIndex] + spotIndex
                                    ItinerarySpotDisplayRow(
                                        spot: spot,
                                        index: globalIndex,
                                        isLast: spotIndex == day.spots.count - 1,
                                        isTimeOrderMisaligned: misalignedSpotIDs.contains(spot.id),
                                        isTimeConflict: conflictingSpotIDs.contains(spot.id)
                                    ) {
                                        statusBadge(for: spot, highlight: highlight)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }

    @ViewBuilder
    private func highlightCards(
        _ highlight: ItineraryCurrentNextResolver.TripSpotHighlight
    ) -> some View {
        switch highlight.current {
        case .hidden:
            EmptyView()
        case .moving, .scheduleFinished:
            CurrentSpotCard(message: currentScheduleText(highlight.current))
        case .spot(let spot):
            CurrentSpotCard(spot: spot)
        }
        switch highlight.next {
        case .spot(let spot):
            NextSpotCard(spot: spot)
        case .firstSpot(let spot):
            NextSpotCard(firstSpot: spot)
        case .noneRegistered, .scheduleFinished:
            NextSpotCard(message: nextScheduleText(highlight.next))
        }
    }

    private func currentScheduleText(
        _ schedule: ItineraryCurrentNextResolver.CurrentSchedule
    ) -> String {
        switch schedule {
        case .moving:
            return "移動中"
        case .scheduleFinished:
            return "予定終了"
        case .hidden, .spot:
            return ""
        }
    }
    
    private func nextScheduleText(
        _ schedule: ItineraryCurrentNextResolver.NextSchedule
    ) -> String {
        switch schedule {
        case .noneRegistered:
            return "予定なし"
        case .scheduleFinished:
            return "予定終了"
        case .firstSpot, .spot:
            return ""
        }
    }

    @ViewBuilder
    private func statusBadge(
        for spot: Spot,
        highlight: ItineraryCurrentNextResolver.TripSpotHighlight
    ) -> some View {
        let status = spotStatus(for: spot, highlight: highlight)
        VStack {
            Spacer()
            if status == .current {
                Text("現在")
            } else if status == .next {
                Text("次")
            }
            Spacer()
        }
    }

    private func spotStatus(
        for spot: Spot,
        highlight: ItineraryCurrentNextResolver.TripSpotHighlight
    ) -> ItinerarySpotStatus {
        switch highlight.current {
        case .spot(let current):
            if current.id == spot.id { return .current }
            break
        default:
            break
        }
        switch highlight.next {
        case .firstSpot(let next):
            if next.id == spot.id { return .next }
            break
        case .spot(let next):
            if next.id == spot.id { return .next }
            break
        default:
            break
        }
        return .none
    }

    private func dayTitle(_ dayIndex: Int) -> String {
        return DayTitleFormatter.dayTitleText(tripStartDate: tripStartDate, dayIndex: dayIndex)
    }

}

#Preview {
    @Previewable @State var trip = Trip.previewTrip
    
    NavigationStack {
        ItineraryViewerView(itinerary: trip.itinerary, tripStartDate: trip.info.startDate)
    }
}
