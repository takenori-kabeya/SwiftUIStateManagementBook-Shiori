//
//  WeatherForecastView.swift
//  ShioriApp
//
//  Created by Takenori Kabeya on 2026/08/04.
//

import SwiftUI
import ComposableArchitecture

struct WeatherForecastView: View {
    @Bindable var store: StoreOf<WeatherForecastFeature>

    private let columnWidth: CGFloat = 56

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if !store.dailyForecasts.isEmpty {
                forecastGrid
            }

            statusRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .task {
            await store.send(.refreshRequested).finish()
        }
    }

    private var forecastGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            Grid(horizontalSpacing: 12, verticalSpacing: 2) {
                GridRow {
                    ForEach(store.dailyForecasts) { forecast in
                        Text(monthDayText(from: forecast.dateText))
                            .font(.subheadline)
                            .frame(width: columnWidth)
                    }
                }

                GridRow {
                    ForEach(store.dailyForecasts) { forecast in
                        Text(conditionText(for: forecast))
                            .font(isAvailable(forecast) ? .title2 : .caption)
                            .frame(width: columnWidth)
                    }
                }

                GridRow {
                    ForEach(store.dailyForecasts) { forecast in
                        Text(maxTemperatureText(for: forecast))
                            .font(.subheadline)
                            .frame(width: columnWidth)
                    }
                }

                GridRow {
                    ForEach(store.dailyForecasts) { forecast in
                        Text(minTemperatureText(for: forecast))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: columnWidth)
                    }
                }

                GridRow {
                    ForEach(store.dailyForecasts) { forecast in
                        Text(precipitationText(for: forecast))
                            .font(.caption)
                            .frame(width: columnWidth)
                    }
                }
            }
            .fixedSize(horizontal: true, vertical: true)
            .padding(.trailing, 16)
        }
    }

    @ViewBuilder
    private var statusRow: some View {
        if store.isFetching {
            ProgressView()
                .frame(maxWidth: .infinity)
        } else if let errorMessage = store.errorMessage {
            Text(errorMessage)
                .font(.caption)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func isAvailable(_ forecast: DailyWeatherForecast) -> Bool {
        if case .available = forecast.availability { return true }
        return false
    }

    private func conditionText(for forecast: DailyWeatherForecast) -> String {
        switch forecast.availability {
        case let .available(condition, _, _, _):
            return condition.emoji
        case .notYet:
            return "—"
        case .pastDay:
            return "過去日"
        case .outsideForecastPeriod:
            return "期間外"
        }
    }

    private func maxTemperatureText(for forecast: DailyWeatherForecast) -> String {
        switch forecast.availability {
        case let .available(_, maxTemperature, _, _):
            return temperatureText(maxTemperature)
        case .pastDay, .outsideForecastPeriod, .notYet:
            return "—"
        }
    }

    private func minTemperatureText(for forecast: DailyWeatherForecast) -> String {
        switch forecast.availability {
        case let .available(_, _, minTemperature, _):
            return temperatureText(minTemperature)
        case .pastDay, .outsideForecastPeriod, .notYet:
            return "—"
        }
    }

    private func precipitationText(for forecast: DailyWeatherForecast) -> String {
        switch forecast.availability {
        case let .available(_, _, _, precipitationProbability):
            return "\(precipitationProbability)%"
        case .pastDay, .outsideForecastPeriod, .notYet:
            return "—"
        }
    }

    private func monthDayText(from dateString: String) -> String {
        let parts = dateString.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return dateString
        }
        return "\(month)/\(day)"
    }

    private func temperatureText(_ value: Double) -> String {
        "\(Int(value.rounded()))℃"
    }
}

#Preview {
    WeatherForecastView(
        store: Store(
            initialState: WeatherForecastFeature.State(
                forecastCondition: ForecastCondition(
                    latitude: 35.6812,
                    longitude: 139.7671,
                    fromDate: Date.makeDate(year: 2026, month: 8, day: 1),
                    numDays: 4
                )
            )
        ) {
            WeatherForecastFeature()
        } withDependencies: {
            $0.weatherForecast = .previewValue
        }
    )
}
