import ComposableArchitecture
import Foundation

@Reducer
struct ItineraryViewerFeature {
    @ObservableState
    struct State: Equatable {
        let tripID: Trip.ID
        @Shared var itinerary: Itinerary
        @Shared var tripStartDate: Date
        var weatherForecast: WeatherForecastFeature.State
    }
    
    enum Action {
        case weatherForecast(WeatherForecastFeature.Action)
        case tripUpdated(Trip)
        case spotTapped(Spot.ID)
        case delegate(Delegate)
        
        @CasePathable
        enum Delegate {
            case showSpotDetailRequested(Trip.ID, Spot.ID)
        }
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.weatherForecast, action: \.weatherForecast) {
            WeatherForecastFeature()
        }

        Reduce { state, action in
            switch action {
            case let .tripUpdated(trip):
                let previous = state.weatherForecast.forecastCondition
                let next = ForecastCondition.makeCondition(from: trip)
                if previous != next {
                    return .send(.weatherForecast(.forecastConditionUpdated(next)))
                }
                return .none
            case let .spotTapped(spotID):
                return .send(.delegate(.showSpotDetailRequested(state.tripID, spotID)))
            case .weatherForecast:
                return .none
            case .delegate:
                return .none
            }
        }
    }
}


