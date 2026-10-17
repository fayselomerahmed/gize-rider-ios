//
//  TripLoadingView.swift
//  GizeTransport
//
//  Created by User on 7/15/23.
//

import SwiftUI

struct TripLoadingView: View {
    var body: some View {
        VStack {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48 , height: 6)
                .padding(.top, 8 )
            HStack {
                VStack(alignment: .leading,spacing: 12) {
                    Text("Connecting you to a driver")
                        .font(.headline)
                    Text("Arriving at 1:30 PM")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.darkGreen))
                }
                .padding()
                
                Spacer()
                
                Spinner(lineWidth: 6, height: 64, width: 64)
                    .padding()
            }
            .padding(.bottom , 24)
        }
        .background(Color.theme.backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.theme.secondaryBackgroundColor, radius: 20)
        }
}

struct TripLoadingView_Previews: PreviewProvider {
    static var previews: some View {
        TripLoadingView()
    }
}
