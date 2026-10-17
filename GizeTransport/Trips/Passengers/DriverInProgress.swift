//
//  DriverInProgress.swift
//  GizeTransport
//
//  Created by User on 10/12/23.
//

import SwiftUI

struct DriverInProgress: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    var body: some View {
        VStack {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48 , height: 6)
                .padding(.top, 8 )
            HStack {
                VStack(alignment: .leading,spacing: 12) {
                    Text("Driver in Progress")
                        .font(.largeTitle)
                    Text("your Driver will arrive within 10 minutes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(Color(.darkGreen))
//                    Button {
//                        homeViewModel.noTrip()
//                    } label: {
//                        Text("Cancel Trip")
//                            .font(.headline)
//                            .fontWeight(.bold)
//                            .padding()
//                            .frame(width: (UIScreen.main.bounds.width / 2) - 64 ,height: 56)
//                            .background(Color(.systemBlue))
//                            .cornerRadius(10)
//                            .foregroundColor(.white)
//                    }
                }
                .padding()
                
                Spacer()
                
                RideInProgressSpinner(lineWidth: 4, height: 44, width: 44)
                    .padding()
            }
            .padding(.bottom , 24)
        }
        .background(Color.theme.backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.theme.secondaryBackgroundColor, radius: 20)

    }
}
