import SwiftUI
import ComposableArchitecture

struct SpotEditorView: View {
    @Bindable var store: StoreOf<SpotFeature>
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("行き先名", text: $store.draft.title.sending(\.titleChanged))
                Toggle("予定到着時刻を指定する", isOn: $store.draft.hasStartTime.sending(\.hasStartTimeChanged))
                DatePicker("予定到着時刻", selection: $store.draft.startTime.sending(\.startTimeChanged), displayedComponents: .hourAndMinute)
                    .disabled(!store.draft.hasStartTime)
                Toggle("予定滞在時間を指定する", isOn: $store.draft.hasDurationMinutes.sending(\.hasDurationMinutesChanged))
                Stepper("予定滞在時間: \(store.draft.durationMinutes) (分)", value: $store.draft.durationMinutes.sending(\.durationMinutesChanged), in: 5...480, step: 5)
                    .disabled(!store.draft.hasDurationMinutes)
                ZStack(alignment: .topLeading) {
                    if store.draft.memo.isEmpty {
                        Text("メモ")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $store.draft.memo.sending(\.memoChanged))
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }

            }
            .navigationTitle("行き先を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        store.send(.cancelButtonTapped)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        store.send(.saveButtonTapped)
                    }
                }
            }
        }
    }
}
