//
//  AlertItem.swift
//  GizeTransport
//
//  Created by User on 11/17/24.
//

import Foundation
import SwiftUI

// AlertItem.swift

struct AlertItem: Identifiable {
    let id = UUID()
    let title: Text
    let message: Text
    let primaryButton: Alert.Button?
    let secondaryButton: Alert.Button?

    // Initializer for single-button alerts
    init(title: Text, message: Text, dismissButton: Alert.Button?) {
        self.title = title
        self.message = message
        self.primaryButton = dismissButton
        self.secondaryButton = nil
    }

    // Initializer for two-button alerts
    init(title: Text, message: Text, primaryButton: Alert.Button?, secondaryButton: Alert.Button?) {
        self.title = title
        self.message = message
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
    }
}
// AlertContext.swift


