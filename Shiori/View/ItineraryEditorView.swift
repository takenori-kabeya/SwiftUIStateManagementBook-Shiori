import SwiftUI
import ComposableArchitecture

struct CandidateSpotRow: View {
    let spot: Spot
    
    let onAddToItinerary: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            Text(spot.title)
            Spacer()
            Button("旅程に\n追加") {
                onAddToItinerary()
            }
            Menu {
                Button("行き先編集") {
                    onEdit()
                }
                Button("削除", role: .destructive) {
                    onDelete()
                }
            } label: {
                Image(systemName: "ellipsis")
            }
        }
        .padding()
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct CandidateSpotsView: View {
    @Binding var newTitle: String
    
    let spots: [Spot]

    let onAdd: () -> Void
    let onAddToItinerary: (Spot) -> Void
    let onEdit: (Spot) -> Void
    let onDelete: (Spot) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("行き先候補")
                    .font(.title3)
                Text("(行くかも知れない場所)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                HStack {
                    TextField("候補名を入力", text: $newTitle)
                    Button("候補に\n追加") {
                        onAdd()
                    }
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityIdentifier("候補に追加")
                }
                
                VStack(spacing: 8) {
                    ForEach(spots) { spot in
                        CandidateSpotRow(
                            spot: spot,
                            onAddToItinerary: { onAddToItinerary(spot) },
                            onEdit: { onEdit(spot) },
                            onDelete: { onDelete(spot) })
                    }
                }
                
            }
        }
    }
}

struct ItinerarySpotRow: View {
    let spot: Spot
    let index: Int
    let isTimelineLast: Bool
    let isReorderLast: Bool
    let isReordering: Bool
    let canMoveToPreviousDay: Bool
    let canMoveToNextDay: Bool
    let isTimeOrderMisaligned: Bool
    let isTimeConflict: Bool
    
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onMoveToPreviousDay: () -> Void
    let onMoveToNextDay: () -> Void
    let onReturnToCandidates: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ItinerarySpotDisplayRow(
            spot: spot,
            index: index,
            isLast: isTimelineLast,
            isTimeOrderMisaligned: isTimeOrderMisaligned,
            isTimeConflict: isTimeConflict
        ) {
            if !isReordering {
                VStack {
                    Spacer()
                    HStack(alignment: .center) {
                        Button("候補に\n戻す") {
                            onReturnToCandidates()
                        }
                        
                        Menu {
                            Button("行き先編集") {
                                onEdit()
                            }
                            Button("削除", role: .destructive) {
                                onDelete()
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                    Spacer()
                }
            }
            
            if isReordering {
                HStack(spacing: 12) {
                    VStack {
                        Spacer()
                        Button {
                            onMoveUp()
                        } label: {
                            Image(systemName: "arrowtriangle.up.fill")
                        }
                        .scaleEffect(x: 2.0, y: 1.0, anchor: .center)
                        .disabled(index == 0)
                        
                        Button {
                            onMoveDown()
                        } label: {
                            Image(systemName: "arrowtriangle.down.fill")
                        }
                        .scaleEffect(x: 2.0, y: 1.0, anchor: .center)
                        .disabled(isReorderLast)
                        Spacer()
                    }

                    VStack {
                        Spacer()
                        Button {
                            onMoveToPreviousDay()
                        } label: {
                            Image(systemName: "arrowtriangle.up.2.fill")
                        }
                        .scaleEffect(x: 2.0, y: 1.0, anchor: .center)
                        .disabled(!canMoveToPreviousDay)

                        Button {
                            onMoveToNextDay()
                        } label: {
                            Image(systemName: "arrowtriangle.down.2.fill")
                        }
                        .scaleEffect(x: 2.0, y: 1.0, anchor: .center)
                        .disabled(!canMoveToNextDay)
                        Spacer()
                    }
                }
            }
        }
    }
}

struct ConfirmedItineraryView: View {
	let itineraryDays: [ItineraryDay]
    let dayLabel: (Int) -> String
    let misalignedSpotIDs: Set<UUID>
    let conflictingSpotIDs: Set<UUID>

    let onMoveUp: (Spot) -> Void
    let onMoveDown: (Spot) -> Void
    let onMoveToPreviousDay: (Spot) -> Void
    let onMoveToNextDay: (Spot) -> Void
    let onReturnToCandidate: (Spot) -> Void
    let onEdit: (Spot) -> Void
    let onDelete: (Spot) -> Void
    let onResolveConflicts: (ItineraryDay.ID) -> Void

    @State private var isReordering: Bool = false
    
    var body: some View {
        let flatSpotsCount = itineraryDays.reduce(0) { $0 + $1.spots.count }
        let dayOffsets: [Int] = itineraryDays.indices.map { dayIndex in
            itineraryDays[..<dayIndex].reduce(0) { $0 + $1.spots.count }
        }

        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("旅程")
                        .font(.title3)
                    Text("(上から順に回る場所・時間)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button(isReordering ? "完了" : "並べ替え") {
                    withAnimation {
                        isReordering.toggle()
                    }
                }
            }
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
                ForEach(Array(itineraryDays.enumerated()), id: \.offset) { dayIndex, day in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(dayLabel(dayIndex))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Spacer()
                            if dayHasConflict(day) {
                                Button("\(dayIndex + 1)日目の重なりを解消") {
                                    onResolveConflicts(day.id)
                                }
                            }
                        }
                        .padding(.leading, 4)

                        VStack(spacing: 12) {
                            ForEach(Array(day.spots.enumerated()), id: \.element.id) { spotIndex, spot in
                                let globalIndex = dayOffsets[dayIndex] + spotIndex
                                ItinerarySpotRow(
                                    spot: spot,
                                    index: globalIndex,
                                    isTimelineLast: spotIndex == day.spots.count - 1,
                                    isReorderLast: globalIndex == flatSpotsCount - 1,
                                    isReordering: isReordering,
                                    canMoveToPreviousDay: dayIndex > 0,
                                    canMoveToNextDay: dayIndex < itineraryDays.count - 1,
                                    isTimeOrderMisaligned: misalignedSpotIDs.contains(spot.id),
                                    isTimeConflict: conflictingSpotIDs.contains(spot.id),
                                    onMoveUp: { withAnimation { onMoveUp(spot) } },
                                    onMoveDown: { withAnimation { onMoveDown(spot) } },
                                    onMoveToPreviousDay: { withAnimation { onMoveToPreviousDay(spot) } },
                                    onMoveToNextDay: { withAnimation { onMoveToNextDay(spot) } },
                                    onReturnToCandidates: { onReturnToCandidate(spot) },
                                    onEdit: { onEdit(spot) },
                                    onDelete: { onDelete(spot) }
                                )
                            }
                        }
                    }
                }
            }
        }
    }

    private func dayHasConflict(_ day: ItineraryDay) -> Bool {
        day.spots.contains { conflictingSpotIDs.contains($0.id) }
    }
}

struct ItineraryEditorView: View {
    @Bindable var store: StoreOf<ItineraryFeature>
    let tripStartDate: Date
    @State private var newTitle = ""

    private var timeMisalignedSpotIDs: Set<UUID> {
        store.itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.misalignedSpotIDs(in: day.spots))
        }
    }

    private var timeConflictingSpotIDs: Set<UUID> {
        store.itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.conflictingSpotIDs(in: day.spots))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CandidateSpotsView(
                    newTitle: $newTitle,
                    spots: store.itinerary.candidateSpots,
                    onAdd: addCandidate,
                    onAddToItinerary: { spot in
                        store.send(.confirmButtonTapped(spot))
                    },
                    onEdit: startEditing,
                    onDelete: delete)
                
                ConfirmedItineraryView(
                    itineraryDays: store.itinerary.itineraryDays,
                    dayLabel: dayTitle,
                    misalignedSpotIDs: timeMisalignedSpotIDs,
                    conflictingSpotIDs: timeConflictingSpotIDs,
                    onMoveUp: moveConfirmedSpotUp,
                    onMoveDown: moveConfirmedSpotDown,
                    onMoveToPreviousDay: moveConfirmedSpotToPreviousDay,
                    onMoveToNextDay: moveConfirmedSpotToNextDay,
                    onReturnToCandidate: unconfirm,
                    onEdit: startEditing,
                    onDelete: delete,
                    onResolveConflicts: resolveConflicts)
            }
            .padding()
        }
        .navigationTitle("旅程作成")
        .confirmationDialog(
            "追加する日を選択",
            isPresented: Binding(
                get: { store.daySelection != nil },
                set: { isPresented in
                    if !isPresented {
                        store.send(.daySelectionDismissed)
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            ForEach(Array(store.itinerary.itineraryDays.enumerated()), id: \.element.id) { dayIndex, day in
                Button("\(dayIndex + 1)日目") {
                    store.send(.daySelected(dayID: day.id))
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
        .sheet(item: $store.scope(\.editSpot, action: \.editSpot)) { spotStore in
            SpotEditorView(store: spotStore)
        }
    }

    private func dayTitle(_ dayIndex: Int) -> String {
        return DayTitleFormatter.dayTitleText(tripStartDate: tripStartDate, dayIndex: dayIndex)
    }

    private func addCandidate() {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.send(.addCandidateButtonTapped(title: trimmed))
        newTitle = ""
    }

    private func unconfirm(_ spot: Spot) {
        store.send(.returnToCandidateButtonTapped(spotID: spot.id))
    }

    private func delete(_ spot: Spot) {
        store.send(.deleteButtonTapped(spotID: spot.id))
    }

    private func startEditing(_ spot: Spot) {
        store.send(.editButtonTapped(spot))
    }

    private func moveConfirmedSpotUp(_ spot: Spot) {
        store.send(.moveUpButtonTapped(spotID: spot.id))
    }

    private func moveConfirmedSpotDown(_ spot: Spot) {
        store.send(.moveDownButtonTapped(spotID: spot.id))
    }

    private func moveConfirmedSpotToPreviousDay(_ spot: Spot) {
        store.send(.moveToPreviousDayButtonTapped(spotID: spot.id))
    }

    private func moveConfirmedSpotToNextDay(_ spot: Spot) {
        store.send(.moveToNextDayButtonTapped(spotID: spot.id))
    }

    private func resolveConflicts(dayID: ItineraryDay.ID) {
        store.send(.autoShiftButtonTapped(dayID: dayID))
    }
}

#Preview {
    @Previewable @State var trip = Trip.previewTrip
    ItineraryEditorView(store: Store(initialState: ItineraryFeature.State(
        itinerary: trip.itinerary)) {
            ItineraryFeature()
        }, tripStartDate: trip.info.startDate)
}
