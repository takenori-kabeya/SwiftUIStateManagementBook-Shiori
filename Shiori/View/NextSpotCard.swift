import SwiftUI

struct NextSpotCard: View {
    enum Content: Equatable {
        case firstSpot(Spot)
        case spot(Spot)
        case message(String)
    }

    let content: Content

    init(spot: Spot) {
        self.content = .spot(spot)
    }
    
    init(firstSpot: Spot) {
        self.content = .firstSpot(firstSpot)
    }

    init(message: String) {
        self.content = .message(message)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if case .firstSpot = content {
                Text("最初の予定")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            else {
                Text("次の予定")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            switch content {
            case let .firstSpot(spot):
                Text(spot.title)
                    .font(.headline)

                Text(spot.stayTimeDisplayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case let .spot(spot):
                Text(spot.title)
                    .font(.headline)

                Text(spot.stayTimeDisplayText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case let .message(text):
                Text(text)
                    .font(.headline)
            }
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

#Preview("spot") {
    @Previewable var spot: Spot = Trip.previewTrip.itinerary.itineraryDays.first!.spots.first!
    NextSpotCard(spot: spot)
}

#Preview("message") {
    NextSpotCard(message: "予定なし")
}
