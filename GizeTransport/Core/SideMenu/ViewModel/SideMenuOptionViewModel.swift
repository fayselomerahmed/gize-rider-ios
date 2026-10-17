//
//  SideMenuOptionViewModel.swift
//  GizeTransport
//
//  Created by User on 4/2/23.
//

import Foundation

enum SideMenuOptionViewModel: Int , CaseIterable , Identifiable {
    case history
    case notification
    case preorder
    
    var title: String {
        switch self {
        case .history: return "Trip history"
        case .notification: return "Notifications"
        case .preorder: return "Pre-orders"
        }
    }

    var subtitle: String {
        switch self {
        case .history: return "Receipts, routes, and past rides"
        case .notification: return "Ride alerts and service updates"
        case .preorder: return "Schedule airport rides ahead"
        }
    }

    var imageName: String {
        switch self {
        case .history: return "list.bullet.rectangle"
        case .notification: return "bell"
        case .preorder: return "calendar"
        }
    }
    var id: Int {
        return self.rawValue
    }
}
