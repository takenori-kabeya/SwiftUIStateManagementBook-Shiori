import SwiftUI
import ComposableArchitecture

struct PlaceSearchView: View {
    @Bindable var store: StoreOf<PlaceSearchFeature>
    
    var body: some View {
        Form {
            Section("地名検索") {
                TextField(
                    "地名を入力",
                    text: $store.query.sending(\.queryChanged)
                )
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onSubmit {
                    store.send(.searchButtonTapped)
                }

                Button {
                    store.send(.searchButtonTapped)
                } label: {
                    if store.isSearching {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("検索")
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(store.isSearching)
            }

            if let errorMessage = store.errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }

            if !store.candidates.isEmpty {
                Section("候補") {
                    ForEach(store.candidates) { candidate in
                        Button {
                            store.send(.candidateSelected(candidate.id))
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(candidate.place.name)
                                    if !candidate.place.address.isEmpty {
                                        Text(candidate.place.address)
                                            .font(.caption)
                                    }
                                }
                                Spacer()
                                if store.selectedPlace == candidate.place {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.tint)
                                }
                            }
                        }
                    }
                }
            }

            if let selectedPlace = store.selectedPlace {
                Section("選択した場所") {
                    LabeledContent("地名", value: selectedPlace.name)
                    LabeledContent("住所", value: selectedPlace.address)
                    LabeledContent("緯度", value: formatCoordinate(selectedPlace.latitude))
                    LabeledContent("経度", value: formatCoordinate(selectedPlace.longitude))
                }
            }
        }
        .navigationTitle("場所を探す")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("キャンセル") {
                    store.send(.cancelButtonTapped)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("確定") {
                    guard store.selectedPlace != nil else { return }
                    store.send(.confirmButtonTapped)
                }
                .disabled(store.selectedPlace == nil)
            }
        }
    }

    private func formatCoordinate(_ value: Double) -> String {
        String(format: "%.6f", value)
    }
}

#Preview {
    NavigationStack {
        PlaceSearchView(
            store: Store(initialState: PlaceSearchFeature.State()) {
                PlaceSearchFeature()
            }
        )
    }
}
