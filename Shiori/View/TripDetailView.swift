import SwiftUI

struct TripDetailView: View {
    @Binding var trip: Trip

    var body: some View {
        List {
            NavigationLink("旅程を編集") {
                ItineraryEditorView(itinerary: $trip.itinerary, tripStartDate: trip.startDate)
            }

            NavigationLink("旅程を見る") {
                ItineraryViewerView(itinerary: trip.itinerary, tripStartDate: trip.startDate)
            }
        }
        .navigationTitle(trip.title)
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    NavigationStack {
        TripDetailView(trip: $trip)
    }
}
