import Foundation
import ComposableArchitecture

@Reducer
struct TripEditFeature {
    struct DayCountReductionPending: Equatable {
        var spotTitlesToMove: [String]
    }
    
    @ObservableState
    struct State: Equatable {
        var draft: TripDraft
        var dayCountReductionPending: DayCountReductionPending?
        @Presents var placeSearch: PlaceSearchFeature.State?
    }
    
    enum Action {
        case saveButtonTapped
        case cancelButtonTapped
        
        case titleChanged(String)
        case startDateChanged(Date)
        case numDaysChanged(Int)
        
        case dayCountReductionConfirmed
        case dayCountReductionDismissed
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate {
            case saveRequested(TripDraft)
        }
        
        case placeSearchButtonTapped
        case placeSearch(PresentationAction<PlaceSearchFeature.Action>)
    }
    
    var body: some Reducer<State, Action> {
        @Dependency(\.dismiss) var dismiss
        
        Reduce { state, action in
            switch (action) {
            case let .titleChanged(title):
                state.draft.info.title = title
                return .none
            case let .startDateChanged(startDate):
                state.draft.info.startDate = startDate
                return .none
            case let .numDaysChanged(numDays):
                state.draft.newNumDays = numDays
                return .none
            case .saveButtonTapped:
                if state.draft.newNumDays < state.draft.currentNumDays {
                    state.dayCountReductionPending =
                        DayCountReductionPending(
                            spotTitlesToMove:
                                state.draft.spotTitlesToMoveWhenReducingDayCount(
                                    to: state.draft.newNumDays))
                    return .none
                }
                else {
                    let draft = state.draft
                    return .run { send in
                        await send(.delegate(.saveRequested(draft)))
                        await dismiss()
                    }
                }
            case .dayCountReductionConfirmed:
                state.dayCountReductionPending = nil
                let draft = state.draft
                return .run { send in
                    await send(.delegate(.saveRequested(draft)))
                    await dismiss()
                }
            case .dayCountReductionDismissed:
                state.dayCountReductionPending = nil
                return .none
            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            case .delegate:
                return .none
                
            case .placeSearchButtonTapped:
                state.placeSearch = PlaceSearchFeature.State(selectedPlace: state.draft.info.weatherPlace)
                return .none
                
            case .placeSearch(.presented(.delegate(.confirmed(let place)))):
                state.draft.info.weatherPlace = place
                return .none
                
            case .placeSearch:
                return .none
            }
        }
        .ifLet(\.$placeSearch, action: \.placeSearch) {
            PlaceSearchFeature()
        }
    }
}
