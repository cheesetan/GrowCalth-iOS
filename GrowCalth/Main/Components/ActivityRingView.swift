//
//  ActivityRingView.swift
//  GrowCalth
//
//  Created by Tristan Chay on 8/2/24.
//

import SwiftUI

struct ActivityRingView: View {
    var progress: Double
    var ringRadius: Double = 60.0
    var thickness: CGFloat = 20.0
    var startColor = Color(red: 0.784, green: 0.659, blue: 0.941)
    var endColor = Color(red: 0.278, green: 0.129, blue: 0.620)
    
    private var ringTipShadowOffset: CGPoint {
        let ringTipPosition = tipPosition(progress: progress, radius: ringRadius)
        let shadowPosition = tipPosition(progress: progress + 0.0075, radius: ringRadius)
        return CGPoint(x: shadowPosition.x - ringTipPosition.x,
                       y: shadowPosition.y - ringTipPosition.y)
    }
    
    private func tipPosition(progress:Double, radius:Double) -> CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: radius * cos(progressAngle.radians),
            y: radius * sin(progressAngle.radians))
    }
    
    var body: some View {
        let activityAngularGradient = AngularGradient(
            gradient: Gradient(colors: [startColor, endColor]),
            center: .center,
            startAngle: .degrees(0),
            endAngle: .degrees(360.0 * progress))
        
        ZStack {
            Circle()
                .stroke(startColor.opacity(0.15), lineWidth: thickness)
                .frame(width:CGFloat(ringRadius) * 2.0)
            Circle()
                .stroke(Color(.systemGray2), lineWidth: 1.0)
                .frame(width:(CGFloat(ringRadius) * 2.0) + thickness)
            Circle()
                .stroke(Color(.systemGray2), lineWidth: 1.0)
                .frame(width:(CGFloat(ringRadius) * 2.0) - thickness)
            Circle()
                .trim(from: 0, to: CGFloat(self.progress))
                .stroke(
                    activityAngularGradient,
                    style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .rotationEffect(Angle(degrees: -90))
                .frame(width:CGFloat(ringRadius) * 2.0)
            ActivityRingTip(progress: progress,
                            ringRadius: Double(ringRadius))
                .fill(progress>0.95 ? endColor : .clear)
                .frame(width:thickness, height:thickness)
                .shadow(color: progress>0.95 ? .black.opacity(0.3) : .clear,
                        radius: 2.5,
                        x: ringTipShadowOffset.x,
                        y: ringTipShadowOffset.y)
        }
    }
}


struct ActivityRingTip: Shape {
    var progress: Double
    var ringRadius: Double
    
    private var position: CGPoint {
        let progressAngle = Angle(degrees: (360.0 * progress) - 90.0)
        return CGPoint(
            x: ringRadius * cos(progressAngle.radians),
            y: ringRadius * sin(progressAngle.radians))
    }
    
    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        if progress > 0.0 {
            path.addEllipse(in: CGRect(
                                x: position.x,
                                y: position.y,
                                width: rect.size.width,
                                height: rect.size.height))
        }
        return path
    }
}
