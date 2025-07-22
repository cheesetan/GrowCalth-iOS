//
//  View+specularHighlight.swift
//  GrowCalth
//
//  Created by Tristan Chay on 20/7/25.
//

import SwiftUI

extension View {
    func specularHighlight(
        for shape: SpecularHighlightShape = .capsule,
        motionManager: MotionManager,
        lineWidth: CGFloat = 2.0,
        isActive: Binding<Bool> = .constant(true)
    ) -> some View {
        self.modifier(
            SpecularHighlightModifier(
                shape: shape,
                motionManager: motionManager,
                strokeWidth: lineWidth,
                isActive: isActive
            )
        )
    }
}
