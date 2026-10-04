import Foundation
import ComposableArchitecture

@Reducer
struct TripsFeature {
    @ObservableState
    struct State: Equatable {
        var trips: IdentifiedArrayOf<TripFeature.State> = []
        var hasLoaded = false
        @Presents var editTrip: TripEditFeature.State?
    }
    
    enum Action {
        case editTrip(PresentationAction<TripEditFeature.Action>)
        case editButtonTapped(Trip.ID)

        case trips(IdentifiedActionOf<TripFeature>)
        case addTrip(Trip)
        case deleteTrip(Trip.ID)
        case updateTrip(Trip)
        case load
        case tripsLoaded([Trip])
        case loadFailed
        case save
        case saveCompleted
        case saveFailed
    }
    
    var body: some Reducer<State, Action> {
        @Dependency(\.tripPersistence) var tripPersistence
        
        Reduce { state, action in
            switch (action) {
            case .trips:
                // TODO: ItineraryFeature/TripFeatureのActionに更新処理以外が入ったら見直し
                return .send(.save)
            case let .addTrip(trip):
                let tripState = TripFeature.State(trip: trip)
                state.trips.append(tripState)
                return .send(.save)
            case let .deleteTrip(id):
                state.trips.remove(id: id)
                return .send(.save)
            case let .updateTrip(trip):
                if let index = state.trips.index(id: trip.id) {
                    state.trips[index] = TripFeature.State(trip: trip)
                }
                return .send(.save)
            case .load:
                guard !state.hasLoaded else { return .none }
                return .run { send in
                    do {
                        let trips = try await tripPersistence.load()
                        await send(.tripsLoaded(trips))
                    }
                    catch {
                        await send(.loadFailed)
                    }
                }
            case let .tripsLoaded(trips):
                let tripStates: [TripFeature.State] = trips.map { TripFeature.State(trip: $0) }
                state.trips = .init(uniqueElements: tripStates)
                state.hasLoaded = true
                return .none
            case .loadFailed:
                // TODO: 現段階ではエラー表示などを省略しているが後で追加する
                return .none
            case .save:
                let tripStates: [TripFeature.State] = state.trips.elements
                let trips: [Trip] = tripStates.map { $0.makeTrip() }
                return .run { send in
                    do {
                        try await tripPersistence.save(trips)
                        await send(.saveCompleted)
                    }
                    catch {
                        await send(.saveFailed)
                    }
                }
            case .saveCompleted:
                // 現段階では特に何もしない予定
                return .none
            case .saveFailed:
                // TODO: 現段階ではエラー表示などを省略しているが後で追加する
                return .none
                
            case let .editTrip(.presented(.delegate(.saveRequested(draft)))):
                guard var tripState = state.trips[id: draft.id] else {
                    return .none
                }
                tripState.info = draft.info
                tripState.itinerary.itinerary.setDayCount(draft.newNumDays)
                state.trips[id: draft.id] = tripState
                return .send(.save)
                
            case .editTrip:
                return .none
                
            case let .editButtonTapped(tripID):
                guard let tripState = state.trips[id: tripID] else {
                    return .none
                }
                let draft = TripDraft(info: tripState.info, itinerary: tripState.itinerary.itinerary)
                state.editTrip = TripEditFeature.State(draft: draft)
                return .none
            }
        }
        .ifLet(\.$editTrip, action: \.editTrip) {
            TripEditFeature()
        }
        .forEach(\.trips, action: \.trips) {
            TripFeature()
        }
    }
}
