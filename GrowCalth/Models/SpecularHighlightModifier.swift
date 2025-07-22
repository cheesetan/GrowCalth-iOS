//
//  SpecularHighlightModifier.swift
//  GrowCalth
//
//  Created by Tristan Chay on 20/7/25.
//

import SwiftUI

struct AnyShape: Shape, @unchecked Sendable {
    private let pathFunction: @Sendable (CGRect) -> Path

    init<S: Shape>(_ wrapped: S) {
        self.pathFunction = { rect in
            wrapped.path(in: rect)
        }
    }

    func path(in rect: CGRect) -> Path {
        pathFunction(rect)
    }
}

enum SpecularHighlightShape: Equatable {
    case roundedRectangle(cornerRadius: CGFloat), capsule, circle

    func getShape() -> AnyShape {
        switch self {
        case .roundedRectangle(let cornerRadius): AnyShape(RoundedRectangle(cornerRadius: cornerRadius))
        case .capsule: AnyShape(Capsule())
        case .circle: AnyShape(Circle())
        }
    }
}

struct SpecularHighlightModifier: ViewModifier {
    let shape: SpecularHighlightShape
    let strokeWidth: CGFloat
    @Binding var isActive: Bool

    @ObservedObject var motionManager: MotionManager

    init(
        shape: SpecularHighlightShape,
        motionManager: MotionManager,
        strokeWidth: CGFloat = 2.0,
        isActive: Binding<Bool>
    ) {
        self.shape = shape
        self.motionManager = motionManager
        self.strokeWidth = strokeWidth
        self._isActive = isActive
    }

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geometry in
                    let size = geometry.size
                    let tiltAngle = atan2(motionManager.pitch, motionManager.roll)

                    if isActive {
                        ZStack {
                            shape.getShape()
                                .stroke(
                                    gradient1(tiltAngle: tiltAngle),
                                    lineWidth: strokeWidth
                                )

                            shape.getShape()
                                .stroke(
                                    gradient2(tiltAngle: tiltAngle),
                                    lineWidth: strokeWidth * 0.8
                                )
                        }
                        .frame(width: size.width, height: size.height)
                        .clipShape(shape.getShape())
                        .animation(.default, value: motionManager.roll)
                        .animation(.default, value: motionManager.pitch)
                    }
                }
            }
            .clipped()
    }

    func gradient1(tiltAngle: Double) -> AngularGradient {
        return AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.02),
                .init(color: .white.opacity(0.2), location: 0.08), // Top edge - very bright
                .init(color: .white.opacity(1.0), location: 0.17),
                .init(color: .white.opacity(0.2), location: 0.23),
                .init(color: .clear, location: 0.3),
                .init(color: .clear, location: 0.4),
                .init(color: .white.opacity(0.0), location: 0.42),
                .init(color: .white.opacity(0.3), location: 0.48), // Right edge - very bright
                .init(color: .white.opacity(1.0), location: 0.52),
                .init(color: .white.opacity(0.3), location: 0.58),
                .init(color: .clear, location: 0.65),
                .init(color: .clear, location: 1.0)
            ]),
            center: .center,
            startAngle: Angle(radians: tiltAngle - .pi/4),
            endAngle: Angle(radians: tiltAngle - .pi/4 + 2 * .pi)
        )
    }

    func gradient2(tiltAngle: Double) -> AngularGradient {
        return AngularGradient(
            gradient: Gradient(stops: [
                .init(color: .clear, location: 0.0),
                .init(color: .clear, location: 0.15),
                .init(color: .clear, location: 0.25),
                .init(color: .white.opacity(0.1), location: 0.27),
                .init(color: .white.opacity(0.5), location: 0.33), // Left edge
                .init(color: .white.opacity(0.5), location: 0.42),
                .init(color: .white.opacity(0.1), location: 0.48),
                .init(color: .clear, location: 0.55),
                .init(color: .clear, location: 0.65),
                .init(color: .white.opacity(0.1), location: 0.72),
                .init(color: .white.opacity(0.6), location: 0.78), // Bottom edge
                .init(color: .white.opacity(0.6), location: 0.92),
                .init(color: .white.opacity(0.1), location: 0.98)
            ]),
            center: .center,
            startAngle: Angle(radians: tiltAngle + .pi/4),
            endAngle: Angle(radians: tiltAngle + .pi/4 + 2 * .pi)
        )
    }
}
