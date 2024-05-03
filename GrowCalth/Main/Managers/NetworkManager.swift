//
//  NetworkManager.swift
//  GrowCalth
//
//  Created by Tristan Chay on 3/5/24.
//

import SwiftUI
import Network

class NetworkManager: ObservableObject {
    static let shared: NetworkManager = .init()
    
    @Published var isConnectionAvailable: Bool? = nil
    
    init() {
        beginNetworkMonitoring()
    }
    
    func beginNetworkMonitoring() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection is available.")
                DispatchQueue.main.async {
                    withAnimation {
                        self.isConnectionAvailable = true
                    }
                }
            } else {
                print("Internet connection is not available.")
                DispatchQueue.main.async {
                    withAnimation {
                        self.isConnectionAvailable = false
                    }
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
}
