//
//  AcceptTripView.swift
//  GizeTransport
//
//  Created by User on 6/1/23.
//

import SwiftUI
import MapKit

struct AcceptTripView: View {
    @State private var region: MKCoordinateRegion
    
    let trip: Trip
    
    let annotaitonItem: UberLocation
    @EnvironmentObject var viewModel: HomeViewModel
    
    init(trip: Trip) {
        let center = CLLocationCoordinate2D(latitude: trip.pickupLocation.latitude, longitude: trip.pickupLocation.longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.025, longitudeDelta: 0.025)
        self._region = State(initialValue: MKCoordinateRegion(center: center, span: span))
        self.trip = trip
        self.annotaitonItem = UberLocation(title: trip.pickupLocationName, coordinate: trip.pickupLocation.toCoordinate())
    }
    var body: some View {
        VStack {
            Capsule()
                .foregroundColor(Color(.systemGray5))
                .frame(width: 48 , height: 6)
                .padding(.top, 8 )
            
            VStack {
                HStack {
                    Text ("Would you like to pickup this passenger?")
                        .font(.headline)
                        .fontWeight(.semibold)
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
            
            // user info view
            
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
                        
                        Text (trip.tripCost.toCurrency())
                            .font(.system(size: 24 , weight: .semibold))
                    }
                }
                
                Divider()
                
                
            }
            .padding()
            // pickup location info view
            
            VStack {
                
                //trip location info
                HStack {
                    // address info
                    VStack(alignment: .leading,spacing: 6) {
                        Text (trip.pickupLocationName)
                            .font(.headline)
                        
                        
                        Text (trip.pickupLocationAddress)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                        
                    }
                    
                    Spacer()
                    // distance
                    VStack {
                        Text(trip.distanceToPassenger.distanceInMilesString() )
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("miles")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.horizontal)
                // map
                Map(coordinateRegion: $region , annotationItems:[annotaitonItem]){item in
                    MapMarker(coordinate: item.coordinate)
                }
                .frame(height: 220)
                .cornerRadius(10)
                .shadow(color: . black.opacity(0.6) , radius: 10)
                .padding()
                // divider
                Divider()
            }
            // action buttons
            HStack {
                Button {
                    viewModel.rejectTrip()
                } label: {
                    Text("Reject")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .frame(width: (UIScreen.main.bounds.width / 2) - 32 ,height: 56)
                        .background(Color(.systemRed))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                Spacer()
                Button {
                    viewModel.acceptTrip()
                } label: {
                    Text("Accept")
                        .font(.headline)
                        .fontWeight(.bold)
                        .padding()
                        .frame(width: (UIScreen.main.bounds.width / 2) - 32 ,height: 56)
                        .background(Color(.darkGreen))
                        .cornerRadius(10)
                        .foregroundColor(.white)
                }
                
            }
            .padding(.top)
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color.theme.backgroundColor)
        .cornerRadius(16)
        .shadow(color: Color.theme.secondaryBackgroundColor, radius: 20)
    }
}


