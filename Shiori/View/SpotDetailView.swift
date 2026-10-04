//
//  SpotDetailView.swift
//  ShioriApp
//

import SwiftUI
import ComposableArchitecture

struct SpotDetailView: View {
    @Bindable var store: StoreOf<SpotDetailFeature>

    var body: some View {
        Form {
            LabeledContent("行き先名", value: store.spot.title)
            LabeledContent("予定到着時刻", value: startTimeText)
            LabeledContent("予定滞在時間", value: durationMinutesText)

            Section("メモ") {
                Text(memoText)
            }
        }
        .navigationTitle("行き先詳細")
    }

    private var startTimeText: String {
        store.spot.startTime?.formattedTime ?? "未設定"
    }

    private var durationMinutesText: String {
        guard let durationMinutes = store.spot.durationMinutes else {
            return "未設定"
        }
        return "\(durationMinutes) 分"
    }

    private var memoText: String {
        store.spot.memo.isEmpty ? "なし" : store.spot.memo
    }
}

#Preview {
    @Previewable @State var trip = Trip.previewTrip

    NavigationStack {
        
        SpotDetailView(
            store: Store(
                initialState: SpotDetailFeature.State(
                    spot: Shared(value: trip.itinerary.itineraryDays.first!.spots.first!)
                )
            ) {
                SpotDetailFeature()
            }
        )
    }
}
