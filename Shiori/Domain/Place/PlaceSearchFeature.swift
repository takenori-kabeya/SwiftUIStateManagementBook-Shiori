import Foundation
import ComposableArchitecture

@Reducer
struct PlaceSearchFeature {
    @ObservableState
    struct State: Equatable {
        var query: String = ""
        var candidates: IdentifiedArrayOf<PlaceCandidate> = []
        var selectedPlace: Place?
        var isSearching: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case queryChanged(String)
        case searchButtonTapped
        case searchResponse(Result<[PlaceCandidate], PlaceSearchError>)
        case candidateSelected(PlaceCandidate.ID)
        case confirmButtonTapped
        case cancelButtonTapped

        case delegate(Delegate)
        @CasePathable
        enum Delegate: Equatable {
            case confirmed(Place)
        }
    }

    @Dependency(\.placeSearch) var placeSearch
    @Dependency(\.dismiss) var dismiss

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .queryChanged(query):
                state.query = query
                return .none

            case .searchButtonTapped:
                let trimmedQuery = state.query.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmedQuery.isEmpty else {
                    state.candidates = []
                    state.selectedPlace = nil
                    state.isSearching = false
                    state.errorMessage = PlaceSearchError.emptyQuery.localizedDescription
                    return .none
                }

                state.isSearching = true
                state.errorMessage = nil
                state.selectedPlace = nil
                state.candidates = []
                return .run { [placeSearch] send in
                    do {
                        let places = try await placeSearch.search(trimmedQuery)
                        await send(.searchResponse(.success(places)))
                    } catch let error as PlaceSearchError {
                        await send(.searchResponse(.failure(error)))
                    } catch {
                        await send(.searchResponse(.failure(.searchFailed)))
                    }
                }

            case let .searchResponse(.success(places)):
                state.isSearching = false
                applySearchResults(places, to: &state)
                return .none

            case let .searchResponse(.failure(error)):
                state.isSearching = false
                state.candidates = []
                state.selectedPlace = nil
                state.errorMessage = error.localizedDescription
                return .none

            case let .candidateSelected(id):
                guard let candidate = state.candidates[id: id] else {
                    return .none
                }
                state.selectedPlace = candidate.place
                state.errorMessage = nil
                return .none

            case .confirmButtonTapped:
                guard let place = state.selectedPlace else {
                    return .none
                }
                return .run { send in
                    await send(.delegate(.confirmed(place)))
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

    private func applySearchResults(_ places: [PlaceCandidate], to state: inout State) {
        switch places.count {
        case 0:
            state.candidates = []
            state.selectedPlace = nil
            state.errorMessage = PlaceSearchError.notFound.localizedDescription
        case 1:
            state.candidates = []
            state.selectedPlace = places[0].place
            state.errorMessage = nil
        default:
            state.candidates = .init(uniqueElements: places)
            state.selectedPlace = nil
            state.errorMessage = nil
        }
    }
}
