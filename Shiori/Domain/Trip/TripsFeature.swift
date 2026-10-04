import Foundation
import ComposableArchitecture

@Reducer
struct TripsFeature {
    @ObservableState
    struct State: Equatable {
        var trips: IdentifiedArrayOf<TripFeature.State> = []
    }
    
    enum Action {
        case trips(IdentifiedActionOf<TripFeature>)
        case addTrip(Trip)
        case deleteTrip(Trip.ID)
        case updateTrip(Trip)
        case setTrips([Trip])
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch (action) {
            case .trips:
                return .none
            case let .addTrip(trip):
                let tripState = TripFeature.State(trip: trip)
                state.trips.append(tripState)
                return .none
            case let .deleteTrip(id):
                state.trips.remove(id: id)
                return .none
            case let .updateTrip(trip):
                if let index = state.trips.index(id: trip.id) {
                    state.trips[index] = TripFeature.State(trip: trip)
                }
                return .none
            case let .setTrips(trips):
                let tripStates: [TripFeature.State] = trips.map { TripFeature.State(trip: $0) }
                state.trips = .init(uniqueElements: tripStates)
                return .none
            }
        }
        .forEach(\.trips, action: \.trips) {
            TripFeature()
        }
    }
}
