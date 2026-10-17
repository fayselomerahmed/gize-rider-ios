//
//  History.swift
//  GizeTransport
//
//  Created by User on 10/6/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseAuth
import MapKit

struct TripHistoryView: View {
    @State private var trips: [Trip] = []
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        NavigationView {
            List(trips) { trip in
                TripRowView(trip: trip)
            }
            .navigationTitle("Completed")
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

        Firestore.firestore().collection("trips")
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

struct TripRowView: View {
    var trip: Trip

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(Int(trip.tripCost)) ETB")
                    .font(.headline)
                Spacer()
                Text(trip.preOrderDate ?? Date(), style: .date)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .padding(.bottom, 5)
            
            StaticMapView(pickupCoordinate: trip.pickupLocationCoordiantes, dropoffCoordinate: trip.dropoffLocationCoordinates)
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
        }
        .padding()
//        .background(Color(UIColor.systemGray6))
        .cornerRadius(10)
    }
}

struct StaticMapView: UIViewRepresentable {
    var pickupCoordinate: CLLocationCoordinate2D
    var dropoffCoordinate: CLLocationCoordinate2D

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: StaticMapView

        init(parent: StaticMapView) {
            self.parent = parent
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator

        let pickupAnnotation = MKPointAnnotation()
        pickupAnnotation.coordinate = pickupCoordinate
        pickupAnnotation.title = "A"

        let dropoffAnnotation = MKPointAnnotation()
        dropoffAnnotation.coordinate = dropoffCoordinate
        dropoffAnnotation.title = "B"

        mapView.addAnnotations([pickupAnnotation, dropoffAnnotation])

        let region = MKCoordinateRegion(
            center: pickupCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
        mapView.setRegion(mapView.regionThatFits(region), animated: true)

        // Draw the route between pickup and dropoff
        let pickupPlacemark = MKPlacemark(coordinate: pickupCoordinate)
        let dropoffPlacemark = MKPlacemark(coordinate: dropoffCoordinate)
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: pickupPlacemark)
        request.destination = MKMapItem(placemark: dropoffPlacemark)
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            if let error = error {
                print("Error calculating directions: \(error.localizedDescription)")
                return
            }

            if let route = response?.routes.first {
                mapView.addOverlay(route.polyline, level: .aboveRoads)
            }
        }

        return mapView
    }

    func updateUIView(_ view: MKMapView, context: Context) {
        // No need to update the map view as it should remain static
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .darkGreen
            renderer.lineWidth = 5.0
            return renderer
        }
        return MKOverlayRenderer()
    }
}
