import SwiftUI

struct NextSpotCard: View {
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("次の予定")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(spot.title)
                .font(.headline)

            Text(spot.stayTimeDisplayText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.thinMaterial)
                .padding(8)
        )
    }
}

#Preview {
    @Previewable var spot: Spot = TripPersistence.defaultTrip.itinerary.itineraryDays.first!.spots.first!
    NextSpotCard(spot: spot)
}
