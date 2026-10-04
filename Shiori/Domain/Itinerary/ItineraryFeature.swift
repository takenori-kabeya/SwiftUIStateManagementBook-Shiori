import ComposableArchitecture

@Reducer
struct ItineraryFeature {
    struct DaySelectionState: Equatable {
        var spot: Spot
    }
    
    @ObservableState
    struct State: Equatable {
        var itinerary: Itinerary
        @Presents var editSpot: SpotFeature.State?
        var daySelection: DaySelectionState?
    }

    enum Action {
        case editSpot(PresentationAction<SpotFeature.Action>)
        case editButtonTapped(Spot)

        case addCandidateButtonTapped(title: String)
        case confirmButtonTapped(Spot)
        case returnToCandidateButtonTapped(spotID: Spot.ID)
        case moveUpButtonTapped(spotID: Spot.ID)
        case moveDownButtonTapped(spotID: Spot.ID)
        case moveToPreviousDayButtonTapped(spotID: Spot.ID)
        case moveToNextDayButtonTapped(spotID: Spot.ID)
        case spotUpdated(Spot)
        case deleteButtonTapped(spotID: Spot.ID)
        case autoShiftButtonTapped(dayID: ItineraryDay.ID)

        case daySelected(dayID: ItineraryDay.ID)
        case daySelectionDismissed
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addCandidateButtonTapped(title):
                state.itinerary.addCandidate(title: title)
                return .none
            case let .confirmButtonTapped(spot):
                state.daySelection = DaySelectionState(spot: spot)
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
            case let .editSpot(.presented(.delegate(.saveRequested(draft)))):
                state.itinerary.updateSpot(draft.spot())
                return .none
            case .editSpot(.dismiss):
                // 特に何もしない
                return .none
            case .editSpot:
                return .none
            case let .editButtonTapped(spot):
                state.editSpot = SpotFeature.State(draft: SpotDraft(spot: spot))
                return .none
            case let .daySelected(dayID):
                guard let spot = state.daySelection?.spot else {
                    return .none
                }
                state.itinerary.confirmCandidate(spotID: spot.id, toDayID: dayID)
                state.daySelection = nil
                return .none
            case .daySelectionDismissed:
                state.daySelection = nil
                return .none
            }
        }
        .ifLet(\.$editSpot, action: \.editSpot) {
            SpotFeature()
        }
    }
}
