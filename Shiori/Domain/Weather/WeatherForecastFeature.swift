import Foundation
import ComposableArchitecture

@Reducer
struct WeatherForecastFeature {
    @ObservableState
    struct State: Equatable {
        var forecastCondition: ForecastCondition
        var dailyForecasts: [DailyWeatherForecast]
        var isFetching: Bool = false
        var errorMessage: String?
    }

    enum Action {
        case forecastConditionUpdated(ForecastCondition)
        case refreshRequested
        case fetchResponse(Result<[DailyWeatherForecast], WeatherForecastError>)
    }
    
    nonisolated enum CancellableTask: Hashable, Sendable {
        case fetchForecast
    }

    @Dependency(\.weatherForecast) var weatherForecast

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case let .forecastConditionUpdated(condition):
                state.forecastCondition = condition
                state.resetForecasts()
                state.errorMessage = nil
                state.isFetching = false
                return .cancel(id: CancellableTask.fetchForecast)
                
            case .refreshRequested:
                let condition = state.forecastCondition
                guard let latitude = condition.latitude,
                      let longitude = condition.longitude else {
                    state.resetForecasts()
                    state.errorMessage = WeatherForecastError.noPlaceSelected.localizedDescription
                    state.isFetching = false
                    return .none
                }
                
                state.isFetching = true
                state.errorMessage = nil
                return .run { [weatherForecast] send in
                    do {
                        let forecasts = try await weatherForecast.fetchForecast(
                            latitude,
                            longitude,
                            condition.fromDate,
                            condition.numDays
                        )
                        await send(.fetchResponse(.success(forecasts)))
                    } catch is CancellationError {
                        return
                    } catch let error as WeatherForecastError {
                        await send(.fetchResponse(.failure(error)))
                    } catch {
                        await send(.fetchResponse(.failure(.requestFailed)))
                    }
                }
                .cancellable(id: CancellableTask.fetchForecast, cancelInFlight: true)
                
            case let .fetchResponse(.success(forecasts)):
                state.isFetching = false
                state.dailyForecasts = forecasts
                state.errorMessage = nil
                return .none
                
            case let .fetchResponse(.failure(error)):
                state.isFetching = false
                state.errorMessage = error.localizedDescription
                return .none
            }
        }
    }
}

extension WeatherForecastFeature.State {
    init(forecastCondition: ForecastCondition) {
        self.forecastCondition = forecastCondition
        
        self.dailyForecasts = WeatherForecastFeature.State.makeInitialForecasts(
            fromDate: forecastCondition.fromDate, numDays: forecastCondition.numDays)
    }
    
    static func makeInitialForecasts(fromDate: Date, numDays: Int) -> [DailyWeatherForecast] {
        var forecasts: [DailyWeatherForecast] = []
        for day in (0 ..< numDays) {
            let date = Calendar.current.date(byAdding: .day, value: day, to: fromDate)!
            forecasts.append(DailyWeatherForecast(date: date, availability: .notYet))
        }
        return forecasts
    }
    
    mutating func resetForecasts() {
        self.dailyForecasts = WeatherForecastFeature.State.makeInitialForecasts(
            fromDate: forecastCondition.fromDate, numDays: forecastCondition.numDays)
    }
}
