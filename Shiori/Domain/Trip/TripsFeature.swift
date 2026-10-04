import Foundation
import ComposableArchitecture

/*
@Reducer
struct TripsFeature {
    @ObservableState
    struct State: Equatable {
        var trips: [TripFeature.State]
    }
    
    enum Action {
        case trip(TripFeature.Action)
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \trips, action: \.trip) {
            TripFeature()
        }
        Reduce { state, action in
            switch (action) {
            case .trip:
                return .none
            }
        }
    }
}
*/

