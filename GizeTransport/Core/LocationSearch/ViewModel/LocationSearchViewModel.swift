//
//  LocationSearchViewModel.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/7/22.
//

import Foundation
import MapKit
import Firebase

enum LocationResultsViewConfig {
    case ride
    case savedLocation(SavedLocationViewModel)
}

class LocationSearchViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedUberLocation: UberLocation?
    @Published var pickUpTime: String?
    @Published var dropOffTime: String?
    @Published var locationResult: String?
    @Published var queryFragment: String = ""
    var userLocation: CLLocationCoordinate2D?

    private let searchCompleter = MKLocalSearchCompleter()

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
    }

    func fetchPlaces(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else {
            results = []
            return
        }
        searchCompleter.queryFragment = trimmed
    }

    func selectLocation(_ prediction: MKLocalSearchCompletion, config: LocationResultsViewConfig) {
        resolveCompletion(prediction) { [weak self] mapItem in
            guard let self = self, let mapItem = mapItem else { return }
            let coordinate = mapItem.placemark.coordinate
            let name = mapItem.name ?? prediction.title

            switch config {
            case .ride:
                self.selectedUberLocation = UberLocation(title: name, coordinate: coordinate)

            case .savedLocation(let viewModel):
                guard let uid = Auth.auth().currentUser?.uid else { return }
                let savedLocation = SavedLocation(
                    title: name,
                    address: mapItem.placemark.formattedAddress,
                    coordinates: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                )
                guard let encodedLocation = try? Firestore.Encoder().encode(savedLocation) else { return }
                Firestore.firestore().collection("users").document(uid).updateData([
                    viewModel.dataabaseKey: encodedLocation
                ]) { error in
                    if let error = error {
                        AppLogger.error("Saved location update failed: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    private func resolveCompletion(_ completion: MKLocalSearchCompletion, finished: @escaping (MKMapItem?) -> Void) {
        let request = MKLocalSearch.Request(completion: completion)
        MKLocalSearch(request: request).start { response, error in
            if let error = error {
                AppLogger.error("Apple Maps search failed: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                finished(response?.mapItems.first)
            }
        }
    }

    func computeRidePrice(forType type: RideType) -> Double {
        guard let destCoordinate = selectedUberLocation?.coordinate,
              let userCoordinate = self.userLocation else { return 0.0 }

        let userLocation = CLLocation(latitude: userCoordinate.latitude, longitude: userCoordinate.longitude)
        let destination = CLLocation(latitude: destCoordinate.latitude, longitude: destCoordinate.longitude)
        let tripDistanceInMeters = userLocation.distance(from: destination)
        return type.computePrice(for: tripDistanceInMeters)
    }

    func getDestinationRoute(from userLocation: CLLocationCoordinate2D, to destination: CLLocationCoordinate2D, completion: @escaping (MKPolyline?) -> Void) {
        AppleMapsRouting.route(from: userLocation, to: destination) { route in
            completion(route?.polyline)
        }
    }

    func configurePickupAndDropoffTimes(with travelTimeInSeconds: TimeInterval) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        pickUpTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date().addingTimeInterval(travelTimeInSeconds))
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.error("Apple Maps autocomplete failed: \(error.localizedDescription)")
    }
}
