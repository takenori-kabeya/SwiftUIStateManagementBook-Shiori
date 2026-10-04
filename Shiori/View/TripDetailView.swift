import SwiftUI
import ComposableArchitecture

struct TripDetailView: View {
    var store: StoreOf<TripFeature>

    var body: some View {
        List {
            NavigationLink("旅程を編集") {
                ItineraryEditorView(store: store.scope(state: \.itinerary, action: \.itinerary), tripStartDate: store.info.startDate)
            }
            
            NavigationLink("旅程を見る") {
                ItineraryViewerView(
                    store: store.scope(state: \.itinerary, action: \.itinerary),
                    weatherForecastStore: store.scope(state: \.weatherForecast, action: \.weatherForecast),
                    tripStartDate: store.info.startDate
                )
            }
        }
        .navigationTitle(store.info.title)
    }
}

#Preview {
    @Previewable @State var trip = Trip.previewTrip
    
    NavigationStack {
        TripDetailView(store: Store(initialState: TripFeature.State(trip: trip)) {
            TripFeature()
        })
    }
}
