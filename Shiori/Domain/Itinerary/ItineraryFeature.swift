import ComposableArchitecture

@Reducer
struct ItineraryFeature {
    @ObservableState
    struct State: Equatable {
        var itinerary: Itinerary
    }

    enum Action {
        case addCandidateButtonTapped(title: String)
        case confirmButtonTapped(spotID: Spot.ID, dayID: ItineraryDay.ID)
        case returnToCandidateButtonTapped(spotID: Spot.ID)
        case moveUpButtonTapped(spotID: Spot.ID)
        case moveDownButtonTapped(spotID: Spot.ID)
        case moveToPreviousDayButtonTapped(spotID: Spot.ID)
        case moveToNextDayButtonTapped(spotID: Spot.ID)
        case spotUpdated(Spot)
        case deleteButtonTapped(spotID: Spot.ID)
        case autoShiftButtonTapped(dayID: ItineraryDay.ID)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addCandidateButtonTapped(title):
                state.itinerary.addCandidate(title: title)
                return .none
            case let .confirmButtonTapped(spotID, dayID):
                state.itinerary.confirmCandidate(spotID: spotID, toDayID: dayID)
                return .none
            case let .returnToCandidateButtonTapped(spotID):
                state.itinerary.returnSpotToCandidates(spotID: spotID)
                return .none
            case let .moveUpButtonTapped(spotID):
                state.itinerary.moveConfirmedSpotUp(spotID: spotID)
                return .none
            case let .moveDownButtonTapped(spotID):
                state.itinerary.moveConfirmedSpotDown(spotID: spotID)
                return .none
            case let .moveToPreviousDayButtonTapped(spotID):
                state.itinerary.moveSpotToPreviousDay(spotID: spotID)
                return .none
            case let .moveToNextDayButtonTapped(spotID):
                state.itinerary.moveSpotToNextDay(spotID: spotID)
                return .none
            case let .spotUpdated(spot):
                state.itinerary.updateSpot(spot)
                return .none
            case let .deleteButtonTapped(spotID):
                state.itinerary.deleteSpot(spotID: spotID)
                return .none
            case let .autoShiftButtonTapped(dayID):
                // 指定日の後続予定をずらす
                state.itinerary.resolveScheduleConflicts(dayID: dayID)
                return .none
            }
        }
    }
}
