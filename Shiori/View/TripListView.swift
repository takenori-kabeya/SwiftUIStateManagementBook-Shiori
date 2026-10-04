import SwiftUI

struct TripListView: View {
    @State private var trips: [Trip] = []
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

                    ForEach($trips) { $trip in
                        if (isEditing) {
                            HStack {
                                Text(trip.info.title)
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
                            NavigationLink(trip.info.title) {
                                TripDetailView(
                                    trip: $trip
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

        trips.append(
            Trip(info: TripInfo(
                id: UUID(),
                title: title,
                startDate: Date.now.date),
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
        editingTitle = trip.info.title
        editingStartDate = trip.info.startDate
        editingDayCount = max(1, trip.itinerary.itineraryDays.count)
    }
    
    private func updateTrip(_ trip: Trip) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        if let index = trips.firstIndex(where: { $0.id == trip.id }) {
            trips[index].info.title = title
            trips[index].info.startDate = editingStartDate
            trips[index].itinerary.setDayCount(editingDayCount)
            editingTrip = nil
            return
        }
    }
}

#Preview {
    TripListView(tripPersistence: .mock)
}
