import SwiftUI
import ComposableArchitecture

struct TripDetailView: View {
    var store: StoreOf<TripFeature>

    var body: some View {
        List {
            Button("旅程を編集") {
                store.send(.itineraryEditorButtonTapped)
            }
            .buttonStyle(.navigationRow)
            Button("旅程を見る") {
                store.send(.itineraryViewerButtonTapped)
            }
            .buttonStyle(.navigationRow)
        }
        .navigationTitle(store.trip.info.title)
    }
}

#Preview {
    @Previewable @State var trip = Trip.previewTrip
    
    NavigationStack {
        TripDetailView(store: Store(initialState: TripFeature.State(trip: Shared(value: trip))) {
            TripFeature()
        })
    }
}
