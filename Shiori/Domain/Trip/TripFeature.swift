import Foundation
import ComposableArchitecture

@Reducer
struct TripFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID {
            info.id
        }
        var info: TripInfo
        var itinerary: ItineraryFeature.State
    }
    
    enum Action {
        case itinerary(ItineraryFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.itinerary, action: \.itinerary) {
            ItineraryFeature()
        }
        
        Reduce { state, action in
            switch (action) {
            case .itinerary:
                return .none
            }
        }
    }
}

extension TripFeature.State {
    init(trip: Trip) {
        self.info = trip.info
        self.itinerary = ItineraryFeature.State(
            itinerary: trip.itinerary
        )
    }

    func makeTrip() -> Trip {
        Trip(
            info: info,
            itinerary: itinerary.itinerary
        )
    }
}

