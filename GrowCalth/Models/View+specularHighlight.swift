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
        highlightColor: Color = .white,
        strokeWidth: CGFloat = 6.0,
        glowRadius: CGFloat = 2.0,
        isActive: Binding<Bool> = .constant(true)
    ) -> some View {
        self.modifier(
            SpecularHighlightModifier(
                shape: shape,
                motionManager: motionManager,
                highlightColor: highlightColor,
                strokeWidth: strokeWidth,
                glowRadius: glowRadius,
                isActive: isActive
            )
        )
    }
}
