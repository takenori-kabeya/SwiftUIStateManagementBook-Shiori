import ComposableArchitecture

@Reducer
struct ItineraryFeature {
    @ObservableState
    struct State: Equatable {
        var itinerary: Itinerary
    }

    enum Action {
        case autoShiftButtonTapped(dayID: ItineraryDay.ID)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .autoShiftButtonTapped(dayID):
                // 指定日の後続予定をずらす
                state.itinerary.resolveScheduleConflicts(dayID: dayID)
                return .none
            }
        }
    }
}
