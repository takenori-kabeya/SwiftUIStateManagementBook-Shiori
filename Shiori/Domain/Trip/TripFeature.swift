import Foundation
import ComposableArchitecture

@Reducer
struct TripFeature {
    @ObservableState
    struct State: Equatable, Identifiable {
        var id: UUID {
            trip.id
        }
        @Shared var trip: Trip
        var itinerary: ItineraryFeature.State
        var weatherForecast: WeatherForecastFeature.State
    }
    
    enum Action {
        case itinerary(ItineraryFeature.Action)
        case weatherForecast(WeatherForecastFeature.Action)
        case tripUpdateRequested(TripDraft)
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case tripUpdated
        }
    }
    
    var body: some Reducer<State, Action> {
        Scope(state: \.itinerary, action: \.itinerary) {
            ItineraryFeature()
        }
        Scope(state: \.weatherForecast, action: \.weatherForecast) {
            WeatherForecastFeature()
        }

        Reduce { state, action in
            switch (action) {
            case .itinerary(.delegate(.itineraryUpdated)):
                return .send(.delegate(.tripUpdated))
            case .itinerary:
                return .none
            case .weatherForecast:
                return .none
            case let .tripUpdateRequested(draft):
                let previous = state.weatherForecast.forecastCondition
                state.$trip.withLock {
                    $0.info = draft.info
                }
                state.itinerary.$itinerary.withLock {
                    $0.setDayCount(draft.newNumDays)
                }
                let next = State.forecastCondition(from: draft)
                if previous != next {
                    return .run { send in
                        await send(.weatherForecast(.forecastConditionUpdated(next)))
                        await send(.delegate(.tripUpdated))
                    }
                }
                return .send(.delegate(.tripUpdated))
            case .delegate:
                return .none
            }
        }
    }
}

extension TripFeature.State {
    init(trip: Shared<Trip>) {
        self._trip = trip
        self.itinerary = ItineraryFeature.State(
            itinerary: trip.itinerary
        )
        self.weatherForecast = WeatherForecastFeature.State(
            forecastCondition: Self.forecastCondition(from: trip.wrappedValue)
        )
    }

    func makeTrip() -> Trip {
        return trip
    }

    static func forecastCondition(from draft: TripDraft) -> ForecastCondition {
        ForecastCondition(
            latitude: draft.info.weatherPlace?.latitude,
            longitude: draft.info.weatherPlace?.longitude,
            fromDate: draft.info.startDate,
            numDays: draft.newNumDays
        )
    }
    
    static func forecastCondition(from trip: Trip) -> ForecastCondition {
        ForecastCondition(
            latitude: trip.info.weatherPlace?.latitude,
            longitude: trip.info.weatherPlace?.longitude,
            fromDate: trip.info.startDate,
            numDays: trip.itinerary.itineraryDays.count
        )
    }
}
