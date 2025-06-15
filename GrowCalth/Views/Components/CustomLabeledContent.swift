//
//  CustomLabeledContent.swift
//  GrowCalth
//
//  Created by Tristan Chay on 15/4/25.
//

import SwiftUI

struct CustomLabeledContent<Content: View, Label: View>: View {
    @ViewBuilder let label: Label
    @ViewBuilder let content: Content

    init(_ titleKey: String, @ViewBuilder content: () -> Content) where Label == Text {
        self.label = Text(titleKey)
        self.content = content()
    }

    init(_ titleKey: LocalizedStringKey, @ViewBuilder content: () -> Content) where Label == Text {
        self.label = Text(titleKey)
        self.content = content()
    }

    init(@ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label) {
        self.label = label()
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            LabeledContent {
                content
            } label: {
                label
            }
        } else {
            HStack {
                label
                Spacer()
                content
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}
