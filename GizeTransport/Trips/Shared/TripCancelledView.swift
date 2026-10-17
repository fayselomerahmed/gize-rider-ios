//
//  TripCancelledView.swift
//  GizeTransport
//
//  Created by User on 7/22/23.
//
import SwiftUI

struct TripCancelledView: View {
    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        VStack {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48, height: 6)
                .padding(.top, 8)
            
            Text(viewModel.tripCancelledMessage)
                .font(.headline)
                .padding(.vertical)
            
            List(viewModel.reasonsForCancellation, id: \.self) { reason in
                HStack {
                    Text(reason)
                    Spacer()
                    Image(systemName: viewModel.selectedReasons.contains(reason) ? "circle.fill" : "circle")
                        .foregroundColor(viewModel.selectedReasons.contains(reason) ? .darkGreen : .gray)
                }
                .onTapGesture {
                    if viewModel.selectedReasons.contains(reason) {
                        viewModel.selectedReasons.remove(reason)
                    } else {
                        viewModel.selectedReasons.insert(reason)
                    }
                }
            }
            .frame(height: 200) // Adjust height based on UI needs
            
            Button {
                handleCancellation()
                viewModel.noTrip()
            } label: {
                Text("OK")
                    .fontWeight(.bold)
                    .frame(width: UIScreen.main.bounds.width - 32, height: 50)
                    .background(Color.darkGreen)
                    .cornerRadius(10)
                    .foregroundColor(Color.white)
            }
        }
        .padding(.bottom, 24)
        .frame(maxWidth: .infinity)
        .background(Color.white) // Assuming Color.theme.backgroundColor is white
        .cornerRadius(16)
        .shadow(color: Color.gray, radius: 20) // Assuming Color.theme.secondaryBackgroundColor is gray
    }
    
    private func handleCancellation() {
        guard let user = viewModel.currentUser, let trip = viewModel.trip else { return }

        // Handling based on user role and trip state
        if user.accountType == .passenger {
            if trip.state == .driverCancelled {
                viewModel.deleteTrip()
            } else if trip.state == .passengerCancelled {
                viewModel.trip = nil
                viewModel.deleteTrip()
            }
        } else {
            if trip.state == .passengerCancelled {
                viewModel.deleteTrip()
            } else if trip.state == .driverCancelled {
                viewModel.trip = nil
                viewModel.deleteTrip()
            }
        }
        AppLogger.info("Trip cancellation submitted.")
    }
}

struct TripCancelledView_Previews: PreviewProvider {
    static var previews: some View {
        TripCancelledView().environmentObject(HomeViewModel())
    }
}
