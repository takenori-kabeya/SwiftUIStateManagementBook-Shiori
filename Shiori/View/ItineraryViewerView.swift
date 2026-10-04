import SwiftUI

enum ItinerarySpotStatus {
    case none
    case current
    case next
}

struct ItineraryViewerView: View {
    let itinerary: Itinerary

    private var misalignedSpotIDs: Set<UUID> {
        ItineraryScheduleChecker.misalignedSpotIDs(in: itinerary.confirmedSpots)
    }

    private var conflictingSpotIDs: Set<UUID> {
        ItineraryScheduleChecker.conflictingSpotIDs(in: itinerary.confirmedSpots)
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
                if let current = currentSpot(at: now) {
                    CurrentSpotCard(spot: current)
                }

                if let next = nextSpot(at: now) {
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
                        ForEach(Array(itinerary.confirmedSpots.enumerated()), id: \.element.id) { index, spot in
                            ItinerarySpotDisplayRow(
                                spot: spot,
                                index: index,
                                isLast: index == itinerary.confirmedSpots.count - 1,
                                isTimeOrderMisaligned: misalignedSpotIDs.contains(spot.id),
                                isTimeConflict: conflictingSpotIDs.contains(spot.id)
                            ) {
                                statusBadge(for: spot, at: now)
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
        if currentSpot(at: now)?.id == spot.id {
            return .current
        }
        if nextSpot(at: now)?.id == spot.id {
            return .next
        }
        return .none
    }

    private func currentSpot(at now: Date) -> Spot? {
        ItineraryCurrentNextResolver.currentSpot(in: itinerary.confirmedSpots, at: now)
    }

    private func nextSpot(at now: Date) -> Spot? {
        ItineraryCurrentNextResolver.nextSpot(in: itinerary.confirmedSpots, at: now)
    }
    
    private func getTimeOfToday(_ dateTime: Date) -> Date {
        let dateComponents = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: Date.now)
        let timeComponents = Calendar.current.dateComponents([.calendar, .hour, .minute], from: dateTime)
        let time = DateComponents(calendar: dateComponents.calendar, year: dateComponents.year, month: dateComponents.month, day: dateComponents.day, hour: timeComponents.hour, minute: timeComponents.minute).date!
        return time
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    NavigationStack {
        ItineraryViewerView(itinerary: trip.itinerary)
    }
}
