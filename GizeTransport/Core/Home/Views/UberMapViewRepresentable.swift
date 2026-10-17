import SwiftUI
import MapKit
import Firebase
import FirebaseFirestore

private enum MapConstants {
    static let defaultSpan = MKCoordinateSpan(latitudeDelta: 0.018, longitudeDelta: 0.018)
    static let routeLineWidth: CGFloat = 5
}

struct UberMapViewRepresentable: UIViewRepresentable {
    @Binding var mapState: MapViewState
    @Binding var recenterTrigger: Int
    @EnvironmentObject var homeViewModel: HomeViewModel
    @ObservedObject var locationManager = LocationManager.shared

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(parent: self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.userTrackingMode = .none
        mapView.showsCompass = false
        mapView.showsScale = false
        mapView.isPitchEnabled = false
        mapView.isRotateEnabled = false
        mapView.pointOfInterestFilter = .includingAll
        if #available(iOS 16.0, *) {
            let configuration = MKStandardMapConfiguration(elevationStyle: .flat)
            configuration.showsTraffic = false
            mapView.preferredConfiguration = configuration
        } else {
            mapView.mapType = .standard
            mapView.showsTraffic = false
            mapView.showsBuildings = false
        }
        context.coordinator.startDriverObservation()
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        guard mapView.bounds.width > 1, mapView.bounds.height > 1 else { return }
        context.coordinator.sync(mapView: mapView, state: mapState)
    }

    static func dismantleUIView(_ mapView: MKMapView, coordinator: MapCoordinator) {
        coordinator.stopDriverObservation()
        mapView.delegate = nil
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations.filter { !($0 is MKUserLocation) })
    }
}

final class MapCoordinator: NSObject, MKMapViewDelegate {
    private let parent: UberMapViewRepresentable
    private weak var mapView: MKMapView?
    private var driverLocationsListener: ListenerRegistration?
    private var driverAnnotations = [String: DriverMapAnnotation]()
    private var routeOverlays = [MKPolyline]()
    private var fallbackUserAnnotation: PassengerLocationAnnotation?
    private var didCenterOnUser = false
    private var isUserChangingRegion = false
    private var lastRecenterTrigger = 0
    private var lastRenderedTripKey: String?
    private var lastRouteKey: String?
    private var routeRequestID = UUID()

    init(parent: UberMapViewRepresentable) {
        self.parent = parent
        super.init()
    }

    func startDriverObservation() {
        guard driverLocationsListener == nil else { return }

        driverLocationsListener = Firestore.firestore().collection("users")
            .whereField("accountType", isEqualTo: AccountType.driver.rawValue)
            .whereField("isActive", isEqualTo: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    AppLogger.error("Driver location fetch failed: \(error.localizedDescription)")
                    return
                }

                var locations = [String: CLLocationCoordinate2D]()
                snapshot?.documents.forEach { document in
                    guard let driver = try? document.data(as: User.self) else { return }
                    let coordinate = driver.coordinates.toCoordinate()
                    guard coordinate.isUsableCoordinate else { return }
                    locations[driver.id ?? driver.uid] = coordinate
                }

                DispatchQueue.main.async {
                    self?.updateDriverAnnotations(locations)
                }
            }
    }

    func stopDriverObservation() {
        driverLocationsListener?.remove()
        driverLocationsListener = nil
    }

    func sync(mapView: MKMapView, state: MapViewState) {
        self.mapView = mapView
        guard mapView.window != nil, mapView.bounds.width > 1, mapView.bounds.height > 1 else { return }
        syncPassengerLocationMarker(on: mapView)
        centerOnUserIfNeeded(mapView)
        recenterIfRequested(mapView)

        switch state {
        case .tripRequested:
            guard let trip = parent.homeViewModel.trip else { return }
            renderTripIfNeeded(trip: trip, state: state, pickup: trip.pickupLocationCoordiantes, dropoff: trip.dropoffLocationCoordinates)
        case .tripAccepted:
            guard let trip = parent.homeViewModel.trip else { return }
            renderTripIfNeeded(trip: trip, state: state, pickup: trip.pickupLocationCoordiantes, dropoff: trip.dropoffLocationCoordinates)
            if let route = parent.homeViewModel.routeToPickupLocation {
                draw(route, tint: .systemCyan)
            }
            configureRouteIfNeeded(to: trip.dropoffLocationCoordinates, trip: trip, state: state)
        case .tripArrived, .tripStarted:
            guard let trip = parent.homeViewModel.trip else { return }
            renderTripIfNeeded(trip: trip, state: state, pickup: trip.pickupLocationCoordiantes, dropoff: trip.dropoffLocationCoordinates)
            configureRouteIfNeeded(to: trip.dropoffLocationCoordinates, trip: trip, state: state)
        case .tripCompleted, .tripCancelledByDriver, .tripCancelledByPassenger, .noInput, .noTrip, .tripRejected:
            clearTripOverlays()
        default:
            break
        }
    }

    func updateDriverAnnotations(_ locations: [String: CLLocationCoordinate2D]) {
        guard let mapView = mapView else { return }

        for (driverId, annotation) in driverAnnotations where locations[driverId] == nil {
            mapView.removeAnnotation(annotation)
            driverAnnotations.removeValue(forKey: driverId)
        }

        for (driverId, coordinate) in locations {
            guard coordinate.isValidForMap else { continue }
            if let annotation = driverAnnotations[driverId] {
                UIView.animate(withDuration: 0.25) {
                    annotation.coordinate = coordinate
                }
            } else {
                let annotation = DriverMapAnnotation(id: driverId, coordinate: coordinate)
                driverAnnotations[driverId] = annotation
                mapView.addAnnotation(annotation)
            }
        }
    }

    private func centerOnUserIfNeeded(_ mapView: MKMapView) {
        guard !didCenterOnUser, let coordinate = bestPassengerCoordinate else { return }
        didCenterOnUser = true
        setVisibleRegion(on: mapView, centeredAt: coordinate, animated: false)
    }

    private func recenterIfRequested(_ mapView: MKMapView) {
        guard parent.recenterTrigger != lastRecenterTrigger else { return }
        lastRecenterTrigger = parent.recenterTrigger
        guard let coordinate = bestPassengerCoordinate else { return }
        isUserChangingRegion = false
        didCenterOnUser = true
        mapView.userTrackingMode = .none
        setVisibleRegion(on: mapView, centeredAt: coordinate, animated: false)
    }

    private var bestPassengerCoordinate: CLLocationCoordinate2D? {
        if let liveCoordinate = parent.locationManager.userLocation?.coordinate,
           liveCoordinate.isValidPassengerFallbackCoordinate {
            return liveCoordinate
        }

        guard let savedCoordinate = parent.homeViewModel.currentUser?.coordinates.toCoordinate(),
              savedCoordinate.isValidPassengerFallbackCoordinate else { return nil }
        return savedCoordinate
    }

    private func setVisibleRegion(on mapView: MKMapView, centeredAt coordinate: CLLocationCoordinate2D, animated: Bool) {
        guard mapView.window != nil,
              mapView.bounds.width > 1,
              mapView.bounds.height > 1,
              coordinate.isValidPassengerFallbackCoordinate else { return }

        let region = MKCoordinateRegion(center: coordinate, span: MapConstants.defaultSpan)
        mapView.setRegion(mapView.regionThatFits(region), animated: animated)
    }

    private func syncPassengerLocationMarker(on mapView: MKMapView) {
        guard let coordinate = bestPassengerCoordinate,
              coordinate.isValidPassengerFallbackCoordinate else {
            if let fallbackUserAnnotation {
                mapView.removeAnnotation(fallbackUserAnnotation)
                self.fallbackUserAnnotation = nil
            }
            return
        }

        if let fallbackUserAnnotation {
            if fallbackUserAnnotation.coordinate.routeKey != coordinate.routeKey {
                fallbackUserAnnotation.coordinate = coordinate
            }
        } else {
            let annotation = PassengerLocationAnnotation(coordinate: coordinate)
            fallbackUserAnnotation = annotation
            mapView.addAnnotation(annotation)
        }
    }

    private func showTripPins(pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D) {
        guard let mapView = mapView else { return }
        guard pickup.isValidForMap, dropoff.isValidForMap else { return }
        let existingTripPins = mapView.annotations.filter { $0 is TripMapAnnotation }
        mapView.removeAnnotations(existingTripPins)

        mapView.addAnnotation(TripMapAnnotation(title: "Pickup", coordinate: pickup, kind: .pickup))
        mapView.addAnnotation(TripMapAnnotation(title: "Drop-off", coordinate: dropoff, kind: .dropoff))
        fitMap(to: [pickup, dropoff])
    }

    private func renderTripIfNeeded(trip: Trip, state: MapViewState, pickup: CLLocationCoordinate2D, dropoff: CLLocationCoordinate2D) {
        let tripKey = "\(trip.id)-\(state)-\(pickup.routeKey)-\(dropoff.routeKey)"
        guard tripKey != lastRenderedTripKey else { return }
        lastRenderedTripKey = tripKey
        showTripPins(pickup: pickup, dropoff: dropoff)
    }

    private func configureRouteIfNeeded(to destination: CLLocationCoordinate2D, trip: Trip, state: MapViewState) {
        guard let origin = parent.locationManager.userLocation?.coordinate,
              origin.isValidForMap,
              destination.isValidForMap else { return }
        let routeKey = "\(trip.id)-\(state)-\(origin.routeKey)-\(destination.routeKey)"
        guard routeKey != lastRouteKey else { return }
        lastRouteKey = routeKey

        let requestID = UUID()
        routeRequestID = requestID

        AppleMapsRouting.route(from: origin, to: destination) { [weak self] route in
            guard let self = self, self.routeRequestID == requestID else { return }
            let polyline = route?.polyline ?? MKPolyline(coordinates: [origin, destination], count: 2)
            self.draw(polyline, tint: .darkGreen)
        }
    }

    private func draw(_ polyline: MKPolyline, tint: UIColor) {
        guard let mapView = mapView else { return }
        mapView.removeOverlays(routeOverlays)
        routeOverlays = [polyline]
        mapView.addOverlay(polyline)
        fitMap(to: polyline.coordinates)
    }

    private func clearTripOverlays() {
        guard let mapView = mapView else { return }
        let tripPins = mapView.annotations.filter { $0 is TripMapAnnotation }
        mapView.removeAnnotations(tripPins)
        mapView.removeOverlays(routeOverlays)
        routeOverlays.removeAll()
        lastRenderedTripKey = nil
        lastRouteKey = nil
    }

    private func fitMap(to coordinates: [CLLocationCoordinate2D]) {
        guard let mapView = mapView, !coordinates.isEmpty else { return }
        guard !isUserChangingRegion else { return }
        let validCoordinates = coordinates.filter(\.isValidForMap)
        guard !validCoordinates.isEmpty else { return }
        var rect = MKMapRect.null
        validCoordinates.forEach { coordinate in
            let point = MKMapPoint(coordinate)
            rect = rect.union(MKMapRect(x: point.x, y: point.y, width: 1, height: 1))
        }
        guard !rect.isNull, !rect.isEmpty else { return }
        mapView.setVisibleMapRect(rect, edgePadding: UIEdgeInsets(top: 90, left: 60, bottom: 260, right: 60), animated: true)
    }

    func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        isUserChangingRegion = mapView.isRegionChangeFromUserInteraction
        if isUserChangingRegion {
            mapView.userTrackingMode = .none
        }
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        guard isUserChangingRegion else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.isUserChangingRegion = false
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard !(annotation is MKUserLocation) else { return nil }

        if let driver = annotation as? DriverMapAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: "driver") ?? MKAnnotationView(annotation: driver, reuseIdentifier: "driver")
            view.annotation = driver
            view.image = UIImage(named: "car") ?? UIImage(systemName: "car.fill")
            view.canShowCallout = true
            return view
        }

        if let tripPin = annotation as? TripMapAnnotation {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: "trip") as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: tripPin, reuseIdentifier: "trip")
            marker.annotation = tripPin
            marker.markerTintColor = tripPin.kind == .pickup ? .darkGreen : .systemRed
            marker.glyphImage = UIImage(systemName: tripPin.kind == .pickup ? "figure.wave" : "mappin.and.ellipse")
            marker.canShowCallout = true
            return marker
        }

        if let passenger = annotation as? PassengerLocationAnnotation {
            let marker = mapView.dequeueReusableAnnotationView(withIdentifier: "passengerLocation") as? MKMarkerAnnotationView ?? MKMarkerAnnotationView(annotation: passenger, reuseIdentifier: "passengerLocation")
            marker.annotation = passenger
            marker.markerTintColor = .systemBlue
            marker.glyphImage = UIImage(systemName: "location.fill")
            marker.canShowCallout = true
            return marker
        }

        return nil
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .darkGreen
            renderer.lineWidth = MapConstants.routeLineWidth
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }
        return MKOverlayRenderer(overlay: overlay)
    }
}

private final class DriverMapAnnotation: NSObject, MKAnnotation {
    let id: String
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { "Driver" }

    init(id: String, coordinate: CLLocationCoordinate2D) {
        self.id = id
        self.coordinate = coordinate
    }
}

private final class TripMapAnnotation: NSObject, MKAnnotation {
    enum Kind { case pickup, dropoff }
    let title: String?
    dynamic var coordinate: CLLocationCoordinate2D
    let kind: Kind

    init(title: String, coordinate: CLLocationCoordinate2D, kind: Kind) {
        self.title = title
        self.coordinate = coordinate
        self.kind = kind
    }
}

private final class PassengerLocationAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var title: String? { "Your location" }
    var subtitle: String? { "Pickup guidance starts here." }

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

private extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = Array(repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))
        return coords
    }
}

private extension CLLocationCoordinate2D {
    var isValidForMap: Bool {
        CLLocationCoordinate2DIsValid(self) && latitude.isFinite && longitude.isFinite
    }

    var routeKey: String {
        "\(latitude.rounded(toPlaces: 5)),\(longitude.rounded(toPlaces: 5))"
    }

    var isValidPassengerFallbackCoordinate: Bool {
        isValidForMap && !(abs(latitude) < 0.0001 && abs(longitude) < 0.0001)
    }
}

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

private extension MKMapView {
    var isRegionChangeFromUserInteraction: Bool {
        guard let view = subviews.first else { return false }
        return view.gestureRecognizers?.contains { recognizer in
            recognizer.state == .began || recognizer.state == .changed
        } ?? false
    }
}
