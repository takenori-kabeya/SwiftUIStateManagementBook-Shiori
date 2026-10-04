import SwiftUI

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
                                .padding(.leading, 4)
                            Spacer()
                        }

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
}

struct ItineraryEditorView: View {
    @Binding var itinerary: Itinerary
    let tripStartDate: Date
    @State private var newTitle = ""

    @State private var editingSpot: Spot?
    @State private var editingDraft: SpotDraft = .empty
    @State private var spotPendingConfirmation: Spot?

    private var timeMisalignedSpotIDs: Set<UUID> {
        itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.misalignedSpotIDs(in: day.spots))
        }
    }

    private var timeConflictingSpotIDs: Set<UUID> {
        itinerary.itineraryDays.reduce(into: Set<UUID>()) { result, day in
            result.formUnion(ItineraryScheduleChecker.conflictingSpotIDs(in: day.spots))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CandidateSpotsView(
                    newTitle: $newTitle,
                    spots: itinerary.candidateSpots,
                    onAdd: addCandidate,
                    onAddToItinerary: { spot in
                        spotPendingConfirmation = spot
                    },
                    onEdit: startEditing,
                    onDelete: delete)
                
                ConfirmedItineraryView(
                    itineraryDays: itinerary.itineraryDays,
                    dayLabel: dayTitle,
                    misalignedSpotIDs: timeMisalignedSpotIDs,
                    conflictingSpotIDs: timeConflictingSpotIDs,
                    onMoveUp: moveConfirmedSpotUp,
                    onMoveDown: moveConfirmedSpotDown,
                    onMoveToPreviousDay: moveConfirmedSpotToPreviousDay,
                    onMoveToNextDay: moveConfirmedSpotToNextDay,
                    onReturnToCandidate: unconfirm,
                    onEdit: startEditing,
                    onDelete: delete)
            }
            .padding()
        }
        .navigationTitle("旅程作成")
        .confirmationDialog(
            "追加する日を選択",
            isPresented: Binding(
                get: { spotPendingConfirmation != nil },
                set: { isPresented in
                    if !isPresented {
                        spotPendingConfirmation = nil
                    }
                }
            ),
            titleVisibility: .visible
        ) {
            if let spot = spotPendingConfirmation {
                ForEach(itinerary.itineraryDays.indices, id: \.self) { dayIndex in
                    Button("\(dayIndex + 1)日目") {
                        confirm(spot, toDayIndex: dayIndex)
                    }
                }
                Button("キャンセル", role: .cancel) {
                    spotPendingConfirmation = nil
                }
            }
        }
        .sheet(item: $editingSpot) { spot in
            NavigationStack {
                Form {
                    TextField("行き先名", text: $editingDraft.title)
                    Toggle("予定到着時刻を指定する", isOn: $editingDraft.hasStartTime)
                    DatePicker("予定到着時刻", selection: $editingDraft.startTime, displayedComponents: .hourAndMinute)
                        .disabled(!editingDraft.hasStartTime)
                    Toggle("予定滞在時間を指定する", isOn: $editingDraft.hasDurationMinutes)
                    Stepper("予定滞在時間: \(editingDraft.durationMinutes) (分)", value: $editingDraft.durationMinutes, in: 5...480, step: 5)
                        .disabled(!editingDraft.hasDurationMinutes)
                    ZStack(alignment: .topLeading) {
                        if editingDraft.memo.isEmpty {
                            Text("メモ")
                                .foregroundStyle(.tertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $editingDraft.memo)
                            .frame(minHeight: 100)
                            .scrollContentBackground(.hidden)
                    }

                }
                .navigationTitle("行き先を編集")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") {
                            editingSpot = nil
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") {
                            updateSpot(spot)
                        }
                    }
                }
            }
        }
    }

    private func dayTitle(_ dayIndex: Int) -> String {
        return DayTitleFormatter.dayTitleText(tripStartDate: tripStartDate, dayIndex: dayIndex)
    }

    private func addCandidate() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        itinerary.candidateSpots.append(
            Spot(
                id: UUID(),
                title: title
            )
        )

        newTitle = ""
    }

    private func confirm(_ spot: Spot, toDayIndex: Int) {
        itinerary.confirmCandidate(spotID: spot.id, toDayIndex: toDayIndex)
        spotPendingConfirmation = nil
    }

    private func unconfirm(_ spot: Spot) {
        guard let location = locationOfConfirmedSpot(spot) else {
            return
        }

        let elem = itinerary.itineraryDays[location.dayIndex].spots.remove(at: location.spotIndex)
        itinerary.candidateSpots.append(elem)
    }

    private func delete(_ spot: Spot) {
        itinerary.candidateSpots.removeAll { $0.id == spot.id }
        for dayIndex in itinerary.itineraryDays.indices {
            itinerary.itineraryDays[dayIndex].spots.removeAll { $0.id == spot.id }
        }
    }

    private func startEditing(_ spot: Spot) {
        editingSpot = spot
        editingDraft = SpotDraft(spot: spot)
    }
    
    private func updateSpot(_ spot: Spot) {
        let title = editingDraft.title.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        if let index = indexOfCandidate(spot) {
            let spot = editingDraft.spot()
            itinerary.candidateSpots[index] = spot
            editingSpot = nil
            return
        }

        if let location = locationOfConfirmedSpot(spot) {
            let spot = editingDraft.spot()
            itinerary.itineraryDays[location.dayIndex].spots[location.spotIndex] = spot
            editingSpot = nil
            return
        }
    }

    private func moveConfirmedSpotUp(_ spot: Spot) {
        guard let globalIndex = globalIndexOfConfirmedSpot(spot) else {
            return
        }
        guard 0 < globalIndex else { return }

        swapConfirmedSpots(from: globalIndex, to: globalIndex - 1)
    }

    private func moveConfirmedSpotDown(_ spot: Spot) {
        guard let globalIndex = globalIndexOfConfirmedSpot(spot) else {
            return
        }
        let flatCount = itinerary.itineraryDays.reduce(0) { $0 + $1.spots.count }
        guard globalIndex < flatCount - 1 else { return }

        swapConfirmedSpots(from: globalIndex, to: globalIndex + 1)
    }

    private func moveConfirmedSpotToPreviousDay(_ spot: Spot) {
        guard let location = locationOfConfirmedSpot(spot) else { return }
        let previousDayIndex = location.dayIndex - 1
        guard previousDayIndex >= 0 else { return }

        itinerary.moveSpot(
            spotID: spot.id,
            toDayIndex: previousDayIndex,
            toSpotIndex: nil
        )
    }

    private func moveConfirmedSpotToNextDay(_ spot: Spot) {
        guard let location = locationOfConfirmedSpot(spot) else { return }
        let nextDayIndex = location.dayIndex + 1
        guard nextDayIndex < itinerary.itineraryDays.count else { return }

        itinerary.moveSpot(
            spotID: spot.id,
            toDayIndex: nextDayIndex,
            toSpotIndex: nil
        )
    }

    private func indexOfCandidate(_ spot: Spot) -> Int? {
        itinerary.candidateSpots.firstIndex { $0.id == spot.id }
    }

    private func locationOfConfirmedSpot(_ spot: Spot) -> (dayIndex: Int, spotIndex: Int)? {
        for (dayIndex, day) in itinerary.itineraryDays.enumerated() {
            if let spotIndex = day.spots.firstIndex(where: { $0.id == spot.id }) {
                return (dayIndex: dayIndex, spotIndex: spotIndex)
            }
        }
        return nil
    }

    private func globalIndexOfConfirmedSpot(_ spot: Spot) -> Int? {
        var index = 0
        for day in itinerary.itineraryDays {
            for element in day.spots {
                if element.id == spot.id {
                    return index
                }
                index += 1
            }
        }
        return nil
    }

    private func swapConfirmedSpots(from i: Int, to j: Int) {
        guard i != j else { return }

        let dayCounts = itinerary.itineraryDays.map { $0.spots.count }
        var flat = itinerary.itineraryDays.flatMap(\.spots)
        flat.swapAt(i, j)

        var cursor = 0
        for dayIndex in itinerary.itineraryDays.indices {
            let count = dayCounts[dayIndex]
            itinerary.itineraryDays[dayIndex].spots = Array(flat[cursor..<(cursor + count)])
            cursor += count
        }
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    ItineraryEditorView(itinerary: $trip.itinerary, tripStartDate: trip.startDate)
}
