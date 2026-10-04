import SwiftUI

struct TimelineMarkerView: View {
    let index: Int
    let isLast: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text("\(index + 1)")
                .font(.caption)
                .frame(width: 24, height: 24)

            if !isLast {
                Rectangle()
                    .frame(width: 1)
                    .frame(height: 40)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ItinerarySpotInfoView: View {
    let spot: Spot
    let isTimeOrderMisaligned: Bool
    let isTimeConflict: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(spot.title)
                .font(.headline)

            HStack(spacing: 4) {
                Text(spot.stayTimeDisplayText)
                if isTimeConflict {
                    Image(systemName: "clock.badge.exclamationmark")
                        .foregroundStyle(.red)
                }
                if isTimeOrderMisaligned {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !spot.memo.isEmpty {
                Text(spot.memo)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct ItinerarySpotDisplayRow<Trailing: View>: View {
    let spot: Spot
    let index: Int
    let isLast: Bool
    let isTimeOrderMisaligned: Bool
    let isTimeConflict: Bool
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TimelineMarkerView(index: index, isLast: isLast)
                .frame(width: 32)

            ItinerarySpotInfoView(
                spot: spot,
                isTimeOrderMisaligned: isTimeOrderMisaligned,
                isTimeConflict: isTimeConflict
            )
            .frame(maxWidth: .infinity, alignment: .leading)

            trailing()
        }
        .padding()
        .background(rowBackgroundColor)
        .overlay {
            if isTimeConflict || isTimeOrderMisaligned {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(rowBorderColor, lineWidth: 1)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var rowBackgroundColor: Color {
        if isTimeConflict {
            return Color.red.opacity(0.15)
        }
        if isTimeOrderMisaligned {
            return Color.orange.opacity(0.15)
        }
        return Color.clear
    }

    private var rowBorderColor: Color {
        isTimeConflict ? .red : .orange
    }
}
