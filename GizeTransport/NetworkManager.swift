//
//  NetworkManager.swift
//  GizeTransport
//
//  Created by User on 5/18/24.
//
import Network
import Combine
import SwiftUI

class NetworkViewModel: ObservableObject {
    func startNetworkConnection() {
        // Network reachability is handled by NetworkManager.shared.
    }

    func stopNetworkConnection() {
        // Kept for existing HomeView lifecycle calls.
    }
}

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkManagerQueue")

    @Published var isConnected: Bool = true

     init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
}
//struct NetworkStatusView: View {
//    @EnvironmentObject var networkManager: NetworkManager
//
//    var body: some View {
//        if !networkManager.isConnected {
//            HStack {
//                Image(systemName: "exclamationmark.triangle.fill")
//                    .foregroundColor(.red)
//                Text("No Internet Connection")
//                    .foregroundColor(.red)
//                    .font(.caption)
//            }
//            .padding()
//            .background(Color.yellow.opacity(0.3))
//            .cornerRadius(8)
//            .padding([.leading, .trailing, .top])
//        }
//    }
//}
