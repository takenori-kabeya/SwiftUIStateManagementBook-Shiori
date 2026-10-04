import SwiftUI

struct TripListView: View {
    @State private var trips: [Trip] = []
    @State private var newTitle = ""

    @State private var editingTrip: Trip?
    @State private var editingTitle = ""
    
    @State private var hasLoaded: Bool = false
    
    @State var isEditing: Bool = false

    let tripPersistence: TripPersistence

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        TextField("旅行名を入力", text: $newTitle)
                        Button("一覧に追加") {
                            addTrip()
                        }
                        .buttonStyle(.borderless)
                        .disabled(newTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .alignmentGuide(.listRowSeparatorLeading) { _ in  0 }

                    ForEach($trips) { $trip in
                        if (isEditing) {
                            HStack {
                                Text(trip.title)
                                Spacer()
                                Button("編集") {
                                    startEditing(trip)
                                }
                                .buttonStyle(.borderless)
                                Button("削除", role: .destructive) {
                                    delete(trip)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        else {
                            NavigationLink(trip.title) {
                                ItineraryEditorView(
                                    itinerary: $trip.itinerary
                                )
                            }
                        }
                    }
                } header: {
                    HStack {
                        Text("旅行")
                        Spacer()
                        CustomEditButton(isEditing: $isEditing)
                        .buttonStyle(.borderless)
                    }
                }
            }
            .navigationTitle("旅行一覧")
            .task {
                guard !hasLoaded else { return }
                
                do {
                    trips = try await tripPersistence.load()
                    hasLoaded = true
                }
                catch {
                    print("読み込み失敗:", error)
                }
            }
            .onDisappear {
                Task {
                    try? await tripPersistence.save(trips)
                }
            }
            .onChange(of: trips) { _, newTrips in
                Task {
                    try? await tripPersistence.save(newTrips)
                }
            }
            .isEditing(isEditing)
            .sheet(item: $editingTrip) { trip in
                NavigationStack {
                    Form {
                        TextField("旅行名", text: $editingTitle)
                    }
                    .navigationTitle("旅行を編集")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                editingTrip = nil
                            }
                        }

                        ToolbarItem(placement: .confirmationAction) {
                            Button("保存") {
                                updateTrip(trip)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func addTrip() {
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        trips.append(
            Trip(
                id: UUID(),
                title: title,
                itinerary: Itinerary()
            )
        )

        newTitle = ""
    }
    
    private func delete(_ trip: Trip) {
        if let index = trips.firstIndex(of: trip) {
            trips.remove(at: index)
        }
    }

    private func startEditing(_ trip: Trip) {
        editingTrip = trip
        editingTitle = trip.title
    }
    
    private func updateTrip(_ trip: Trip) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        if let index = trips.firstIndex(of: trip) {
            trips[index].title = title
            editingTrip = nil
            return
        }
    }
}

#Preview {
    TripListView(tripPersistence: .mock)
}
