import SwiftUI
import ComposableArchitecture

struct TripListView: View {
    @State var store: StoreOf<TripsFeature>
    @State private var newTitle = ""

    
    @State var isEditing: Bool = false

    var body: some View {
        NavigationStack(path: $store.scope(state: \.path, action: \.path)) {
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

                    ForEach(store.trips) { trip in
                        if (isEditing) {
                            HStack {
                                Text(trip.info.title)
                                Spacer()
                                Button("編集") {
                                    store.send(.editButtonTapped(trip.info.id))
                                }
                                .buttonStyle(.borderless)
                                Button("削除", role: .destructive) {
                                    delete(trip.info.id)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        else {
                            Button(trip.info.title) {
                                store.send(.tripTapped(trip.id))
                            }
                            .buttonStyle(.navigationRow)
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
        } destination: { childStore in
            switch (childStore.case) {
            case let .tripDetail(tripDetailStore):
                TripDetailView(store: tripDetailStore)
            case let .itineraryViewer(viewerStore):
                ItineraryViewerView(store: viewerStore)
            case let .itineraryEditor(editorStore):
                ItineraryEditorView(store: editorStore)
            case let .spotDetail(spotDetailStore):
                SpotDetailView(store: spotDetailStore)
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
    TripListView(store: Store(initialState: TripsFeature.State(trips: Shared(value: []))) {
        TripsFeature()
    })
}
