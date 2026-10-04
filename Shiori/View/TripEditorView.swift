import SwiftUI
import ComposableArchitecture

struct TripEditorView: View {
    @Bindable var store: StoreOf<TripEditFeature>
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("旅行名", text: $store.draft.info.title.sending(\.titleChanged))
                DatePicker("開始日", selection: $store.draft.info.startDate.sending(\.startDateChanged), displayedComponents: .date)
                let maxDayCount = max(10, store.draft.currentNumDays)
                Stepper(value: $store.draft.newNumDays.sending(\.numDaysChanged), in: 1...maxDayCount) {
                    Text("\(store.draft.newNumDays)日")
                }
            }
            .navigationTitle("旅行を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", role: .cancel) {
                        store.send(.cancelButtonTapped)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.send(.saveButtonTapped)
                    }
                }
            }
            .confirmationDialog(
                dayCountReductionMessage,
                isPresented: Binding(
                    get: { store.dayCountReductionPending != nil },
                    set: { isPresented in
                        if !isPresented {
                            store.send(.dayCountReductionDismissed)
                        }
                    }
                ),
                titleVisibility: .visible,
            ) {
                Button("日数を減らす", role: .destructive) {
                    store.send(.dayCountReductionConfirmed)
                }
                Button("キャンセル") {
                    store.send(.dayCountReductionDismissed)
                }
            }
        }
    }
    private var dayCountReductionMessage: String {
        guard let titles = store.state.dayCountReductionPending?.spotTitlesToMove else {
            return ""
        }
        if titles.isEmpty {
            return "日数を減らしますか？"
        }
        
        let titleText = titles.joined(separator: "、")
        return "次の行き先は最終日に移動します: \(titleText)"
    }

}
