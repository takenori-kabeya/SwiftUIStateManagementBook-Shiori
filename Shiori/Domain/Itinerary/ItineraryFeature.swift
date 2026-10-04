import ComposableArchitecture

@Reducer
struct ItineraryFeature {
    struct DaySelectionState: Equatable {
        var spot: Spot
    }

    struct ScheduleShiftPending: Equatable {
        var dayID: ItineraryDay.ID
        var fromSpotID: Spot.ID
    }
    
    @ObservableState
    struct State: Equatable {
        var itinerary: Itinerary
        @Presents var editSpot: SpotFeature.State?
        var daySelection: DaySelectionState?
        var scheduleShiftPending: ScheduleShiftPending?
        var spotPendingDeletion: Spot.ID?
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
        case deleteButtonTapped(spotID: Spot.ID)
        case deleteConfirmed
        case deleteConfirmationDismissed
        case autoShiftButtonTapped(dayID: ItineraryDay.ID)
        case scheduleShiftConfirmed
        case scheduleShiftDismissed
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
            case let .deleteButtonTapped(spotID):
                //state.itinerary.deleteSpot(spotID: spotID)
                state.spotPendingDeletion = spotID
                return .none
            case .deleteConfirmed:
                guard let spotID = state.spotPendingDeletion else {
                    return .none
                }
                state.itinerary.deleteSpot(spotID: spotID)
                state.spotPendingDeletion = nil
                return .none
            case .deleteConfirmationDismissed:
                state.spotPendingDeletion = nil
                return .none
            case let .autoShiftButtonTapped(dayID):
                // 指定日の後続予定をずらす
                state.itinerary.resolveScheduleConflicts(dayID: dayID)
                return .none
            case .scheduleShiftConfirmed:
                guard let pending = state.scheduleShiftPending else {
                    return .none
                }
                state.itinerary.resolveScheduleConflicts(dayID: pending.dayID, fromSpotID: pending.fromSpotID)
                state.scheduleShiftPending = nil
                return .none
            case .scheduleShiftDismissed:
                state.scheduleShiftPending = nil
                return .none
            case let .editSpot(.presented(.delegate(.saveRequested(draft)))):
                guard let previous = state.itinerary.spot(id: draft.id) else {
                    return .none
                }
                let updated = draft.spot()
                state.itinerary.updateSpot(updated)
                state.scheduleShiftPending = scheduleShiftPendingIfNeeded(
                    itinerary: state.itinerary,
                    previous: previous,
                    updated: updated
                )
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

    private func scheduleShiftPendingIfNeeded(
        itinerary: Itinerary,
        previous: Spot,
        updated: Spot
    ) -> ScheduleShiftPending? {
        guard ItineraryScheduleChecker.isScheduleExtension(from: previous, to: updated),
              let location = itinerary.confirmedSpotLocation(spotID: updated.id),
              let day = itinerary.itineraryDays.first(where: { $0.id == location.dayID }),
              location.spotIndex + 1 < day.spots.count else {
            return nil
        }

        let saved = day.spots[location.spotIndex]
        let subsequent = Array(day.spots[(location.spotIndex + 1)...])
        guard ItineraryScheduleChecker.conflictsWithSubsequent(spot: saved, subsequent: subsequent) else {
            return nil
        }

        return ScheduleShiftPending(
            dayID: location.dayID,
            fromSpotID: subsequent[0].id
        )
    }
}
