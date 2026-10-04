import SwiftUI
import ComposableArchitecture

struct TripListView: View {
    @State var store: StoreOf<TripsFeature>
    @State private var newTitle = ""

    
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
                                    store.send(.editButtonTapped(tripStore.info.id))
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
            .sheet(item: $store.scope(state: \.editTrip, action: \.editTrip)) { editStore in
                TripEditorView(store: editStore)
            }
        }
    }
    
    private func addTrip() {
        @Dependency(\.date) var date
        @Dependency(\.uuid) var uuid
        
        let title = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        let trip =
            Trip(info: TripInfo(
                id: uuid(),
                title: title,
                startDate: date.now.date),
                 itinerary: Itinerary(candidateSpots: [], itineraryDays: [ItineraryDay(id: uuid())])
            )
        
        store.send(.addTrip(trip))

        newTitle = ""
    }
    
    private func delete(_ tripId: Trip.ID) {
        store.send(.deleteTrip(tripId))
    }

    
    
}

#Preview {
    TripListView(store: Store(initialState: TripsFeature.State()) {
        TripsFeature()
    })
}
