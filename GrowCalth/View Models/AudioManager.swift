//
//  AudioManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 21/7/25.
//

import Foundation
import AVFoundation

@MainActor
class AudioManager: ObservableObject {
    private var audioPlayer: AVAudioPlayer?

    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }

    private var playbackPosition: TimeInterval = 0

    init() {
        configureAudioSession()
    }

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()

            // Set category to playback with mixWithOthers to not pause other audio
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])

            // Activate the audio session
            try audioSession.setActive(true)

        } catch {
            print("Failed to configure audio session: \(error.localizedDescription)")
        }
    }

    nonisolated func playSound(named name: String) {
        Task { @MainActor in
            await playAudio(named: name)
        }
    }

    private func playAudio(named name: String) async {
        // Ensure audio session is active before playing
        configureAudioSession()

        guard let url = Bundle.main.url(forResource: name, withExtension: "mp3") else {
            print("Sound file not found")
            return
        }

        do {
            if audioPlayer == nil || !isPlaying {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.currentTime = playbackPosition
                audioPlayer?.prepareToPlay()
                audioPlayer?.play()
            } else {
                print("Sound is already playing")
            }
        } catch {
            print("Error playing sound: \(error.localizedDescription)")
        }
    }

    nonisolated func stopSound() {
        Task { @MainActor in
            await stopAudio()
        }
    }

    private func stopAudio() async {
        if let player = audioPlayer {
            playbackPosition = player.currentTime
            player.stop()
        }
    }

    // Optional: Method to deactivate audio session when done
    nonisolated func deactivateAudioSession() {
        Task { @MainActor in
            await deactivateSession()
        }
    }

    private func deactivateSession() async {
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }
}
