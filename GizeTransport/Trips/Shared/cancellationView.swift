//
//  cancellationView.swift
//  GizeTransport
//
//  Created by User on 4/24/24.
//

import SwiftUI

struct CancellationView: View {
    @State private var showAlert = false
    @State private var cancellationReason = "No reason provided"

    var body: some View {
        VStack {
            Button("Cancel Trip") {
                // This button simulates a trip cancellation
                cancellationReason = "Driver unavailable"
                showAlert = true
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Trip Cancelled"),
                message: Text(cancellationReason),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct CancellationView_Previews: PreviewProvider {
    static var previews: some View {
        CancellationView()
    }
}
