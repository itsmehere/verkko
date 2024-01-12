//
//  NetworkManager.swift
//  Verkko
//
//  Created by Justin Wong on 6/13/23.
//

import Foundation
import Network

class NetworkManager {
    private let monitor = NWPathMonitor()
    var currentStatus: NetworkConnectionStatus = .noconnection
    
    enum NetworkConnectionStatus {
        case connected
        case noconnection
    }
    
    init() {
        monitor.pathUpdateHandler = { path in
            if path.status == .satisfied {
                print("Internet connection is available")
                self.currentStatus = .connected
            } else {
                print("No internet connection")
                self.currentStatus = .noconnection
            }
        }
        
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    func getConnectionStatus() -> NetworkConnectionStatus {
        return currentStatus
    }
}
