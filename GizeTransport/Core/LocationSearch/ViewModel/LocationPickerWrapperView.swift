//
//  LocationPickerWrapperView.swift
//  GizeTransport
//
//  Created by User on 11/14/24.
//

import SwiftUI
import CoreLocation

struct LocationPickerWrapperView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var viewModel: HomeViewModel
    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedAddress: String?

    var body: some View {
        ZStack {
            // Map view
            LocationPickerView(
                selectedCoordinate: $selectedCoordinate,
                selectedAddress: $selectedAddress,
                initialCoordinate: viewModel.userLocation ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
            )
            .edgesIgnoringSafeArea(.all)

            // Crosshair icon in the center
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .frame(width: 32, height: 32)
                .foregroundColor(.red)

            VStack {
                HStack {
                    // Cancel button at the top-left corner
                    Button(action: {
                        isPresented = false
                    }) {
                        Image(systemName: "chevron.backward")
                            .imageScale(.large)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .buttonStyle(PlainButtonStyle())
                .padding([.top, .leading], 16)

                Spacer()

                // Display the selected address
                if let address = selectedAddress {
                    Text(address)
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.9))
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                }

                // Confirm button at the bottom
                Button(action: {
                    if let coordinate = selectedCoordinate, let address = selectedAddress {
                        viewModel.destinationQuery = address
                        viewModel.selectedUberLocation = UberLocation(title: address, coordinate: coordinate)
                        viewModel.destination = coordinate
                    }
                    isPresented = false
                }) {
                    Text("Confirm Location")
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(8)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 32)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
}
