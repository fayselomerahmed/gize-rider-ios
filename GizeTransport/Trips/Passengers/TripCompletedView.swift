//
//  TripCompletedView.swift
//  GizeTransport
//
//  Created by User on 6/12/24.
//

import SwiftUI
import FirebaseFirestore

struct TripCompletedView: View {

    @Binding var isPresented: Bool
    @State private var showTripDetails: Bool = false
    @State private var rating: Int = 0
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 16) {
            // Header Section
            Spacer()

            VStack(spacing: 12) {
                // Total Trip Cost Section
                Text("TOTAL")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("ETB \(homeViewModel.trip?.tripCost ?? 0, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Drop Down Button for Trip Info
                Button(action: {
                    withAnimation {
                        showTripDetails.toggle()
                    }
                }) {
                    HStack {
                        Text("Trip Details")
                        Image(systemName: showTripDetails ? "chevron.up" : "chevron.down")
                    }
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(5)
                    .shadow(radius: 2)
                }

                if showTripDetails {
                    VStack {
                        detailView(title: "Start Location:", value: homeViewModel.trip?.pickupLocationAddress ?? "")
                        detailView(title: "End Location:", value: homeViewModel.trip?.dropofflocationName ?? "")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .shadow(radius: 5)
                }

                // Driver Info Section
                VStack(spacing: 8) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    Text(homeViewModel.trip?.driverName ?? "")
                        .font(.headline)
                    
                    // Rating Section
                    RatingView(rating: $rating)
                        .padding()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .shadow(radius: 5)

                // Rate Button
                Button("OK") {
                    uploadRating()
                    homeViewModel.reset()
                    homeViewModel.noTrip()
                
                }
                .font(.title3)
                .foregroundColor(.white)
                .padding()
                .frame(width: UIScreen.main.bounds.width * 0.8, height: 50)
                .background(Color.green)
                .cornerRadius(25)
                .shadow(radius: 10)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 5)

            Spacer()
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    func detailView(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color.primary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    // Function to upload rating to Firestore
    func uploadRating() {
        let driverUID = homeViewModel.trip?.driverUid ?? ""
        
        let db = Firestore.firestore()
        let driverRef = db.collection("users").document(driverUID)
        
        driverRef.updateData(["rating": rating]) { error in
            if let error = error {
                print("Error updating rating: \(error.localizedDescription)")
            } else {
                print("Rating successfully updated")
            }
        }
    }
}

struct RatingView: View {
    @Binding var rating: Int

    var body: some View {
        HStack {
            ForEach(1..<6) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .foregroundColor(index <= rating ? .yellow : .gray)
                    .onTapGesture {
                        rating = index
                    }
            }
        }
    }
}



