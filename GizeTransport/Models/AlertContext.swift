//
//  AlertContext.swift
//  GizeTransport
//
//  Created by User on 11/17/24.
//

import SwiftUI

struct AlertContext {
    // MARK: - Network Alerts
    static let invalidResponse = AlertItem(
        title: Text("Server Error"),
        message: Text("Invalid response from the server. Please try again later."),
        dismissButton: .default(Text("OK"))
    )
    
    static let invalidData = AlertItem(
        title: Text("Data Error"),
        message: Text("The data received from the server was invalid. Please contact support."),
        dismissButton: .default(Text("OK"))
    )
    
    // Add more predefined alerts as needed
}
