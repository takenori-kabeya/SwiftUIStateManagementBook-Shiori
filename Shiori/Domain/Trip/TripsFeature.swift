import Foundation
import ComposableArchitecture
import TCACompatibility

@Reducer
struct TripsFeature {
    @MainActorReducer
    enum Path {
        case tripDetail(TripFeature)
        case itineraryViewer(ItineraryViewerFeature)
        case itineraryEditor(ItineraryFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        @Shared var trips: IdentifiedArrayOf<Trip>
        var path = StackState<Path.State>()
        var hasLoaded = false
        @Presents var editTrip: TripEditFeature.State?
    }
    
    enum Action {
        case path(StackActionOf<Path>)
        
        case tripTapped(Trip.ID)

        case editTrip(PresentationAction<TripEditFeature.Action>)
        case editButtonTapped(Trip.ID)

        case addTrip(Trip)
        case deleteTrip(Trip.ID)
        case tripUpdated
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
            case let .addTrip(trip):
                state.$trips.withLock {
                    _ = $0.append(trip)
                }
                return .send(.tripUpdated)
            case let .deleteTrip(id):
                state.$trips.withLock {
                    _ = $0.remove(id: id)
                }
                return .send(.tripUpdated)
            case .tripUpdated:
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
                state.$trips.withLock {
                    $0 = IdentifiedArray(uniqueElements: trips)
                }
                state.hasLoaded = true
                return .none
            case .loadFailed:
                // TODO: 現段階ではエラー表示などを省略しているが後で追加する
                return .none
            case .save:
                let trips: [Trip] = state.trips.elements
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
                state.$trips.withLock {
                    $0[id: draft.id]?.info = draft.info
                    $0[id: draft.id]?.itinerary.setDayCount(draft.newNumDays)
                }
                if let elementID = findItineraryViewerElementID(in: state.path, tripID: draft.id),
                   let trip = state.trips[id: draft.id] {
                    return .run { send in
                        await send(.path(.element(id: elementID, action: .itineraryViewer(.tripUpdated(trip)))))
                        await send(.tripUpdated)
                    }
                }
                return .send(.tripUpdated)
            case .editTrip:
                return .none
                
            case let .editButtonTapped(tripID):
                guard let trip = state.trips[id: tripID] else {
                    return .none
                }
                let draft = TripDraft(info: trip.info, itinerary: trip.itinerary)
                state.editTrip = TripEditFeature.State(draft: draft)
                return .none
                
            case let .path(.element(_, action: .tripDetail(.delegate(.itineraryEditorButtonTapped(id))))):
                guard let sharedTrip = Shared(state.$trips[id: id]) else {
                    return .none
                }
                state.path.append(.itineraryEditor(ItineraryFeature.State(itinerary: sharedTrip.itinerary, tripStartDate: sharedTrip.info.startDate)))
                return .none
                
            case let .path(.element(_, action: .tripDetail(.delegate(.itineraryViewerButtonTapped(id))))):
                guard let sharedTrip = Shared(state.$trips[id: id]) else {
                    return .none
                }
                let forecastCondition = ForecastCondition.makeCondition(from: sharedTrip.wrappedValue)
                let weatherForecastState = WeatherForecastFeature.State(forecastCondition: forecastCondition)
                state.path.append(.itineraryViewer(ItineraryViewerFeature.State(
                    tripID: sharedTrip.id.wrappedValue,
                    itinerary: sharedTrip.itinerary,
                    tripStartDate: sharedTrip.info.startDate,
                    weatherForecast: weatherForecastState)))
                return .none
            case .path(.element(_, action: .tripDetail(.delegate(.tripUpdated)))):
                return .send(.tripUpdated)
            case .path(.element(_, action: .itineraryEditor(.delegate(.itineraryUpdated)))):
                return .send(.tripUpdated)
            case .path:
                return .none
                
            case let .tripTapped(tripID):
                guard let sharedTrip = Shared(state.$trips[id: tripID]) else {
                    return .none
                }
                state.path.append(.tripDetail(TripFeature.State(trip: sharedTrip)))
                return .none
            }
        }
        .ifLet(\.$editTrip, action: \.editTrip) {
            TripEditFeature()
        }
        .forEach(\.path, action: \.path)
    }
    
    private func findTripDetailElementID(
        in path: StackState<Path.State>,
        tripID: Trip.ID
    ) -> StackElementID? {
        path.ids.first { elementID in
            if case let .tripDetail(tripFeatureState) = path[id: elementID] {
                return tripFeatureState.id == tripID
            }
            return false
        }
    }
    
    private func findItineraryViewerElementID(
        in path: StackState<Path.State>,
        tripID: Trip.ID
    ) -> StackElementID? {
        path.ids.first { elementID in
            if case let .itineraryViewer(viewerFeatureState) = path[id: elementID] {
                return viewerFeatureState.tripID == tripID
            }
            return false
        }
    }
}

extension TripsFeature.Path.State : Equatable {}
