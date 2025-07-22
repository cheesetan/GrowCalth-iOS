//
//  MotionManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 20/7/25.
//

import SwiftUI
import CoreMotion

@MainActor
final class MotionManager: ObservableObject {
    let motionManager = CMMotionManager()
    private var lastUpdateTime: TimeInterval = 0
    private let updateThreshold: TimeInterval = 0.033 // ~30 FPS limit
    private var isTrackingMotion = true
    private var onFirstLoad = true

    @ObservedObject private var settingsManager: SettingsManager

    private var isActive: Bool {
        if settingsManager.specularHighlightsEnabled {
            return isTrackingMotion
        } else {
            self.roll = -0.007943875685558606
            self.pitch = 0.0186287793618111
            return false
        }
    }

    @Published var roll: Double = 0.0
    @Published var pitch: Double = 0.0

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        startMotionUpdates()
    }

    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            settingsManager.specularHighlightsEnabled = false
            return
        }

        if !onFirstLoad {
            guard isActive else { return }
        } else {
            onFirstLoad = false
        }

        // Optimal update interval - 30Hz for good responsiveness with lower CPU usage
        motionManager.deviceMotionUpdateInterval = 0.033

        motionManager.startDeviceMotionUpdates(to: .current!) { [weak self] motion, _ in
            guard let motion = motion else { return }

            // Do heavy calculations on background queue
            let currentTime = CACurrentMediaTime()
            let newRoll = motion.attitude.roll / (.pi / 2)
            let newPitch = motion.attitude.pitch / (.pi / 2)

            // Batch update to main thread only when necessary
            DispatchQueue.main.async { [weak self] in
                guard let self = self, self.isActive else { return }

                // Throttle updates
                guard currentTime - self.lastUpdateTime >= self.updateThreshold else { return }

                // Only update if there's meaningful change
                let rollDiff = abs(newRoll - self.roll)
                let pitchDiff = abs(newPitch - self.pitch)

                if rollDiff > 0.01 || pitchDiff > 0.01 { // More sensitive threshold
                    self.roll = motion.attitude.roll / (.pi / 2)
                    self.pitch = motion.attitude.pitch / (.pi / 2)
                    self.lastUpdateTime = currentTime
                }
            }
        }
    }

    deinit {
        // Set isActive to false to prevent any pending callbacks from executing
        isTrackingMotion = false
        // CMMotionManager will clean up automatically when deallocated
    }
}
