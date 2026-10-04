import SwiftUI

struct SpotEditorView: View {
    @Binding var editingDraft: SpotDraft
    
    let onCancel: () -> Void
    let onSave: () -> Void
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("行き先名", text: $editingDraft.title)
                Toggle("予定到着時刻を指定する", isOn: $editingDraft.hasStartTime)
                DatePicker("予定到着時刻", selection: $editingDraft.startTime, displayedComponents: .hourAndMinute)
                    .disabled(!editingDraft.hasStartTime)
                Toggle("予定滞在時間を指定する", isOn: $editingDraft.hasDurationMinutes)
                Stepper("予定滞在時間: \(editingDraft.durationMinutes) (分)", value: $editingDraft.durationMinutes, in: 5...480, step: 5)
                    .disabled(!editingDraft.hasDurationMinutes)
                ZStack(alignment: .topLeading) {
                    if editingDraft.memo.isEmpty {
                        Text("メモ")
                            .foregroundStyle(.tertiary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }
                    TextEditor(text: $editingDraft.memo)
                        .frame(minHeight: 100)
                        .scrollContentBackground(.hidden)
                }

            }
            .navigationTitle("行き先を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        //editingSpot = nil
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        //saveEditingSpot()
                        onSave()
                    }
                }
            }
        }
    }
}
