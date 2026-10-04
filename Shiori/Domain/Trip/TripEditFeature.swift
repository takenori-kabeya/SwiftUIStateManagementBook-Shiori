import ComposableArchitecture

@Reducer
struct TripEditFeature {
    @ObservableState
    struct State: Equatable {
        var draft: TripDraft
    }
    
    enum Action {
        case saveButtonTapped
        case cancelButtonTapped
        
        case numDaysChanged(Int)
        
        case delegate(Delegate)
        @CasePathable
        enum Delegate {
            case saveRequested(TripDraft)
        }
    }
    
    var body: some Reducer<State, Action> {
        @Dependency(\.dismiss) var dismiss
        
        Reduce { state, action in
            switch (action) {
            case let .numDaysChanged(numDays):
                state.draft.numDays = numDays
                return .none
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
            case .delegate:
                return .none
            }
        }
    }
}
