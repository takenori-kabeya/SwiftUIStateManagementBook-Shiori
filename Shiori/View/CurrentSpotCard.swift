import SwiftUI

struct CurrentSpotCard: View {
    let spot: Spot

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("現在の予定")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(spot.title)
                .font(.title3)
                .bold()

            Text(spot.stayTimeDisplayText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !spot.memo.isEmpty {
                Text(MemoAttributedString.make(from: spot.memo))
                    .font(.body)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.background)
                .padding(8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.quaternary)
                .padding(8)
        )
    }
}

#Preview {
    @Previewable var spot: Spot = TripPersistence.defaultTrip.itinerary.itineraryDays.first!.spots.first!
    CurrentSpotCard(spot: spot)
}
