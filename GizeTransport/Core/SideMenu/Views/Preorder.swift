//
//  Preorder.swift
//  GizeTransport
//
//  Created by User on 10/7/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct PreOrder: View {
    @State private var trips: [Trip] = []
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        NavigationView {
            List(trips) { trip in
                PreOrderRowView(trip: trip)
            }
            .navigationTitle("Pre-Orders")
            .onAppear {
                loadUserTrips()
            }
        }
    }

    func loadUserTrips() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }

        Firestore.firestore().collection("preorder")
            .whereField("passengerUid", isEqualTo: uid)
            .getDocuments { querySnapshot, error in
                if let error = error {
                    print("Error fetching user trips: \(error.localizedDescription)")
                    return
                }

                guard let documents = querySnapshot?.documents else {
                    print("No documents found.")
                    return
                }

                let decodedTrips = documents.compactMap { document -> Trip? in
                    do {
                        let tripData = try document.data(as: Trip.self)
                        return tripData
                    } catch {
                        print("Error decoding trip data: \(error.localizedDescription)")
                        return nil
                    }
                }

                DispatchQueue.main.async {
                    self.trips = decodedTrips
                }
            }
    }
}

struct PreOrderRowView: View {
    var trip: Trip
    @EnvironmentObject var homeViewModel: HomeViewModel
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(Int(trip.tripCost)) ETB")
                    .font(.headline)
                Spacer()
                if let preOrderDate = trip.preOrderDate {
                    Text(preOrderDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                } else {
                    Text("\(Date())")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 5)

            MapViewpreoder(pickupCoordinate: trip.pickupLocationCoordiantes, dropoffCoordinate: trip.dropoffLocationCoordinates)
                .frame(height: 150)
                .cornerRadius(10)
                .padding(.bottom, 5)

            HStack {
                VStack(alignment: .leading) {
                    Text("A")
                        .font(.subheadline)
                        .bold()
                    Text(trip.pickupLocationName)
                        .font(.subheadline)
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("B")
                        .font(.subheadline)
                        .bold()
                    Text(trip.dropofflocationName)
                        .font(.subheadline)
                }
            }
            .padding(.bottom, 10)
            
    
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct MapViewpreoder: UIViewRepresentable {
    var pickupCoordinate: CLLocationCoordinate2D
    var dropoffCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        MKMapView(frame: .zero)
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        let pickupAnnotation = MKPointAnnotation()
        pickupAnnotation.coordinate = pickupCoordinate
        pickupAnnotation.title = "A"

        let dropoffAnnotation = MKPointAnnotation()
        dropoffAnnotation.coordinate = dropoffCoordinate
        dropoffAnnotation.title = "B"

        view.addAnnotations([pickupAnnotation, dropoffAnnotation])

        let region = MKCoordinateRegion(
            center: pickupCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        view.setRegion(view.regionThatFits(region), animated: true)
    }
}

struct PreOrder_Previews: PreviewProvider {
    static var previews: some View {
        PreOrder()
            .environmentObject(HomeViewModel()) // Make sure HomeViewModel is provided
    }
}
