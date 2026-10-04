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
    }
    
    enum Action {
        case itineraryEditorButtonTapped
        case itineraryViewerButtonTapped
        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case tripUpdated
            case itineraryEditorButtonTapped(Trip.ID)
            case itineraryViewerButtonTapped(Trip.ID)
        }
    }
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch (action) {
            case .itineraryEditorButtonTapped:
                return .send(.delegate(.itineraryEditorButtonTapped(state.id)))
            case .itineraryViewerButtonTapped:
                return .send(.delegate(.itineraryViewerButtonTapped(state.id)))
            case .delegate:
                return .none
            }
        }
    }
}

extension TripFeature.State {
    static func forecastCondition(from draft: TripDraft) -> ForecastCondition {
        ForecastCondition(
            latitude: draft.info.weatherPlace?.latitude,
            longitude: draft.info.weatherPlace?.longitude,
            fromDate: draft.info.startDate,
            numDays: draft.newNumDays
        )
    }
    
    static func forecastCondition(from trip: Trip) -> ForecastCondition {
        ForecastCondition.makeCondition(from: trip)
    }
}
