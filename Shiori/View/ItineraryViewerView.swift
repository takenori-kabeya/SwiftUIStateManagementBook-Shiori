import SwiftUI

struct ItineraryViewerView: View {
    let itinerary: Itinerary

    var body: some View {
        List {
            Section("現在の予定(\(Date.now.formatted(date: .omitted, time: .shortened)) 時点)") {
                if let current = currentSpot {
                    SpotSummaryView(spot: current)
                } else {
                    Text("現在の予定はありません")
                        .foregroundStyle(.secondary)
                }
            }

            Section("次の予定") {
                if let next = nextSpot {
                    SpotSummaryView(spot: next)
                } else {
                    Text("次の予定はありません")
                        .foregroundStyle(.secondary)
                }
            }
            Section("旅程全体") {
                ForEach(Array(itinerary.confirmedSpots.enumerated()), id: \.element.id) { index, spot in
                    HStack {
                        Text("\(index + 1)")
                        Text(spot.title)
                        Spacer()
                        if let current = currentSpot, current.id == spot.id {
                            Text("現在")
                        }
                        else if let next = nextSpot, next.id == spot.id {
                            Text("次")
                        }
                    }
                }
            }
        }
        .navigationTitle("旅程を見る")
    }
    
    private var currentSpot: Spot? {
        let now = Date.now
        for spot in (self.itinerary.confirmedSpots) {
            guard let startDateTime = spot.startTime else {
                continue
            }
            guard let duration = spot.durationMinutes else {
                continue
            }
            let dateComponents = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: Date.now)
            let timeComponents = Calendar.current.dateComponents([.calendar, .hour, .minute], from: startDateTime)
            let startTime = DateComponents(calendar: dateComponents.calendar, year: dateComponents.year, month: dateComponents.month, day: dateComponents.day, hour: timeComponents.hour, minute: timeComponents.minute).date!
            
            let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
            if startTime <= now && now <= endTime {
                return spot
            }
        }
        return nil
    }
    private var nextSpot: Spot? {
        // いまの予定が見つかれば、その次の予定を返す
        if let current = currentSpot {
            guard let currentIndex = itinerary.confirmedSpots.firstIndex(of: current) else {
                return nil
            }
            let nextIndex = currentIndex.advanced(by: 1)
            guard let lastIndex = itinerary.confirmedSpots.indices.last, nextIndex <= lastIndex else {
                return nil
            }
            return itinerary.confirmedSpots[nextIndex]
        }
        // いまの予定が見つからない場合は、いまの時刻以降で、もっとも早い予定を返す
        else {
            let now = Date.now
            let spotWithTime = itinerary.confirmedSpots.filter({
                $0.startTime != nil &&
                now <= getTimeOfToday($0.startTime!)
            })
            if spotWithTime.isEmpty {
                return nil
            }
            let sorted = spotWithTime.sorted(by: { $0.startTime! < $1.startTime! })
            return sorted.first
        }
    }
    
    private func getTimeOfToday(_ dateTime: Date) -> Date {
        let dateComponents = Calendar.current.dateComponents([.calendar, .year, .month, .day], from: Date.now)
        let timeComponents = Calendar.current.dateComponents([.calendar, .hour, .minute], from: dateTime)
        let time = DateComponents(calendar: dateComponents.calendar, year: dateComponents.year, month: dateComponents.month, day: dateComponents.day, hour: timeComponents.hour, minute: timeComponents.minute).date!
        return time
    }
}

#Preview {
    @Previewable @State var trip = TripPersistence.defaultTrip
    
    NavigationStack {
        ItineraryViewerView(itinerary: trip.itinerary)
    }
}
