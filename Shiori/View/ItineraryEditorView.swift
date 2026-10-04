import SwiftUI

struct ItineraryEditorView: View {
    @Binding var itinerary: Itinerary
    @State private var newTitle = ""

    @State var isEditing: Bool = false

    @State private var editingSpot: Spot?
    @State private var editingTitle = ""

    var body: some View {
        List {
            Section("行き先候補") {
                HStack {
                    TextField("行き先を入力", text: $newTitle)
                    Button("候補に追加") {
                        addCandidate()
                    }
                    .buttonStyle(.borderless)
                    .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .alignmentGuide(.listRowSeparatorLeading) { _ in  0 }

                ForEach(itinerary.candidateSpots) { spot in
                    HStack {
                        Text(spot.title)
                        Spacer()
                        Button("編集") {
                            startEditing(spot)
                        }
                        .buttonStyle(.borderless)
                        Button("旅程に入れる") {
                            confirm(spot)
                        }
                        .buttonStyle(.borderless)
                        Button("削除", role: .destructive) {
                            delete(spot)
                        }
                        .buttonStyle(.borderless)
                        
                    }
                }
            }

            Section {
                ForEach(itinerary.confirmedSpots) { spot in
                    HStack {
                        Text(spot.title)
                        Spacer()
                        Button("編集") {
                            startEditing(spot)
                        }
                        .buttonStyle(.borderless)
                        Button("候補に戻す") {
                            unconfirm(spot)
                        }
                        .buttonStyle(.borderless)
                        Button("削除", role: .destructive) {
                            delete(spot)
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .onMove(perform: moveConfirmedSpots)
            } header: {
                HStack {
                    Text("旅程")
                    Spacer()
                    CustomEditButton(isEditing: $isEditing)
                    .buttonStyle(.borderless)
                }
            }
        }
        .navigationTitle("旅程作成")
        .isEditing(isEditing)
        .sheet(item: $editingSpot) { spot in
            NavigationStack {
                Form {
                    TextField("行き先名", text: $editingTitle)
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
        editingTitle = spot.title
    }
    
    private func updateSpot(_ spot: Spot) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        if let index = indexOfCandidate(spot) {
            itinerary.candidateSpots[index].title = title
            editingSpot = nil
            return
        }

        if let index = indexOfConfirmed(spot) {
            itinerary.confirmedSpots[index].title = title
            editingSpot = nil
            return
        }
    }

    private func moveConfirmedSpots(from source: IndexSet, to spot: Int) {
        itinerary.confirmedSpots.move(fromOffsets: source, toOffset: spot)
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
