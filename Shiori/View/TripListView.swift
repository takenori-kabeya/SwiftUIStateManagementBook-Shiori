import SwiftUI
import ComposableArchitecture

struct TripListView: View {
    @State var store: StoreOf<TripsFeature>
    @State private var newTitle = ""

    @State private var editingTrip: Trip?
    @State private var editingTitle = ""
    @State private var editingStartDate: Date = Date.now.date
    @State private var editingDayCount: Int = 1
    
    @State var isEditing: Bool = false

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

                    ForEach(store.scope(state: \.trips, action: \.trips)) { tripStore in
                        if (isEditing) {
                            HStack {
                                Text(tripStore.info.title)
                                Spacer()
                                Button("編集") {
                                    startEditing(tripStore.state.makeTrip())
                                }
                                .buttonStyle(.borderless)
                                Button("削除", role: .destructive) {
                                    delete(tripStore.info.id)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        else {
                            NavigationLink(tripStore.info.title) {
                                TripDetailView(store: tripStore)
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
                store.send(.load)
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
    })
}
