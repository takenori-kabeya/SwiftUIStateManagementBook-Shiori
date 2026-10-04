//
//  NavigationRowButtonStyle.swift
//  ShioriApp
//
//  Created by Takenori Kabeya on 2026/08/20.
//
import SwiftUI

struct NavigationRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            Image(systemName: "chevron.forward")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
        .foregroundStyle(.primary)
        .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == NavigationRowButtonStyle {
    static var navigationRow: NavigationRowButtonStyle {
        NavigationRowButtonStyle()
    }
}
