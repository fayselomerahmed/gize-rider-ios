//
//  PickupPassengerView.swift
//  GizeTransport
//
//  Created by User on 7/22/23.
//

import SwiftUI

struct PickupPassengerView: View {
    let trip: Trip
    @EnvironmentObject var viewModel : HomeViewModel
    var body: some View {
        VStack{
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48 , height: 6)
                .padding(.top, 8 )
            
            VStack {
                HStack {
                    Text ("Pickup \(trip.passengerName) at \(trip.dropofflocationName)")
                        .font(.headline)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .frame(height: 44)
                    
                    Spacer()
                
                    VStack {
                        Text("\(trip.travelTimeToPassenger)")
                            .bold()
                        
                        Text ("min")
                            .bold()
                    }
                    .frame(width: 56 , height: 56)
                    .foregroundColor(.white)
                    .background(Color(.darkGreen))
                    .cornerRadius(10)
                    
                }
                .padding()
                Divider()
            }
            
            VStack {
                HStack {
                    Image("logo")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 80 , height: 80)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text(trip.passengerName)
                            .fontWeight(.bold)
                        
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(Color(.systemYellow))
                                .imageScale(.small)
                            Text ("4.8")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 6) {
                        Text ("Earnings")
                        
                        Text ("\(trip.tripCost.toCurrency())")
                            .font(.system(size: 24 , weight: .semibold))
                    }
                }
                
                Divider()
                
                
            }
            .padding()
            
            Button {
               print("DEBUG: Cancel trip")
                viewModel.cancelTripAsDriver()
            } label: {
                Text("CANCEL TRIP")
                    .fontWeight(.bold)
                    .frame(width: UIScreen.main.bounds.width - 32 ,height: 50 )
                    .background(.red)
                    .cornerRadius(10)
                    .foregroundColor(.white)
               
            }
        }
        .padding(.bottom , 24)
        .background(Color.theme.backgroundColor)
            .cornerRadius(16)
            .shadow(color: Color.theme.secondaryBackgroundColor, radius: 20)
    }
}


