import Foundation
import ComposableArchitecture

@Reducer
struct SpotFeature {
    @ObservableState
    struct State: Equatable {
        var draft: SpotDraft
    }
    
    enum Action {
        case saveButtonTapped
        case cancelButtonTapped
        
        case titleChanged(String)
        case hasStartTimeChanged(Bool)
        case hasDurationMinutesChanged(Bool)
        case startTimeChanged(Date)
        case durationMinutesChanged(Int)
        case memoChanged(String)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate {
            case saveRequested(SpotDraft)
        }
    }

    var body: some Reducer<State, Action> {
        @Dependency(\.dismiss) var dismiss
        
        Reduce { state, action in
            switch action {
            case .saveButtonTapped:
                let draft = state.draft
                return .run { send in
                    await send(.delegate(.saveRequested(draft)))
                    await dismiss()
                }
            case .cancelButtonTapped:
                return .run { _ in
                    await dismiss()
                }
            case let .titleChanged(newValue):
                state.draft.title = newValue
                return .none
            case let .hasStartTimeChanged(newValue):
                state.draft.hasStartTime = newValue
                return .none
            case let .hasDurationMinutesChanged(newValue):
                state.draft.hasDurationMinutes = newValue
                return .none
            case let .startTimeChanged(newValue):
                state.draft.startTime = newValue
                return .none
            case let .durationMinutesChanged(newValue):
                state.draft.durationMinutes = newValue
                return .none
            case let .memoChanged(newValue):
                state.draft.memo = newValue
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
