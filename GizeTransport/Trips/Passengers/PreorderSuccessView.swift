//
//  PreOrderAccpetedByDriverView.swift
//  GizeTransport
//
//  Created by User on 10/12/23.
//

import SwiftUI

struct PreorderSuccessView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        VStack {
            Text("Preorder Successful!")
                .font(.title)
                .fontWeight(.bold)
                .padding()

            Text("Your preorder has been accepted by a driver.")
                .multilineTextAlignment(.center)
                .padding()

            Button(action: {
                // Dismiss the view
                homeViewModel.trip?.state = .noTrip
            }) {
                Text("Dismiss")
                    .fontWeight(.bold)
                    .frame(width: 200, height: 50)
                    .background(Color.darkGreen)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(radius: 5)
    }
}

//struct PreorderSuccessView_Previews: PreviewProvider {
//    static var previews: some View {
//        PreorderSuccessView(homeViewModel: .constant(true))
//    }
//}

