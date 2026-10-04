import SwiftUI


struct SpotSummaryView: View {
    let spot: Spot
    
    var body: some View {
        HStack {
            Text("行き先:")
            Spacer()
            Text(spot.title)
        }
        HStack {
            Text("予定滞在時間:")
            Spacer()
            Text(duration)
        }
        if (!spot.memo.isEmpty) {
            VStack {
                HStack {
                    Text("メモ:")
                    Spacer()
                }
                HStack {
                    Text(spot.memo)
                    Spacer()
                }
                .padding(.top, 2)
                .padding(.leading, 8)
            }
        }
    }
    
    private var duration: String {
        guard let startTime = spot.startTime else {
            return "(予定なし)"
        }
        if let durationMinutes = spot.durationMinutes {
            let endTime = startTime.addingTimeInterval(TimeInterval(durationMinutes * 60))
            return startTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits)) + " 〜 " +
            endTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        }
        else {
            return startTime.formatted(Date.FormatStyle(date: .omitted, time: .shortened).hour(.twoDigits(amPM: .omitted)).minute(.twoDigits))
        }
        
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    List {
        SpotSummaryView(spot: trip.itinerary.confirmedSpots.first!)
    }
}
