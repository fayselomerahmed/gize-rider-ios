//
//  Wallet.swift
//  GizeTransport
//
//  Created by User on 10/6/23.
//
import SwiftUI

struct Notification: View {
    var notificationTitle: String
    var notificationBody: String

    var body: some View {
        NavigationView {
            List {
                NotificationCard(
                    icon: "bell.fill",
                    title: notificationTitle,
                    bodyCon: notificationBody,
                    backgroundColor: Color.teal.opacity(0.1)
                )
                
                NotificationCard(
                    icon: "star.fill",
                    title: "Bonus Points",
                    bodyCon: "You have used your bonus points for a car wash",
                    backgroundColor: Color.teal.opacity(0.1)
                )
            }
            .navigationTitle("Notifications")
            .listStyle(PlainListStyle())
        }
    }
}


struct Notification_Previews: PreviewProvider {
    static var previews: some View {
        Notification(
            notificationTitle: "New Ride Request",
            notificationBody: "You have a new ride request. Check it out!"
        )
        .previewLayout(.sizeThatFits)
        .padding()
    }
}








