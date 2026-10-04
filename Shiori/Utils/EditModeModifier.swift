import SwiftUI

struct EditModeModifier: ViewModifier {
    var editing: Bool
    var localEditMode: Binding<EditMode> {
        Binding {
            return editing ? .active : .inactive
        } set: { _ in
        }
    }
    
    func body(content: Content) -> some View {
        content
            .environment(\.editMode, localEditMode)
    }
}

extension View {
    func isEditing(_ editing: Bool) -> some View {
        self.modifier(EditModeModifier(editing: editing))
    }
}
