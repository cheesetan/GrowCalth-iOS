//
//  NetworkManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 3/5/24.
//

import SwiftUI
import Network

@MainActor
final class NetworkManager: ObservableObject {

    @Published var isConnectionAvailable: Bool? = nil
    private var monitor: NWPathMonitor?

    init() {
        beginNetworkMonitoring()
    }

    deinit {
        monitor?.cancel()
    }

    func beginNetworkMonitoring() {
        let monitor = NWPathMonitor()
        self.monitor = monitor

        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self = self else { return }

                withAnimation {
                    self.isConnectionAvailable = path.status == .satisfied
                }

                if path.status == .satisfied {
                    print("Internet connection is available.")
                } else {
                    print("Internet connection is not available.")
                }
            }
        }

        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
