import SwiftUI
import ComposableArchitecture

struct ItineraryEditorPrototypeView: View {
    let store: StoreOf<ItineraryFeature>
    let tripStartDate: Date

    private var conflictingSpotIDs: Set<Spot.ID> {
        store.itinerary.itineraryDays.reduce(into: Set<Spot.ID>()) {
            result,
            day in

            result.formUnion(
                ItineraryScheduleChecker.conflictingSpotIDs(
                    in: day.spots
                )
            )
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                ForEach(
                    Array(store.itinerary.itineraryDays.enumerated()),
                    id: \.element.id
                ) { dayIndex, day in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(dayTitle(dayIndex))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if hasConflict(in: day) {
                                Button(
                                    "\(dayIndex + 1)日目の重なりを解消"
                                ) {
                                    store.send(
                                        .autoShiftButtonTapped(
                                            dayID: day.id
                                        )
                                    )
                                }
                            }
                        }

                        ForEach(Array(day.spots.enumerated()), id: \.element.id) { index, spot in
                            displayRow(spot: spot, index: index, isLast: day.spots.last?.id == spot.id, isTimeConflict: conflictingSpotIDs.contains(spot.id))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("旅程作成")
    }
    
    @ViewBuilder
    private func displayRow(spot: Spot, index: Int, isLast: Bool, isTimeConflict: Bool) -> some View {
        ItinerarySpotDisplayRow(
            spot: spot,
            index: index,
            isLast: isLast,
            isTimeOrderMisaligned: false,
            isTimeConflict: isTimeConflict
        ) {
            EmptyView()
        }
    }

    private func hasConflict(
        in day: ItineraryDay
    ) -> Bool {
        day.spots.contains {
            conflictingSpotIDs.contains($0.id)
        }
    }

    private func dayTitle(_ dayIndex: Int) -> String {
        return DayTitleFormatter.dayTitleText(tripStartDate: tripStartDate, dayIndex: dayIndex)
    }
}
