import SwiftUI
import ComposableArchitecture

struct TripEditorView: View {
    let store: StoreOf<TripsFeature>
    @Binding var editingTrip: Trip?
    
    @State var editingTitle: String
    @State var editingStartDate: Date
    @State var editingDayCount: Int
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("旅行名", text: $editingTitle)
                DatePicker("開始日", selection: $editingStartDate, displayedComponents: .date)
                let maxDayCount = max(10, editingTrip?.itinerary.itineraryDays.count ?? 1)
                Stepper(value: $editingDayCount, in: 1...maxDayCount) {
                    Text("\(editingDayCount)日")
                }
            }
            .navigationTitle("旅行を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        editingTrip = nil
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        if let trip = editingTrip {
                            updateTrip(trip)
                        }
                    }
                }
            }
        }
    }
    
    private func updateTrip(_ trip: Trip) {
        let title = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
            return
        }

        var updatedTrip = trip
        updatedTrip.info.title = title
        updatedTrip.info.startDate = editingStartDate
        updatedTrip.itinerary.setDayCount(editingDayCount)

        store.send(.updateTrip(updatedTrip))
        editingTrip = nil
    }
}
