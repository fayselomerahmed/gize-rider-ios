//
//  LocationManager.swift
//  UberSwiftUitutorial
//
//  Created by User on 11/15/22.
//
import Combine
import CoreLocation
import MapKit

enum RegionType: String {
    case pickup
    case dropoff
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    static let shared = LocationManager()

    @Published var userLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var lastLocationError: CLError?
    @Published var didEnterPickupRegion = false
    @Published var didEnterDropoffRegion = false

    private let regionRadius: CLLocationDistance = 25
    private var pickupCoordinate: CLLocationCoordinate2D?
    private var dropoffCoordinate: CLLocationCoordinate2D?

    override init() {
        authorizationStatus = locationManager.authorizationStatus
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.distanceFilter = 5
        requestLocationPermission()
    }

    var isLocationAuthorized: Bool {
        authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse
    }

    var isLocationDenied: Bool {
        authorizationStatus == .denied || authorizationStatus == .restricted
    }

    func requestLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .denied, .restricted:
            AppLogger.warning("Location permission is denied or restricted.")
        @unknown default:
            AppLogger.warning("Unknown location authorization status.")
        }
    }

    func startLocationUpdates() {
        guard isLocationAuthorized else {
            requestLocationPermission()
            return
        }
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.startUpdatingLocation()
    }

    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }

    func createPickupRegionForTrip(_ trip: Trip) {
        pickupCoordinate = trip.pickupLocationCoordiantes
        checkDistanceFromMarkers()
    }

    func createDropoffRegionForTrip(_ trip: Trip) {
        dropoffCoordinate = trip.dropoffLocationCoordinates
        checkDistanceFromMarkers()
    }

    private func checkDistanceFromMarkers() {
        guard let userLocation = userLocation else { return }

        if let pickupCoordinate = pickupCoordinate {
            let pickupLocation = CLLocation(latitude: pickupCoordinate.latitude, longitude: pickupCoordinate.longitude)
            didEnterPickupRegion = userLocation.distance(from: pickupLocation) < regionRadius
        }

        if let dropoffCoordinate = dropoffCoordinate {
            let dropoffLocation = CLLocation(latitude: dropoffCoordinate.latitude, longitude: dropoffCoordinate.longitude)
            didEnterDropoffRegion = userLocation.distance(from: dropoffLocation) < regionRadius
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.lastLocationError = nil
            self.userLocation = location
            self.checkDistanceFromMarkers()
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        DispatchQueue.main.async {
            self.authorizationStatus = status
        }

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startLocationUpdates()
        case .denied, .restricted:
            stopLocationUpdates()
            AppLogger.warning("Location access is not available. Ask the rider to enable Location Services in Settings.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard let clError = error as? CLError else {
            AppLogger.error("Location update failed: \(error.localizedDescription)")
            return
        }

        DispatchQueue.main.async {
            self.lastLocationError = clError
        }

        if clError.code == .denied {
            DispatchQueue.main.async {
                self.authorizationStatus = .denied
                self.userLocation = nil
            }
            stopLocationUpdates()
        }

        AppLogger.error("Location update failed: \(clError.localizedDescription)")
    }

    func updateDriverLocation(driverId: String, location: CLLocationCoordinate2D, rotation: CLLocationDirection) {
        AppLogger.info("Driver annotation update handled by Apple Maps view for \(driverId).")
    }
}
