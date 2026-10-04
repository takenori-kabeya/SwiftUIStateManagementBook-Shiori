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
    let isLast: Bool
    let isReordering: Bool
    let isTimeOrderMisaligned: Bool
    let isTimeConflict: Bool
    
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onReturnToCandidates: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        ItinerarySpotDisplayRow(
            spot: spot,
            index: index,
            isLast: isLast,
            isTimeOrderMisaligned: isTimeOrderMisaligned,
            isTimeConflict: isTimeConflict
        ) {
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
            
            if isReordering {
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
                    .disabled(isLast)
                    Spacer()
                }
            }
        }
    }
}

struct ConfirmedItineraryView: View {
    let spots: [Spot]
    let misalignedSpotIDs: Set<UUID>
    let conflictingSpotIDs: Set<UUID>

    let onMoveUp: (Spot) -> Void
    let onMoveDown: (Spot) -> Void
    let onReturnToCandidate: (Spot) -> Void
    let onEdit: (Spot) -> Void
    let onDelete: (Spot) -> Void
    
    @State private var isReordering: Bool = false
    
    var body: some View {
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
                ForEach(Array(spots.enumerated()), id: \.element.id) { index, spot in
                    ItinerarySpotRow(
                        spot: spot,
                        index: index,
                        isLast: index == spots.count - 1,
                        isReordering: isReordering,
                        isTimeOrderMisaligned: misalignedSpotIDs.contains(spot.id),
                        isTimeConflict: conflictingSpotIDs.contains(spot.id),
                        onMoveUp: { withAnimation { onMoveUp(spot) } },
                        onMoveDown: { withAnimation { onMoveDown(spot) } },
                        onReturnToCandidates: { onReturnToCandidate(spot) },
                        onEdit: { onEdit(spot) },
                        onDelete: { onDelete(spot) })
                }
            }
        }
    }
}

struct ItineraryEditorView: View {
    @Binding var itinerary: Itinerary
    @State private var newTitle = ""

    @State var isEditing: Bool = false

    @State private var editingSpot: Spot?
    @State private var editingDraft: SpotDraft = .empty

    private var timeMisalignedSpotIDs: Set<UUID> {
        ItineraryScheduleChecker.misalignedSpotIDs(in: itinerary.confirmedSpots)
    }

    private var timeConflictingSpotIDs: Set<UUID> {
        ItineraryScheduleChecker.conflictingSpotIDs(in: itinerary.confirmedSpots)
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                CandidateSpotsView(
                    newTitle: $newTitle,
                    spots: itinerary.candidateSpots,
                    onAdd: addCandidate,
                    onAddToItinerary: confirm,
                    onEdit: startEditing,
                    onDelete: delete)
               ConfirmedItineraryView(
                    spots: itinerary.confirmedSpots,
                    misalignedSpotIDs: timeMisalignedSpotIDs,
                    conflictingSpotIDs: timeConflictingSpotIDs,
                    onMoveUp: moveConfirmedSpotUp,
                    onMoveDown: moveConfirmedSpotDown,
                    onReturnToCandidate: unconfirm,
                    onEdit: startEditing,
                    onDelete: delete)
            }
            .padding()
        }
        .navigationTitle("旅程作成")
        .isEditing(isEditing)
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
                    TextField("メモ", text: $editingDraft.memo)
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

    private func confirm(_ spot: Spot) {
        guard let index = indexOfCandidate(spot) else {
            return
        }

        let elem = itinerary.candidateSpots.remove(at: index)
        itinerary.confirmedSpots.append(elem)
    }

    private func unconfirm(_ spot: Spot) {
        guard let index = indexOfConfirmed(spot) else {
            return
        }

        let elem = itinerary.confirmedSpots.remove(at: index)
        itinerary.candidateSpots.append(elem)
    }

    private func delete(_ spot: Spot) {
        itinerary.candidateSpots.removeAll { $0.id == spot.id }
        itinerary.confirmedSpots.removeAll { $0.id == spot.id }
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

        if let index = indexOfConfirmed(spot) {
            let spot = editingDraft.spot()
            itinerary.confirmedSpots[index] = spot
            editingSpot = nil
            return
        }
    }

    private func moveConfirmedSpotUp(_ spot: Spot) {
        guard let index = indexOfConfirmed(spot), 0 < index else {
            return
        }

        itinerary.confirmedSpots.swapAt(index, index - 1)
    }

    private func moveConfirmedSpotDown(_ spot: Spot) {
        guard let index = indexOfConfirmed(spot),
              index < itinerary.confirmedSpots.count - 1 else {
            return
        }

        itinerary.confirmedSpots.swapAt(index, index + 1)
    }

    private func indexOfCandidate(_ spot: Spot) -> Int? {
        itinerary.candidateSpots.firstIndex { $0.id == spot.id }
    }
    
    private func indexOfConfirmed(_ spot: Spot) -> Int? {
        itinerary.confirmedSpots.firstIndex { $0.id == spot.id }
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    ItineraryEditorView(itinerary: $trip.itinerary)
}
