//
//  NotificationCard.swift
//  GizeTransport
//
//  Created by User on 6/8/24.
//

import SwiftUI
struct NotificationCard: View {
    var icon: String
    var title: String
    var bodyCon: String
    var backgroundColor: Color
    
    var bodyContent: some View { // Changed to avoid redeclaration error
        HStack {
            Image(systemName: icon)
                .foregroundColor(.darkGreen)
                .font(.title2)
                .padding(.trailing, 10)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(bodyCon)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    var body: some View {
        bodyContent // Use bodyContent to avoid redeclaration error
    }
}
