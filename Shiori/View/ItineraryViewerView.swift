import SwiftUI

struct ItineraryViewerView: View {
    let itinerary: Itinerary

    var body: some View {
        List {
            Section("旅程") {
                ForEach(Array(itinerary.confirmedSpots.enumerated()), id: \.element.id) { index, spot in
                    HStack {
                        Text("\(index + 1)")
                        Text(spot.title)
                    }
                }
            }
        }
        .navigationTitle("旅程を見る")
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    NavigationStack {
        ItineraryViewerView(itinerary: trip.itinerary)
    }
}
