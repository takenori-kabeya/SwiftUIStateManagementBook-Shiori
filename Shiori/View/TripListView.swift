import SwiftUI
import ComposableArchitecture

struct TripListView: View {
    @State var store: StoreOf<TripsFeature>
    @State private var newTitle = ""

    @State private var editingTrip: Trip?
    @State private var editingTitle = ""
    @State private var editingStartDate: Date = Date.now.date
    @State private var editingDayCount: Int = 1
    
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

                    ForEach(store.scope(state: \.trips, action: \.trips)) { childStore in
                        if (isEditing) {
                            HStack {
                                Text(childStore.info.title)
                                Spacer()
                                Button("編集") {
                                    startEditing(childStore.state.makeTrip())
                                }
                                .buttonStyle(.borderless)
                                Button("削除", role: .destructive) {
                                    delete(childStore.info.id)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        else {
                            NavigationLink(childStore.info.title) {
                                TripDetailView(store: childStore)
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
                    let trips = try await tripPersistence.load()
                    store.send(.setTrips(trips))
                    hasLoaded = true
                }
                catch {
                    print("読み込み失敗:", error)
                }
            }
            .onDisappear {
                Task {
                    let trips = store.trips.elements.map { $0.makeTrip() }
                    try? await tripPersistence.save(trips)
                }
            }
            .isEditing(isEditing)
            .sheet(item: $editingTrip) { trip in
                NavigationStack {
                    Form {
                        TextField("旅行名", text: $editingTitle)
                        DatePicker("開始日", selection: $editingStartDate, displayedComponents: .date)
                        let maxDayCount = max(10, trip.itinerary.itineraryDays.count)
                        Stepper(value: $editingDayCount, in: 1...maxDayCount) {
                            Text("\(editingDayCount)日")
                        }
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

        let trip =
            Trip(info: TripInfo(
                id: UUID(),
                title: title,
                startDate: Date.now.date),
                itinerary: Itinerary()
            )
        
        store.send(.addTrip(trip))

        newTitle = ""
    }
    
    private func delete(_ tripId: Trip.ID) {
        store.send(.deleteTrip(tripId))
    }

    private func startEditing(_ trip: Trip) {
        editingTrip = trip
        editingTitle = trip.info.title
        editingStartDate = trip.info.startDate
        editingDayCount = max(1, trip.itinerary.itineraryDays.count)
    }
    
    private func updateTrip(_ trip: Trip) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        var updatedTrip = trip
        updatedTrip.info.title = title
        updatedTrip.info.startDate = editingStartDate
        updatedTrip.itinerary.setDayCount(editingDayCount)

        store.send(.updateTrip(updatedTrip))
        editingTrip = nil
    }
}

#Preview {
    TripListView(store: Store(initialState: TripsFeature.State()) {
        TripsFeature()
    }, tripPersistence: .mock)
}
