//
//  LocationPickerView.swift
//  GizeTransport
//
//  Created by User on 11/14/24.
//

import SwiftUI
import MapKit

struct LocationPickerView: UIViewRepresentable {
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    @Binding var selectedAddress: String?
    var initialCoordinate: CLLocationCoordinate2D

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        let coordinate = selectedCoordinate ?? initialCoordinate
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)), animated: false)
        context.coordinator.updateCenterAnnotation(on: mapView, coordinate: coordinate)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: LocationPickerView
        private let annotation = MKPointAnnotation()

        init(_ parent: LocationPickerView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            updateCenterAnnotation(on: mapView, coordinate: mapView.centerCoordinate)
            parent.selectedCoordinate = mapView.centerCoordinate
            reverseGeocode(mapView.centerCoordinate)
        }

        func updateCenterAnnotation(on mapView: MKMapView, coordinate: CLLocationCoordinate2D) {
            annotation.coordinate = coordinate
            annotation.title = "Selected location"
            if !mapView.annotations.contains(where: { ($0 as AnyObject) === annotation }) {
                mapView.addAnnotation(annotation)
            }
        }

        private func reverseGeocode(_ coordinate: CLLocationCoordinate2D) {
            let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
            CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
                let address = placemarks?.first?.formattedAddress ?? "Selected location"
                DispatchQueue.main.async {
                    self.parent.selectedAddress = address
                }
            }
        }
    }
}
