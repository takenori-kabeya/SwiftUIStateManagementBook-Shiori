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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if let current = ItineraryCurrentNextResolver.currentSpot(
                    in: itinerary,
                    tripStartDate: tripStartDate,
                    now: now
                ) {
                    CurrentSpotCard(spot: current)
                }

                if let next = ItineraryCurrentNextResolver.nextSpot(
                    in: itinerary,
                    tripStartDate: tripStartDate,
                    now: now
                ) {
                    NextSpotCard(spot: next)
                }

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
                                        statusBadge(for: spot, at: now)
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
    private func statusBadge(for spot: Spot, at now: Date) -> some View {
        let status = spotStatus(for: spot, at: now)
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

    private func spotStatus(for spot: Spot, at now: Date) -> ItinerarySpotStatus {
        if ItineraryCurrentNextResolver.currentSpot(
            in: itinerary,
            tripStartDate: tripStartDate,
            now: now
        )?.id == spot.id {
            return .current
        }
        if ItineraryCurrentNextResolver.nextSpot(
            in: itinerary,
            tripStartDate: tripStartDate,
            now: now
        )?.id == spot.id {
            return .next
        }
        return .none
    }

    private func dayTitle(_ dayIndex: Int) -> String {
        return DayTitleFormatter.dayTitleText(tripStartDate: tripStartDate, dayIndex: dayIndex)
    }

}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    NavigationStack {
        ItineraryViewerView(itinerary: trip.itinerary, tripStartDate: trip.info.startDate)
    }
}
