import Foundation
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
        @Shared var itinerary: Itinerary
        @Shared var tripStartDate: Date
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

        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case itineraryUpdated
        }
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .addCandidateButtonTapped(title):
                state.$itinerary.withLock {
                    $0.addCandidate(title: title)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .confirmButtonTapped(spot):
                state.daySelection = DaySelectionState(spot: spot)
                return .none
            case let .returnToCandidateButtonTapped(spotID):
                state.$itinerary.withLock {
                    $0.returnSpotToCandidates(spotID: spotID)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .moveUpButtonTapped(spotID):
                state.$itinerary.withLock {
                    $0.moveConfirmedSpotUp(spotID: spotID)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .moveDownButtonTapped(spotID):
                state.$itinerary.withLock {
                    $0.moveConfirmedSpotDown(spotID: spotID)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .moveToPreviousDayButtonTapped(spotID):
                state.$itinerary.withLock {
                    $0.moveSpotToPreviousDay(spotID: spotID)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .moveToNextDayButtonTapped(spotID):
                state.$itinerary.withLock {
                    $0.moveSpotToNextDay(spotID: spotID)
                }
                return .send(.delegate(.itineraryUpdated))
            case let .deleteButtonTapped(spotID):
                state.spotPendingDeletion = spotID
                return .none
            case .deleteConfirmed:
                guard let spotID = state.spotPendingDeletion else {
                    return .none
                }
                state.$itinerary.withLock {
                    $0.deleteSpot(spotID: spotID)
                }
                state.spotPendingDeletion = nil
                return .send(.delegate(.itineraryUpdated))
            case .deleteConfirmationDismissed:
                state.spotPendingDeletion = nil
                return .none
            case let .autoShiftButtonTapped(dayID):
                // 指定日の後続予定をずらす
                state.$itinerary.withLock {
                    $0.resolveScheduleConflicts(dayID: dayID)
                }
                return .send(.delegate(.itineraryUpdated))
            case .scheduleShiftConfirmed:
                guard let pending = state.scheduleShiftPending else {
                    return .none
                }
                state.$itinerary.withLock {
                    $0.resolveScheduleConflicts(
                        dayID: pending.dayID,
                        fromSpotID: pending.fromSpotID
                    )
                }
                state.scheduleShiftPending = nil
                return .send(.delegate(.itineraryUpdated))
            case .scheduleShiftDismissed:
                state.scheduleShiftPending = nil
                return .none
            case let .editSpot(.presented(.delegate(.saveRequested(draft)))):
                guard let previous = state.itinerary.spot(id: draft.id) else {
                    return .none
                }
                let updated = draft.spot()
                state.$itinerary.withLock {
                    $0.updateSpot(updated)
                }
                state.scheduleShiftPending = scheduleShiftPendingIfNeeded(
                    itinerary: state.itinerary,
                    previous: previous,
                    updated: updated
                )
                return .send(.delegate(.itineraryUpdated))
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
                state.$itinerary.withLock {
                    $0.confirmCandidate(spotID: spot.id, toDayID: dayID)
                }
                state.daySelection = nil
                return .send(.delegate(.itineraryUpdated))
            case .daySelectionDismissed:
                state.daySelection = nil
                return .none
            case .delegate:
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

extension ItineraryFeature.State {
    init(
        tripStartDate: Shared<Date>,
        itinerary: Shared<Itinerary>,
        editSpot: SpotFeature.State? = nil,
        daySelection: ItineraryFeature.DaySelectionState? = nil,
        spotPendingDeletion: Spot.ID? = nil,
        scheduleShiftPending: ItineraryFeature.ScheduleShiftPending? = nil
    ) {
        self._itinerary = itinerary
        self._tripStartDate = tripStartDate
        self.editSpot = editSpot
        self.daySelection = daySelection
        self.spotPendingDeletion = spotPendingDeletion
        self.scheduleShiftPending = scheduleShiftPending
    }
}
