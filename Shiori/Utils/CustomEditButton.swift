import SwiftUI

/// 編集中かどうかを表す指定したBool変数と連動する編集ボタン
struct CustomEditButton: View {
    @Binding var isEditing: Bool
    var editLabel: String = "編集"
    var doneLabel: String = "完了"
    
    var body: some View {
        Button(isEditing ? doneLabel : editLabel) {
            withAnimation { isEditing.toggle() }
        }
    }
}
