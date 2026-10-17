//
//  HomeViewModel.swift
//  GizeTransport
//
//  Created by User on 4/20/23.

import SwiftUI
import Firebase
import FirebaseFirestoreSwift
import Combine
import MapKit
import GeoFire
import FirebaseMessaging
import UserNotifications
import FirebaseFirestore

class HomeViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var alertItem: AlertItem?
    @Published var shouldUpdateMap = true
    @Published var driver: Driver?
    private var attemptedDrivers: Set<String> = []
    private var isRequestingDriver = false
    private var countdownTimer: Timer?
    private var driverRefreshTimer: Timer?
    private var countdownDuration: TimeInterval = 15 // 20 seconds
    private var tripStartTime: Date?
    private var isRequestingNextDriver = false
    @Published var rideTypes: [RideType] = []
    private var rideTypesListener: ListenerRegistration?
    private var cancellables = Set<AnyCancellable>()
    @Published var selectedRideType: RideType?
    private var remainingDrivers: [(String, CLLocationDistance)] = []
    var driverQueue: [User] = []
    private let radius: CLLocationDistance = 300

    var listenersDictionary: [String: ListenerRegistration] = [:]
    @Published var drivers = [User]()
    @Published var trip: Trip?
    @Published var preOrderTrip: Trip?
    private var previousLocation: CLLocation?
    private let service = UserService.shared
    var currentUser: User?
    var didExecuteFetchDrivers = false
    @Published var mapState = MapViewState.noInput
    var routeToPickupLocation: MKPolyline?
    @Published var errorMessage: String?
    @State var isPreorderSuccessful = false
    @Published var results = [MKLocalSearchCompletion]()
    @Published var selectedUberLocation: UberLocation?
    @Published var pickUpTime: String?
    @Published var dropOffTime: String?
    var userLocation: CLLocationCoordinate2D?
    @Published var locationResult: String?
    @Published var selectedReasons: Set<String> = []
    private let searchCompleter = MKLocalSearchCompleter()
    @Published var isLoading: Bool = false
    @Published var currentTrip: Trip?
    @Published var reasonsForCancellation: [String] = [
        "Change of plans",
        "Long wait time",
        "Driver didn't show up",
        "Driver behaviour",
        "Found a better option",
        "Other"
    ]
    @Published var startLocationQuery: String = ""
    @Published var destinationQuery: String = ""
    @Published var startLocationText: String = ""
    @Published var destinationText: String = ""
    var activeField: LocationFieldType? = nil
    private var locationManager = LocationManager.shared
    @Published var startLocation: CLLocationCoordinate2D?
    @Published var destination: CLLocationCoordinate2D?
    @Published var totalDistanceTraveled: Double = 0.0 // in kilometers or miles

    private let costPerKilometer = 1.2
    let fcmManager = FCMNotificationManager()
    func reset() {
        self.selectedUberLocation = nil
        self.trip = nil
    }

    func clearCurrentTrip() {
        self.trip = nil
        self.selectedUberLocation = nil
        shouldUpdateMap = true
    }

    override init() {
        super.init()
        searchCompleter.delegate = self
        searchCompleter.resultTypes = [.address, .pointOfInterest]
        fetchUser { [weak self] success in
            guard let self = self, success, let currentUser = self.currentUser else {
                print("Failed to fetch user or user is nil")
                return
            }
            self.setDefaultStartLocation()
            self.fetchOnlineDrivers() // Fetch online drivers on startup
            self.startUpdatingDrivers() // Start periodic updates
        }
        setupLocationManager()
        currentTrip = Trip(tripId: nil, passengerUid: "", driverUid: "", passengerName: "", driverName: "", passengerLocation: GeoPoint(latitude: 0, longitude: 0), driverLocation: GeoPoint(latitude: 0, longitude: 0), pickupLocationName: "", dropofflocationName: "", pickupLocationAddress: "", pickupLocation: GeoPoint(latitude: 0, longitude: 0), dropoffLocation: GeoPoint(latitude: 0, longitude: 0), tripCost: 0, distanceToPassenger: 0, travelTimeToPassenger: 0, state: .requested, tripType: .now, rideType: selectedRideType, tripDate: nil, timestamp: nil)
    }

    deinit {
        removeAllListeners()
        countdownTimer?.invalidate()
        driverRefreshTimer?.invalidate()
    }

    // MARK: - HELPERS
    var tripCancelledMessage: String {
        guard let user = currentUser, let trip = trip else {return ""}
        if user.accountType == .passenger {
            if trip.state == .driverCancelled {
                deleteTrip()
                return "Your Driver Cancelled this Trip. Press Ok to Continue"
            } else if trip.state == .passengerCancelled {
                return "Your Trip Has Been Cancelled"
            }
        } else {
            if trip.state == .passengerCancelled {
                deleteTrip()
                return "Your Trip Has Been Cancelled"
            } else if trip.state == .passengerCancelled {
                deleteTrip()
                return "The Trip Has Been Cancelled By The Passenger"
            }
        }
        return ""
    }
    func confirmTripCancellation() {
        DispatchQueue.main.async { [weak self] in
            self?.alertItem = AlertItem(
                title: Text("Cancel Trip"),
                message: Text("Are you sure you want to cancel the trip?"),
                primaryButton: .destructive(Text("Yes, Cancel"), action: {
                    self?.cancelTripAsPassenger()
                }),
                secondaryButton: .cancel()
            )
        }
    }
    private func handleError(_ error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.alertItem = AlertItem(
                title: Text("Error"),
                message: Text(error.localizedDescription),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    private func handleNoDriversAvailable() {
        DispatchQueue.main.async { [weak self] in
            self?.alertItem = AlertItem(
                title: Text("No Drivers Available"),
                message: Text("We're sorry, but there are no drivers available at the moment. Please try again later."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    private func handleCustomError(_ message: String) {
        DispatchQueue.main.async { [weak self] in
            self?.alertItem = AlertItem(
                title: Text("Error"),
                message: Text(message),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    func listenForRideTypes() {
        // Detach any existing listener to avoid duplication
        detachRideTypesListener()

        // Start listening for updates in the `RideTypes` collection
        rideTypesListener = Firestore.firestore().collection("RideTypes")
            .whereField("isActive", isEqualTo: true) // Filter for active ride types
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }

                if let error = error {
                    print("DEBUG: Error listening to ride types: \(error.localizedDescription)")
                    return
                }

                guard let documents = snapshot?.documents else {
                    print("DEBUG: No ride types found.")
                    return
                }

                // Map Firestore documents to `RideType` models
                self.rideTypes = documents.compactMap { document -> RideType? in
                    let data = document.data()
                    return RideType(
                        id: data["id"] as? Int ?? 0,
                        name: data["name"] as? String ?? "",
                        description: data["description"] as? String ?? "",
                        baseFare: data["baseFare"] as? Double ?? 0.0,
                        perKilometerRate: data["perKilometerRate"] as? Double ?? 0.0,
                        imageName: data["imageName"] as? String ?? ""
                    )
                }
                print("DEBUG: Ride types updated: \(self.rideTypes)")
            }
    }

    func detachRideTypesListener() {
        rideTypesListener?.remove()
        rideTypesListener = nil
    }
    func fetchRideTypes() {
        isLoading = true
        Firestore.firestore().collection("RideTypes")
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.isLoading = false
                    if let error = error {
                        print("DEBUG: Error fetching ride types: \(error.localizedDescription)")
                        return
                    }
                    self.rideTypes = snapshot?.documents.compactMap { document -> RideType? in
                        let data = document.data()
                        return RideType(
                            id: data["id"] as? Int ?? 0,
                            name: data["name"] as? String ?? "",
                            description: data["description"] as? String ?? "",
                            baseFare: data["baseFare"] as? Double ?? 0.0,
                            perKilometerRate: data["perKilometerRate"] as? Double ?? 0.0,
                            imageName: data["imageName"] as? String ?? ""
                        )
                    } ?? []
                }
            }
    }
//    private func showAlert(title: String, message: String) {
//        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
//              let rootViewController = windowScene.windows.first?.rootViewController else {
//            return
//        }
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
//        rootViewController.present(alert, animated: true, completion: nil)
//    }

    func viewForState(_ state: MapViewState, user: User) -> some View {
        switch state {
        case .polylineAdded, .locationSelected:
            return AnyView(RideRequestView())
        case .tripRequested:
            if user.accountType == .passenger {
                return AnyView(TripLoadingView())
            } else {
                if let trip = self.trip {
                    return AnyView(AcceptTripView(trip: trip))
                }
            }
        case .tripAccepted:
            if trip?.tripType == .now {
                return AnyView(TripAcceptedView())
            } else if trip?.tripType == .preorder {
                return AnyView(PreorderSuccessView())
            }
        case .tripCancelledByPassenger, .tripCancelledByDriver:
            return AnyView(TripCancelledView())
        case .tripArrived:
            if self.trip != nil {
                return AnyView(DriverInProgress())
            }
        case .tripStarted:
            return AnyView(TripStartedView())
        case .tripCompleted:
            if let trip = self.trip {
                return AnyView(TripCompletedView(isPresented: .constant(true)))
            }
        case .preordered:
            return AnyView(PreOrderView())
        default:
            break
        }
        return AnyView(Text(""))
    }

    func removeAllListeners() {
        for (_, listener) in listenersDictionary {
            listener.remove()
        }
        listenersDictionary.removeAll()
        
        driverRefreshTimer?.invalidate()
        driverRefreshTimer = nil
    }


    // MARK: - User API
    private func setupLocationManager() {
        let locationManager = LocationManager.shared
        locationManager.$userLocation
            .sink { [weak self] location in
                guard let self = self, let location = location else { return }
                self.updateCurrentUserLocation(location: location)
            }
            .store(in: &cancellables)
    }

    func updateCurrentUserLocation(location: CLLocation) {
        guard var currentUser = currentUser, let userId = currentUser.id else { return }

        if let previousLocation = previousLocation {
            let distance = location.distance(from: previousLocation)
            if distance < 7 {
                return
            }
        }

        previousLocation = location
        currentUser.coordinates = GeoPoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)

        let userRef = Firestore.firestore().collection("users").document(userId)
        do {
            // Use merge to prevent overwriting the FCM token
            try userRef.setData(from: currentUser, merge: true) { error in
                if let error = error {
                    print("Error updating user location: \(error.localizedDescription)")
                } else {
                    print("Successfully updated user location")
                }
            }
        } catch let error {
            print("Error encoding user: \(error.localizedDescription)")
        }
    }


    private func fetchUser(completion: @escaping (Bool) -> Void) {
        isLoading = true
        service.$user
            .receive(on: DispatchQueue.main) // Ensure updates happen on the main thread
            .sink { [weak self] user in
                guard let self = self else {
                    completion(false)
                    return
                }
                self.currentUser = user
                self.isLoading = false
                AppLogger.info("Account profile loaded.")
                
                guard let user = user else {
                    completion(false)
                    return
                }

                if user.accountType == .passenger {
                    self.fetchDrivers()
                    self.addTripObserverForPassenger()
                    self.addPreOrderTripObserverForPassenger()
                } else if user.accountType == .driver {
                    self.addTripObserverForDriver()
                }
                completion(true)
            }
            .store(in: &cancellables)
    }


    private func updateTripState(state: TripState) {
        guard let trip = trip else { return }
        var tripsData = ["state": state.rawValue]
        
        if state == .accepted {
            tripsData["travelTimeToPassenger"] = trip.travelTimeToPassenger
        }
        
        // Log the state change for debugging
        print("DEBUG: Updating trip state to \(state.rawValue)")
        
        let tripRef = Firestore.firestore().collection("trips").document(trip.id)
        let preorderRef = Firestore.firestore().collection("preorder").document(trip.id)

        // Update `trips` collection
        tripRef.updateData(tripsData) { [weak self] error in
            if let error = error {
                print("ERROR: Failed to update trip in 'trips' collection: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully updated trip state in 'trips' collection.")
                self?.sendNotificationBasedOnStateChange(state: state) // Trigger notification on state change
            }
        }

        // Update `preorder` collection
        preorderRef.setData(tripsData) { [weak self] error in
            if let error = error {
                print("ERROR: Failed to update trip in 'preorder' collection: \(error.localizedDescription)")
            } else {
                print("DEBUG: Successfully updated trip state in 'preorder' collection.")
                self?.sendNotificationBasedOnStateChange(state: state) // Trigger notification on state change
            }
        }
    }

    private func sendNotificationBasedOnStateChange(state: TripState) {
        print("DEBUG: Preparing to send notification for state: \(state.rawValue)")
        guard let trip = self.trip else {
            print("DEBUG: No trip found, notification not sent.")
            return
        }
        
        let (title, body) = getNotificationDetails(for: state)
        
        // Send automated notification for general updates
        fcmManager.sendAutomatedNotification(title: title, body: body)
        
        // Determine target user based on the state
        let targetId: String
        switch state {
        case .requested, .passengerCancelled:
            targetId = trip.driverUid
        case .accepted, .arrived, .tripCompleted, .driverCancelled:
            targetId = trip.passengerUid
        default:
            print("DEBUG: No notification action required for state: \(state.rawValue)")
            return
        }
        
        AppLogger.info("Sending a trip-state notification.")
        fcmManager.sendMessageToDriver(driverId: targetId, title: title, body: body)
    }

    // Helper to provide notification details
    private func getNotificationDetails(for state: TripState) -> (title: String, body: String) {
        switch state {
        case .requested:
            return ("Trip Requested", "Your trip has been requested. Please wait while we find a driver.")
        case .accepted:
            return ("Trip Accepted", "Your driver has accepted the trip. They are on their way!")
        case .rejected:
            return ("Trip Rejected", "Your trip request was rejected. Trying to find another driver.")
        case .arrived:
            return ("Driver Arrived", "Your driver has arrived at the pickup location.")
        case .starttrip:
            return ("Trip Started", "Your trip has started. Enjoy your ride!")
        case .tripCompleted:
            return ("Trip Completed", "Your trip has been completed. Thank you for riding with us!")
        case .driverCancelled:
            return ("Trip Cancelled by Driver", "Your trip was cancelled by the driver.")
        case .passengerCancelled:
            return ("Trip Cancelled", "You have cancelled the trip.")
        case .noTrip:
            return ("No Active Trip", "There is currently no active trip.")
        default:
            return ("", "")
        }
    }



    func deleteTrip() {
        guard let trip = trip else {
            print("No trip to delete.")
            return
        }
        guard preOrderTrip != nil else {
            print("No pre-order trip to delete.")
            return
        }

        var deletionErrors: [Error?] = []

        let group = DispatchGroup()

        group.enter()
        Firestore.firestore().collection("preorder").document(trip.id).delete { error in
            if let error = error {
                print("Error deleting pre-order trip: \(error.localizedDescription)")
                deletionErrors.append(error)
            } else {
                print("Pre-order trip deleted successfully.")
            }
            group.leave()
        }

        group.enter()
        Firestore.firestore().collection("trips").document(trip.id).delete { error in
            if let error = error {
                print("Error deleting trip: \(error.localizedDescription)")
                deletionErrors.append(error)
            } else {
                print("Trip deleted successfully.")
            }
            group.leave()
        }

        group.notify(queue: .main) {
            if deletionErrors.isEmpty {
                self.trip = nil
                print("All deletion processes completed successfully and trip object set to nil.")
            } else {
                print("Failed to delete some or all documents: \(deletionErrors)")
            }
        }
    }

    func emergencyCall() {
        print("Emergency button tapped")
        if let url = URL(string: "tel://911"), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }


    func removeDriverListener() {
        drivers.forEach { driver in
            guard let driverID = driver.id else { return }
            listenersDictionary[driverID]?.remove()
            listenersDictionary[driverID] = nil
        }
    }

    func addListenerToDriverLocation(driverID: String, completion: @escaping (CLLocationCoordinate2D?, Bool) -> Void) {
        let COLLECTION_USERS = Firestore.firestore().collection("users")

        let driverListener = COLLECTION_USERS.document(driverID).addSnapshotListener { [weak self] snapshot, error in
            guard self != nil else { return }

            if let error = error {
                print("Error listening to driver location: \(error.localizedDescription)")
                completion(nil, false)
                return
            }

            guard let data = snapshot?.data() else {
                completion(nil, false)
                return
            }

            guard let isActive = data["isActive"] as? Bool else {
                completion(nil, false)
                return
            }

            let driver = try? snapshot?.data(as: User.self)
            let driverLocation = driver?.coordinates.toCoordinate()

            DispatchQueue.main.async {
                completion(driverLocation, isActive)
            }
        }

        listenersDictionary[driverID] = driverListener
    }

    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error)")
            }
        }
    }

    func scheduleNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Ride Request Sent"
        content.body = "Please Wait until a driver is assigned to you"
        content.sound = UNNotificationSound.defaultCritical

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { (error) in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }


    func sendFCMNotification(to token: String, title: String, body: String, accessToken: String, url: URL) {
        // Notification payload with platform-specific options
        let notificationContent: [String: Any] = [
            "message": [
                "token": token,
                "notification": [
                    "title": title,
                    "body": body
                ],
                "android": [
                    "priority": "high",
                    "notification": [
                        "sound": "default"
                    ]
                ],
                "apns": [
                    "payload": [
                        "aps": [
                            "sound": "default"
                        ]
                    ],
                    "headers": [
                        "apns-priority": "10"
                    ]
                ]
            ]
        ]

        // HTTP request to FCM
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        do {
            let jsonData = try JSONSerialization.data(withJSONObject: notificationContent, options: [])
            request.httpBody = jsonData

            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error sending notification: \(error.localizedDescription)")
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse else {
                    print("Invalid response from FCM.")
                    return
                }

                if httpResponse.statusCode == 200 {
                    print("Notification sent successfully.")
                } else {
                    print("Failed to send notification. HTTP Status Code: \(httpResponse.statusCode)")
                }
            }
            task.resume()

        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
        }
    }

    // Refactored function to handle access token logic
//    func sendSelfFCMNotification(title: String, body: String) {
//        guard let url = URL(string: "https://fcm.googleapis.com/v1/projects/transport-app-19f11/messages:send") else {
//            print("Invalid FCM URL.")
//            return
//        }
//
//        let tokenManager = AccessTokenManager.shared
//
//        // Ensure the access token is available
//        guard let accessToken = tokenManager.accessToken, !accessToken.isEmpty else {
//            print("Access token is missing or invalid.")
//            // Attempt to refresh the token here
//            tokenManager.refreshAccessToken { refreshedToken in
//                guard let refreshedToken = refreshedToken else {
//                    print("Unable to refresh access token.")
//                    return
//                }
//                // Proceed to send the notification after refreshing the token
//                self.requestDeviceToken { [weak self] deviceToken in
//                    guard let deviceToken = deviceToken else {
//                        print("Failed to retrieve device token.")
//                        return
//                    }
//                    self?.sendFCMNotification(to: deviceToken, title: title, body: body, accessToken: refreshedToken, url: url)
//                }
//            }
//            return
//        }
//
//        // Proceed to send the notification
//        requestDeviceToken { [weak self] deviceToken in
//            guard let deviceToken = deviceToken else {
//                print("Failed to retrieve device token.")
//                return
//            }
//            self?.sendFCMNotification(to: deviceToken, title: title, body: body, accessToken: accessToken, url: url)
//        }
//    }

    // Refactored device token request function
    func requestDeviceToken(completion: @escaping (String?) -> Void) {
        #if targetEnvironment(simulator)
        print("Skipping FCM token retrieval on simulator.")
        completion(nil)
        return
        #else
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error retrieving device token: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let token = token else {
                print("Device token is nil.")
                completion(nil)
                return
            }

            completion(token)
        }
        #endif
    }


    func addListenerToDrivers() {
        for i in 0 ..< drivers.count {
            let driver = drivers[i]
            let COLLECTION_USERS = Firestore.firestore().collection("users")
            let driverListener = COLLECTION_USERS.document(driver.id ?? "").addSnapshotListener { [weak self] snapshot, error in
                guard let self = self, let driver = try? snapshot?.data(as: User.self) else { return }
                self.drivers[i].isActive = driver.isActive
                self.drivers[i].coordinates = driver.coordinates
            }

            self.listenersDictionary[driver.id ?? ""] = driverListener
        }
    }

    func addPreOrderTripObserverForPassenger() {
        guard let currentUser = currentUser, currentUser.accountType == .passenger else { return }
        listenersDictionary["passengerPreorders"]?.remove()

        let listener = Firestore.firestore().collection("preorder")
            .whereField("passengerUid", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let change = snapshot?.documentChanges.first,
                      change.type == .added
                        || change.type == .modified else { return }

                guard let trip = try? change.document.data(as: Trip.self) else { return }
                self.trip = trip
                print("DEBUG: Updated trip state is \(trip.state)")
        }

        listenersDictionary["passengerPreorders"] = listener
    }

    func fetchDrivers() {
        Firestore.firestore().collection("users")
            .whereField("accountType", isEqualTo: AccountType.driver.rawValue)
            .getDocuments { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let documents = snapshot?.documents else { return }
                let fetchedDrivers = documents.compactMap { try? $0.data(as: User.self) }
                self.updateNearbyDrivers(from: fetchedDrivers, maxDistance: 1000)
            }
    }

    private func updateNearbyDrivers(from drivers: [User], maxDistance: CLLocationDistance) {
        guard let currentUserLocation = self.userLocation ?? currentUser?.coordinates.toCoordinate(),
              currentUserLocation.isUsableCoordinate else {
            self.drivers = drivers
            self.driverQueue = drivers
            self.addListenerToDrivers()
            return
        }

        let currentLocation = CLLocation(latitude: currentUserLocation.latitude, longitude: currentUserLocation.longitude)
        let nearbyDrivers = drivers
            .map { driver in
                (driver: driver, distance: currentLocation.distance(from: driver.coordinates.toCLLocation()))
            }
            .filter { $0.distance <= maxDistance }
            .sorted { $0.distance < $1.distance }
            .map { $0.driver }

        self.drivers = nearbyDrivers
        self.driverQueue = nearbyDrivers
        self.addListenerToDrivers()
    }

    func fetchNearbyDrivers(withCoordinates coordinates: CLLocationCoordinate2D) {
        let queryBounds = GFUtils.queryBounds(forLocation: coordinates, withRadius: radius)
        didExecuteFetchDrivers = true
        let COLLECTION_USERS = Firestore.firestore().collection("drivers")
        let queries = queryBounds.map { bound -> Query in
            return COLLECTION_USERS
                .order(by: "geohash")
                .start(at: [bound.startValue])
                .end(at: [bound.endValue])
        }

        for query in queries {
            query.getDocuments(completion: getDocumentsCompletion)
        }
    }

    private func getDocumentsCompletion(snapshot: QuerySnapshot?, error: Error?) -> () {
        guard let documents = snapshot?.documents else { return }
        guard let userLocation = userLocation else { return }
        var drivers = [User]()

        documents.forEach { doc in
            guard let driver = try? doc.data(as: User.self), driver.accountType == .driver else { return }
            let coordinates = CLLocation(latitude: driver.coordinates.latitude, longitude: driver.coordinates.longitude)
            let centerPoint = CLLocation(latitude: userLocation.latitude, longitude: userLocation.longitude)

            let distance = GFUtils.distance(from: centerPoint, to: coordinates)

            if distance <= radius {
                drivers.append(driver)
            }
        }

        self.drivers.append(contentsOf: drivers)
        self.driverQueue = self.drivers
        self.addListenerToDrivers()
    }

    func startUpdatingDrivers() {
        driverRefreshTimer?.invalidate()
        driverRefreshTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.fetchOnlineDrivers()
        }
    }

    func fetchOnlineDrivers() {
        guard let currentUserLocation = self.userLocation ?? currentUser?.coordinates.toCoordinate(),
              currentUserLocation.isUsableCoordinate else {
            print("Current user location is not available.")
            return
        }

        let currentUserCLLocation = CLLocation(latitude: currentUserLocation.latitude, longitude: currentUserLocation.longitude)
        Firestore.firestore().collection("users")
            .whereField("accountType", isEqualTo: AccountType.driver.rawValue)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    print("Error fetching online drivers from Firestore: \(error.localizedDescription)")
                    return
                }

                let drivers = snapshot?.documents.compactMap { try? $0.data(as: User.self) } ?? []
                let nearbyDrivers = drivers
                    .map { driver in
                        (driver: driver, distance: currentUserCLLocation.distance(from: driver.coordinates.toCLLocation()))
                    }
                    .filter { $0.distance <= 1000 }
                    .sorted { $0.distance < $1.distance }

                self.drivers = nearbyDrivers.map { $0.driver }
                self.driverQueue = self.drivers
                self.remainingDrivers = nearbyDrivers.map { item in
                    ((item.driver.id ?? item.driver.uid), item.distance)
                }
                self.addListenerToDrivers()
                AppLogger.info("Nearby drivers refreshed.")
            }
    }

    private func reverseGeocode(location: CLLocation) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let placemark = placemarks?.first, let country = placemark.country {
                    continuation.resume(returning: country)
                } else {
                    continuation.resume(throwing: NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to determine country name."]))
                }
            }
        }
    }

    func fetchClosestDriverAndRequestTrip(with rideType: RideType, tripType: TripType, preorderDate: Date? = nil, preorderTime: Date? = nil) {
        guard let currentUserLocation = self.userLocation ?? currentUser?.coordinates.toCoordinate(),
              currentUserLocation.isUsableCoordinate else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user location is not available."]))
            return
        }

        guard !isRequestingDriver else {
            print("DEBUG: Already requesting a driver, ignoring new request")
            return
        }
        isRequestingDriver = true

        let currentUserCLLocation = CLLocation(latitude: currentUserLocation.latitude, longitude: currentUserLocation.longitude)

        reverseGeocodeCoordinate(coordinate: currentUserCLLocation.coordinate) { [weak self] countryName in
            guard let self = self, let countryName = countryName else {
                self?.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to get country name."]))
                self?.isRequestingDriver = false // Reset flag on error
                return
            }

            self.queryDrivers(at: currentUserCLLocation, countryName: countryName, rideType: rideType, tripType: tripType, preorderDate: preorderDate, preorderTime: preorderTime)
        }
    }

    private func queryDrivers(at location: CLLocation, countryName: String, rideType: RideType, tripType: TripType, preorderDate: Date?, preorderTime: Date?) {
        Firestore.firestore().collection("users")
            .whereField("accountType", isEqualTo: AccountType.driver.rawValue)
            .whereField("isActive", isEqualTo: true)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                if let error = error {
                    self.handleError(error)
                    self.isRequestingDriver = false
                    return
                }

                let sortedDrivers = snapshot?.documents
                    .compactMap { document -> (String, CLLocationDistance)? in
                        guard let driver = try? document.data(as: User.self) else { return nil }
                        let distance = location.distance(from: driver.coordinates.toCLLocation())
                        guard distance <= 1000 else { return nil }
                        return ((driver.id ?? driver.uid), distance)
                    }
                    .sorted { $0.1 < $1.1 } ?? []

                let driversWithin300Meters = sortedDrivers.filter { $0.1 <= 300 }
                let driversWithin1000Meters = sortedDrivers.filter { $0.1 > 300 }
                self.handleGeoFireResults(driversWithin300Meters: driversWithin300Meters, driversWithin1000Meters: driversWithin1000Meters, rideType: rideType, tripType: tripType, preorderDate: preorderDate, preorderTime: preorderTime)
            }
    }

    private func handleGeoFireResults(driversWithin300Meters: [(String, CLLocationDistance)], driversWithin1000Meters: [(String, CLLocationDistance)], rideType: RideType, tripType: TripType, preorderDate: Date?, preorderTime: Date?) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if driversWithin300Meters.isEmpty {
                if let firstDriver = driversWithin1000Meters.first {
                    self.remainingDrivers = Array(driversWithin1000Meters.dropFirst())
                    self.fetchDriverDetailsAndRequestTrip(driverUID: firstDriver.0, with: rideType, tripType: tripType, remainingDrivers: self.remainingDrivers, preorderDate: preorderDate, preorderTime: preorderTime)
                } else {
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No drivers found."]))
                    self.isRequestingDriver = false // Reset flag if no drivers found
                }
            } else {
                let closestDrivers = Array(driversWithin300Meters.sorted(by: { $0.1 < $1.1 }).prefix(3))
                self.fetchDriverDetailsFromUsersCollection(closestDrivers: closestDrivers, rideType: rideType, tripType: tripType, preorderDate: preorderDate, preorderTime: preorderTime)
            }
        }
    }

    private func fetchDriverDetailsFromUsersCollection(closestDrivers: [(String, CLLocationDistance)], rideType: RideType, tripType: TripType, preorderDate: Date?, preorderTime: Date?) {
        let COLLECTION_USERS = Firestore.firestore().collection("users")
        var driverDetails: [(String, Int, Double, CLLocationDistance)] = []
        let dispatchGroup = DispatchGroup()

        closestDrivers.forEach { driver in
            dispatchGroup.enter()
            COLLECTION_USERS.document(driver.0).getDocument { document, error in
                defer { dispatchGroup.leave() } // Ensure to leave the dispatch group

                if let error = error {
                    print("DEBUG: Error fetching driver document: \(error)")
                    self.handleError(error)
                    return
                }

                guard let document = document, document.exists else {
                    print("DEBUG: Driver record does not exist.")
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Driver document does not exist."]))
                    return
                }

                guard let data = document.data() else {
                    print("DEBUG: Driver record data is unavailable.")
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Driver document data is nil."]))
                    return
                }

                guard let cancellationCount = data["cancellationCount"] as? Int,
                      let rating = data["Rating"] as? Double else {
                    print("DEBUG: Driver record is missing required matching fields.")
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Driver data is missing required fields."]))
                    return
                }

                driverDetails.append((driver.0, cancellationCount, rating, driver.1))
            }
        }

        dispatchGroup.notify(queue: .main) { [weak self] in
            guard let self = self else { return }
            if driverDetails.isEmpty {
                self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No valid drivers found."]))
                self.isRequestingDriver = false // Reset flag if no valid drivers found
                return
            }

            let sortedDriverDetails = driverDetails.sorted {
                if $0.1 != $1.1 {
                    return $0.1 < $1.1
                } else if $0.2 != $1.2 {
                    return $0.2 > $1.2
                } else {
                    return $0.3 < $1.3
                }
            }

            self.remainingDrivers = sortedDriverDetails.map { ($0.0, $0.3) }

            let firstDriverUID = sortedDriverDetails[0].0
            self.fetchDriverDetailsAndRequestTrip(driverUID: firstDriverUID, with: rideType, tripType: tripType, remainingDrivers: Array(self.remainingDrivers.dropFirst()), preorderDate: preorderDate, preorderTime: preorderTime)
        }
    }

    private func fetchDriverDetailsAndRequestTrip(driverUID: String, with rideType: RideType, tripType: TripType, remainingDrivers: [(String, CLLocationDistance)], preorderDate: Date? = nil, preorderTime: Date? = nil) {
        guard !attemptedDrivers.contains(driverUID) else {
            AppLogger.info("Skipping a driver already attempted for this request.")
            if remainingDrivers.isEmpty {
                print("DEBUG: No remaining drivers, resetting attempted drivers")
                self.attemptedDrivers.removeAll() // Reset the list of attempted drivers
                self.isRequestingDriver = false // Reset flag if no remaining drivers
                self.mapState = .noInput
                self.reset()
                self.resetRequestState()
                self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more drivers available in fetchDriverDetails function."]))
            } else {
                self.fetchDriverDetailsAndRequestTrip(driverUID: remainingDrivers.first!.0, with: rideType, tripType: tripType, remainingDrivers: Array(remainingDrivers.dropFirst()), preorderDate: preorderDate, preorderTime: preorderTime)
            }
            return
        }

        let COLLECTION_USERS = Firestore.firestore().collection("users")
        COLLECTION_USERS.document(driverUID).getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let error = error {
                self.handleError(error)
                self.isRequestingDriver = false // Reset flag on error
                return
            }

            if let document = document, document.exists, let driverData = document.data() {
                guard let driverName = driverData["fullname"] as? String,
                      let driverCoordinates = driverData["coordinates"] as? GeoPoint,
                      let fcmToken = driverData["fcmToken"] as? String else {
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Driver data is incomplete or invalid."]))
                    self.isRequestingDriver = false // Reset flag if driver data is invalid
                    return
                }

                if let platform = driverData["platform"] as? String {
                    print("Driver platform: \(platform)")

                    self.attemptedDrivers.insert(driverUID)

                    if tripType == .now {
                        if platform == "IOS" {
                            self.requestTrip(with: driverUID, driverName: driverName, driverCoordinates: driverCoordinates, rideType: rideType, remainingDrivers: remainingDrivers)
                        } else if platform == "Android" {
                            self.trip = Trip(
                                tripId: UUID().uuidString,
                                passengerUid: self.currentUser?.uid ?? "",
                                driverUid: driverUID,
                                passengerName: self.currentUser?.fullname ?? "",
                                driverName: driverName,
                                passengerLocation: self.currentUser?.coordinates ?? GeoPoint(latitude: 0, longitude: 0),
                                driverLocation: driverCoordinates,
                                pickupLocationName: self.currentTrip?.pickupLocationName ?? "Unknown",
                                dropofflocationName: self.selectedUberLocation?.title ?? "Unknown",
                                pickupLocationAddress: "",
                                pickupLocation: self.currentTrip?.pickupLocation ?? GeoPoint(latitude: 0, longitude: 0),
                                dropoffLocation: GeoPoint(latitude: self.selectedUberLocation?.coordinate.latitude ?? 0, longitude: self.selectedUberLocation?.coordinate.longitude ?? 0),
                                tripCost: self.trip?.tripCost ?? 0,
                                distanceToPassenger: self.trip?.distanceToPassenger ?? 0,
                                travelTimeToPassenger: self.trip?.travelTimeToPassenger ?? 0,
                                state: .requested,
                                tripType: .now,
                                rideType: selectedRideType,
                                tripDate: Date(),
                                driverToken: fcmToken
                            )
                            do {
                                let encodedTrip = try Firestore.Encoder().encode(self.trip)
                                Firestore.firestore().collection("trips").document(self.trip?.tripId ?? "").setData(encodedTrip) { error in
                                    if let error = error {
                                        self.handleError(error)
                                        self.isRequestingDriver = false // Reset flag on error
                                    } else {
                                        print("Trip successfully uploaded to Firestore")
                                        self.listenForTripRejection(trip: self.trip!, remainingDrivers: remainingDrivers)
                                        self.startCountdownTimer(for: self.trip!)
                                    }
                                }
                            } catch {
                                self.handleError(error)
                                self.isRequestingDriver = false // Reset flag on error
                            }
                            self.sendFCMMessage(with: fcmToken)
                        } else {
                            self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown platform: \(platform)"]))
                            self.isRequestingDriver = false // Reset flag on unknown platform
                        }
                    } else if tripType == .preorder {
                        self.startPreorderedTrip(for: driverUID, driverName: driverName, driverCoordinates: driverCoordinates, rideType: rideType, preorderDate: preorderDate, preorderTime: preorderTime, with: fcmToken)
                    } else {
                        self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown trip type: \(tripType)"]))
                        self.isRequestingDriver = false // Reset flag on unknown trip type
                    }
                } else {
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Platform field is missing in driver data."]))
                    self.isRequestingDriver = false // Reset flag on missing platform
                }
            } else {
                self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Driver document does not exist."]))
                self.isRequestingDriver = false // Reset flag if driver document does not exist
            }
        }
    }

    private func resetRequestState() {
        DispatchQueue.main.async { [weak self] in
            self?.isRequestingDriver = false
            self?.isRequestingNextDriver = false
            self?.attemptedDrivers.removeAll() // Ensure the list is reset here as well
        }
    }

    private func requestTrip(with driverUID: String, driverName: String, driverCoordinates: GeoPoint, rideType: RideType, remainingDrivers: [(String, CLLocationDistance)]) {
        guard let dropOffLocation = selectedUberLocation else {
            DispatchQueue.main.async { [weak self] in
                self?.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Drop-off location is not selected."]))
                self?.isRequestingDriver = false
            }
            return
        }

        let dropoffGeopoint = GeoPoint(latitude: dropOffLocation.coordinate.latitude, longitude: dropOffLocation.coordinate.longitude)
        guard let currentUser = currentUser else {
            DispatchQueue.main.async { [weak self] in
                self?.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user is nil."]))
                self?.isRequestingDriver = false
            }
            return
        }

        guard let pickupLocationCoordinate = self.currentTrip?.pickupLocation.toCoordinate() else {
            DispatchQueue.main.async { [weak self] in
                self?.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Pickup location is not set."]))
                self?.isRequestingDriver = false
            }
            return
        }

        reverseGeocodeCoordinate(coordinate: pickupLocationCoordinate) { [weak self] (detailedAddress) in
            guard let self = self else { return }

            let tripCost = self.computeRidePrice(forType: rideType)
            self.getDestinationRouteForAppleMaps(from: pickupLocationCoordinate, to: dropOffLocation.coordinate) { route, expectedTravelTime, distance in
                let distanceInKilometers = distance / 1000

                let trip = Trip(
                    tripId: UUID().uuidString,
                    passengerUid: currentUser.uid,
                    driverUid: driverUID,
                    passengerName: currentUser.fullname,
                    driverName: driverName,
                    passengerLocation: currentUser.coordinates,
                    driverLocation: driverCoordinates,
                    pickupLocationName: self.currentTrip?.pickupLocationName ?? "Unknown",
                    dropofflocationName: dropOffLocation.title ?? "Unknown",
                    pickupLocationAddress: detailedAddress ?? "Current Location",
                    pickupLocation: self.currentTrip?.pickupLocation ?? GeoPoint(latitude: 0, longitude: 0),
                    dropoffLocation: dropoffGeopoint,
                    tripCost: tripCost,
                    distanceToPassenger: distanceInKilometers,
                    travelTimeToPassenger: Int(expectedTravelTime / 60),
                    state: .requested,
                    tripType: .now,
                    tripDate: Date()
                )

                do {
                    let encodedTrip = try Firestore.Encoder().encode(trip)
                    DispatchQueue.main.async {
                        Firestore.firestore().collection("trips").document(trip.tripId!).setData(encodedTrip) { error in
                            if let error = error {
                                self.handleError(error)
                                self.isRequestingDriver = false
                            } else {
                                print("Trip successfully uploaded to Firestore")
                                self.listenForTripRejection(trip: trip, remainingDrivers: remainingDrivers)
                                self.startCountdownTimer(for: trip) // Start the timer only when the trip is requested
                            }
                        }
                    }
                } catch {
                    DispatchQueue.main.async { [weak self] in
                        self?.handleError(error)
                        self?.isRequestingDriver = false
                    }
                }
            }
        }
    }
    func updateTripCostWithDistance() {
          guard var trip = trip, trip.state == .tripCompleted else {
              return
          }

          // Set the trip's cost to the total distance traveled
        trip.tripCost = totalDistanceTraveled
          print("Trip completed. Distance traveled: \(totalDistanceTraveled) km")

          // Reset distance after trip completes
          totalDistanceTraveled = 0.0
      }

      // Function to be called each time you receive a location update during the trip
      func updateDistanceTraveled(from previousLocation: CLLocation, to currentLocation: CLLocation) {
          let distance = previousLocation.distance(from: currentLocation) / 1000 // Convert to kilometers
          totalDistanceTraveled += distance
      }

      // Call this when trip completes

  
    private func reverseGeocodeCoordinate(coordinate: CLLocationCoordinate2D, completion: @escaping (String?) -> Void) {
        let geocoder = CLGeocoder()
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)

        geocoder.reverseGeocodeLocation(location) { (placemarks, error) in
            if let error = error {
                print("Error reverse geocoding: \(error.localizedDescription)")
                completion(nil)
                return
            }

            if let placemark = placemarks?.first, let country = placemark.country {
                completion(country)
            } else {
                completion(nil)
            }
        }
    }

    private func startCountdownTimer(for trip: Trip) {
        countdownTimer?.invalidate() // Ensure any existing timer is invalidated before creating a new one
        tripStartTime = Date()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 20.0, repeats: false) { [weak self] _ in
            self?.handleTimerExpiry(for: trip)
        }
    }

    private func handleTimerExpiry(for trip: Trip) {
        print("DEBUG: Timer expired, rejecting trip")
        self.rejectTripAndRequestNextDriver(trip, remainingDrivers: self.remainingDrivers)
    }

    private func listenForTripRejection(trip: Trip, remainingDrivers: [(String, CLLocationDistance)]) {
        let tripRef = Firestore.firestore().collection("trips").document(trip.tripId!)

        tripRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }

            if let error = error {
                self.handleError(error)
                self.isRequestingDriver = false // Reset flag on error
                return
            }

            guard let snapshot = snapshot, let tripData = try? snapshot.data(as: Trip.self) else {
                self.isRequestingDriver = false // Reset flag if no snapshot
                return
            }

            if tripData.state == .rejected && !self.isRequestingNextDriver {
                self.handleTripRejection(trip)
            } else if tripData.state == .accepted {
                self.countdownTimer?.invalidate()
                self.countdownTimer = nil
                self.tripStartTime = nil
                self.isRequestingNextDriver = false
            }
        }
    }

    private func handleTripRejection(_ trip: Trip) {
        guard !self.isRequestingNextDriver else {
            print("DEBUG: Already requesting the next driver, ignoring duplicate rejection")
            return
        }

        self.isRequestingNextDriver = true

        if !self.remainingDrivers.isEmpty {
            self.rejectTripAndRequestNextDriver(trip, remainingDrivers: self.remainingDrivers)
        } else {
            print("No more drivers available in handleTripRejection")
            self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more drivers available."]))
            self.countdownTimer?.invalidate()
            self.countdownTimer = nil
            self.tripStartTime = nil
            self.resetRequestState()
        }
    }

    private func rejectTripAndRequestNextDriver(_ trip: Trip, remainingDrivers: [(String, CLLocationDistance)]) {
        Firestore.firestore().collection("trips").document(trip.tripId!).delete { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                print("ERROR: Failed to delete trip with ID \(String(describing: trip.tripId)) in 'trips' collection: \(error.localizedDescription)")
                self.isRequestingNextDriver = false
            } else {
                print("DEBUG: Successfully deleted trip with ID \(String(describing: trip.tripId)) in 'trips' collection.")

                if !remainingDrivers.isEmpty {
                    let nextDriver = remainingDrivers.first!
                    self.remainingDrivers = Array(remainingDrivers.dropFirst())
                    
                    // Unwrap `selectedRideType`
                    guard let rideType = self.selectedRideType else {
                        print("ERROR: Selected ride type is nil.")
                        self.resetRequestState()
                        self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No ride type selected."]))
                        return
                    }
                    
                    self.fetchDriverDetailsAndRequestTrip(
                        driverUID: nextDriver.0,
                        with: rideType,
                        tripType: trip.tripType,
                        remainingDrivers: self.remainingDrivers,
                        preorderDate: trip.preOrderDate,
                        preorderTime: trip.preOrderTime
                    )
                } else {
                    print("No more drivers available")
                    self.resetRequestState()
                    self.handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No more drivers available."]))
                    self.isRequestingNextDriver = false
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.tripStartTime = nil
                }
            }
        }
    }

    func addTripObserverForPassenger() {
        guard let currentUser = currentUser, currentUser.accountType == .passenger else { return }
        listenersDictionary["passengerTrips"]?.remove()

        let listener = Firestore.firestore().collection("trips")
            .whereField("passengerUid", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let changes = snapshot?.documentChanges else { return }

                for change in changes {
                    if change.type == .added || change.type == .modified {
                        guard let trip = try? change.document.data(as: Trip.self) else { return }
                        self.trip = trip
                        print("DEBUG: Updated trip state is \(trip.state)")

                        if trip.state == .rejected {
                            DispatchQueue.main.async {
                                self.handleTripRejection(trip)
                            }
                        }
                    }
                }
            }

        listenersDictionary["passengerTrips"] = listener
    }

    private func startPreorderedTrip(for driverUID: String, driverName: String, driverCoordinates: GeoPoint, rideType: RideType, preorderDate: Date?, preorderTime: Date?, with fcmToken: String) {
        guard let currentUser = currentUser else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Current user is nil."]))
            isRequestingDriver = false
            return
        }

        guard let dropOffLocation = selectedUberLocation else {
            handleError(NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Drop-off location is not selected."]))
            isRequestingDriver = false
            return
        }

        let dropoffGeopoint = GeoPoint(latitude: dropOffLocation.coordinate.latitude, longitude: dropOffLocation.coordinate.longitude)

        reverseGeocodeCoordinate(coordinate: dropOffLocation.coordinate) { [weak self] detailedAddress in
            guard let self = self else { return }

            let tripCost = self.computeRidePrice(forType: rideType)
            self.getDestinationRouteForAppleMaps(from: currentUser.coordinates.toCoordinate(), to: dropOffLocation.coordinate) { route, expectedTravelTime, distance in
                let distanceInKilometers = distance / 1000

                let preorderedTrip = Trip(
                    tripId: UUID().uuidString,
                    passengerUid: currentUser.uid,
                    driverUid: driverUID,
                    passengerName: currentUser.fullname,
                    driverName: driverName,
                    passengerLocation: currentUser.coordinates,
                    driverLocation: driverCoordinates,
                    pickupLocationName: self.currentTrip?.pickupLocationName ?? "Unknown",
                    dropofflocationName: dropOffLocation.title ?? "Unknown",
                    pickupLocationAddress: detailedAddress ?? "Current Location",
                    pickupLocation: self.currentTrip?.pickupLocation ?? GeoPoint(latitude: 0, longitude: 0),
                    dropoffLocation: dropoffGeopoint,
                    tripCost: tripCost,
                    distanceToPassenger: distanceInKilometers,
                    travelTimeToPassenger: Int(expectedTravelTime / 60),
                    preOrderDate: preorderDate, preOrderTime: preorderTime, state: .requested,
                    tripType: .preorder,
                    tripDate: Date()
                )

                do {
                    let encodedTrip = try Firestore.Encoder().encode(preorderedTrip)
                    Firestore.firestore().collection("preorder").addDocument(data: encodedTrip) { error in
                        if let error = error {
                            self.handleError(error)
                            self.isRequestingDriver = false
                        } else {
                            print("DEBUG: Preorder trip successfully uploaded to Firestore")
                            self.sendFCMMessageForPreorder(with: fcmToken, with: preorderDate ?? Date())
                        }
                    }
                } catch {
                    self.handleError(error)
                    self.isRequestingDriver = false
                }
            }
        }
    }

    func sendFCMMessageForPreorder(with Token: String, with tripDate: Date) {
        guard let serverKey = AppConfig.legacyFCMServerKey else {
            AppLogger.warning("Legacy FCM server key is not configured. Route notifications through the backend before App Store release.")
            return
        }
        let endpoint = AppConfig.legacyFCMEndpoint
        let driverToken = Token

        guard let trip = trip else {
            print("Trip is nil, cannot proceed")
            return
        }

        let notificationData: [String: Any] = [
            "title": "RequestDriver",
            "body": "This message represents a request driver action",
            "RiderKey": trip.passengerUid,
            "PickupLocationString": trip.pickupLocationName,
            "PickupLocation": "\(trip.pickupLocation.latitude),\(trip.pickupLocation.longitude)",
            "DestinationLocationString": trip.dropofflocationName,
            "DestinationLocation": "\(trip.dropoffLocation.latitude),\(trip.dropoffLocation.longitude)",
            "DistanceText": "\(trip.distanceToPassenger)",
            "DistanceValue": "\(trip.travelTimeToPassenger)",
            "DurationText": "\(trip.travelTimeToPassenger)",
            "TimeValue": "600",
            "TotalFee": "\(trip.tripCost.rounded())",
            "timeText":"2023-10-28 12:00:00",
            "tripType": "pre_order",
            "FaysTripKey": trip.id,
            "platform": "IOS"
        ]

        let payload: [String: Any] = [
            "to": driverToken,
            "data": notificationData
        ]

        guard let url = URL(string: endpoint),
              let jsonPayload = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonPayload

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error sending FCM message: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = responseData["success"] as? Int, success == 1 {
                        AppLogger.info("Successfully sent FCM message.")
                    } else {
                        AppLogger.warning("Failed to send FCM message.")
                    }
                } catch {
                    print("Error parsing response JSON: \(error)")
                }
            } else {
                print("HTTP Error: Status code is not 200")
            }
        }

        task.resume()
    }

    func fetchDriverFCMToken(driverUID: String, completion: @escaping (String?) -> Void) {
        let COLLECTION_USERS = Firestore.firestore().collection("users")
        COLLECTION_USERS.document(driverUID).getDocument { document, error in
            if let error = error {
                print("Error fetching driver document: \(error)")
                completion(nil)
                return
            }

            if let document = document, document.exists {
                let fcmToken = document.data()?["fcmToken"] as? String
                completion(fcmToken)
            } else {
                completion(nil)
            }
        }
    }

    func sendFCMMessageNotfication(for tripState: TripState, to token: String, trip: Trip) {
        guard let serverKey = AppConfig.legacyFCMServerKey else {
            AppLogger.warning("Legacy FCM server key is not configured. Route notifications through the backend before App Store release.")
            return
        }
        let endpoint = AppConfig.legacyFCMEndpoint

        let notificationData: [String: Any] = [
            "title": "Trip \(tripState)",
            "body": "The trip has been \(tripState.rawValue)",
            "tripId": trip.tripId ?? "",
            "tripState": tripState.rawValue
        ]

        let payload: [String: Any] = [
            "to": token,
            "data": notificationData
        ]

        guard let url = URL(string: endpoint),
              let jsonPayload = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonPayload

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error sending FCM message: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = responseData["success"] as? Int, success == 1 {
                        AppLogger.info("Successfully sent FCM message.")
                    } else {
                        AppLogger.warning("Failed to send FCM message.")
                    }
                } catch {
                    print("Error parsing response JSON: \(error)")
                }
            } else {
                print("HTTP Error: Status code is not 200")
            }
        }

        task.resume()
    }

    func sendFCMMessage(with Token: String) {
        guard let serverKey = AppConfig.legacyFCMServerKey else {
            AppLogger.warning("Legacy FCM server key is not configured. Route notifications through the backend before App Store release.")
            return
        }
        let endpoint = AppConfig.legacyFCMEndpoint
        let driverToken = Token

        guard let trip = trip else {
            print("Trip is nil, cannot proceed")
            return
        }

        let notificationData: [String: Any] = [
            "title": "RequestDriver",
            "body": "This message represents a request driver action",
            "RiderKey": trip.passengerUid,
            "PickupLocationString": trip.pickupLocationName,
            "PickupLocation": "\(trip.pickupLocation.latitude),\(trip.pickupLocation.longitude)",
            "DestinationLocationString": trip.dropofflocationName,
            "DestinationLocation": "\(trip.dropoffLocation.latitude),\(trip.dropoffLocation.longitude)",
            "DistanceText": "\(trip.distanceToPassenger)",
            "DistanceValue": "\(trip.travelTimeToPassenger)",
            "DurationText": "\(trip.travelTimeToPassenger)",
            "TimeValue": "600",
            "TotalFee": "\(trip.tripCost.rounded())",
            "timeText": "2023-10-28 12:00:00",
            "tripType": "now",
            "FaysTripKey": trip.id,
            "platform": "IOS"
        ]

        let payload: [String: Any] = [
            "to": driverToken,
            "data": notificationData
        ]

        guard let url = URL(string: endpoint),
              let jsonPayload = try? JSONSerialization.data(withJSONObject: payload) else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonPayload

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error sending FCM message: \(error?.localizedDescription ?? "Unknown error")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                do {
                    if let responseData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let success = responseData["success"] as? Int, success == 1 {
                        AppLogger.info("Successfully sent FCM message.")
                    } else {
                        AppLogger.warning("Failed to send FCM message.")
                    }
                } catch {
                    print("Error parsing response JSON: \(error)")
                }
            } else {
                print("HTTP Error: Status code is not 200")
            }
        }

        task.resume()
    }

    func cancelTripAsPassenger() {
        updateTripState(state: .passengerCancelled)
        
        DispatchQueue.main.async { [weak self] in
            self?.alertItem = AlertItem(
                title: Text("Trip Cancelled"),
                message: Text("You have successfully cancelled the trip."),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

extension HomeViewModel {
    func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    func addTripObserverForDriver() {
        guard let currentUser = currentUser, currentUser.accountType == .driver else { return }

        Firestore.firestore().collection("trips")
            .whereField("driverUid", isEqualTo: currentUser.uid)
            .addSnapshotListener { [weak self] snapshot, _ in
                guard let self = self else { return }
                guard let change = snapshot?.documentChanges.first,
                      change.type == .added || change.type == .modified,
                      let trip = try? change.document.data(as: Trip.self) else {
                    return
                }

                DispatchQueue.main.async {
                    self.trip = trip
                    print("DEBUG: Updated trip state is \(trip.state)")
                    self.getDestinationRouteForAppleMaps(
                        from: trip.driverLocation.toCoordinate(),
                        to: trip.pickupLocation.toCoordinate()
                    ) { route, travelTime, distance in
                        self.routeToPickupLocation = route
                        self.trip?.travelTimeToPassenger = Int(travelTime / 60)
                        self.trip?.distanceToPassenger = distance
                    }
                }
            }
    }


    func rejectTrip() {
        updateTripState(state: .rejected)
    }

    func acceptTrip() {
        updateTripState(state: .accepted)
    }

    func cancelTripAsDriver() {
        updateTripState(state: .driverCancelled)
    }
    
    func tripArrived() {
        updateTripState(state: .arrived)
    }
    func completeTrip() {
        // Update trip cost using the method from Trip model
        if var trip = self.trip {
            trip.updateCost(with: totalDistanceTraveled)
            self.trip = trip // Reassign to reflect the changes
            print("Trip completed. Total distance traveled: \(totalDistanceTraveled) km")
        }

        // Update trip state to completed
        updateTripState(state: .tripCompleted)
        
        // Change the map state to reflect that the trip has been completed
        DispatchQueue.main.async {
            self.mapState = .tripCompleted
        }
        
        // Reset total distance traveled after the trip is complete
        totalDistanceTraveled = 0.0
    }



    func noTrip() {
        updateTripState(state: .noTrip)
    }

    func preordered() {
        updateTripState(state: .preorder )
    }
}

extension HomeViewModel {
    func addressFromPlacemark(_ placemark: CLPlacemark) -> String {
        return [
            placemark.name,
            placemark.locality,
            placemark.administrativeArea,
            placemark.country
        ].compactMap { $0 }.joined(separator: ", ")
    }

    private func getPlacemark(forLocation location: CLLocation, completion: @escaping (CLPlacemark?, Error?) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { placemarks, error in
            if let error = error {
                completion(nil, error)
            } else {
                completion(placemarks?.first, nil)
            }
        })
    }

    func setDefaultStartLocation() {
        guard let currentLocation = locationManager.userLocation else { return }
        geocodeLocation(location: currentLocation) { [weak self] address in
            guard let self = self else { return }
            self.startLocationQuery = address
            self.currentTrip?.pickupLocation = GeoPoint(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
            self.currentTrip?.pickupLocationName = address
            self.currentTrip?.pickupLocationAddress = address
        }
    }

    func setPickupLocationToCurrentLocation() {
        guard let currentLocation = locationManager.userLocation else { return }
        geocodeLocation(location: currentLocation) { [weak self] address in
            guard let self = self else { return }
            self.startLocationQuery = address
            self.currentTrip?.pickupLocation = GeoPoint(latitude: currentLocation.coordinate.latitude, longitude: currentLocation.coordinate.longitude)
            self.currentTrip?.pickupLocationName = address
            self.currentTrip?.pickupLocationAddress = address
        }
    }

    private func geocodeLocation(location: CLLocation, completion: @escaping (String) -> Void) {
        CLGeocoder().reverseGeocodeLocation(location) { placemarks, _ in
            completion(placemarks?.first?.formattedAddress ?? "Current Location")
        }
    }

    func fetchPlaces(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 1 else {
            results = []
            return
        }
        searchCompleter.queryFragment = trimmed
    }

    func selectStartLocation(_ prediction: MKLocalSearchCompletion) {
        resolveCompletion(prediction) { [weak self] mapItem in
            guard let self = self, let mapItem = mapItem else { return }
            let coordinate = mapItem.placemark.coordinate
            let locationName = mapItem.name ?? prediction.title
            self.startLocationQuery = locationName

            if var trip = self.currentTrip {
                trip.pickupLocationName = locationName
                trip.pickupLocationAddress = mapItem.placemark.formattedAddress
                self.currentUser?.coordinates = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                trip.pickupLocation = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                trip.passengerLocation = GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude)
                self.currentTrip = trip
            } else {
                self.currentTrip = Trip(
                    tripId: nil,
                    passengerUid: "",
                    driverUid: "",
                    passengerName: "",
                    driverName: "",
                    passengerLocation: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    driverLocation: GeoPoint(latitude: 0, longitude: 0),
                    pickupLocationName: locationName,
                    dropofflocationName: "",
                    pickupLocationAddress: mapItem.placemark.formattedAddress,
                    pickupLocation: GeoPoint(latitude: coordinate.latitude, longitude: coordinate.longitude),
                    dropoffLocation: GeoPoint(latitude: 0, longitude: 0),
                    tripCost: 0.0,
                    distanceToPassenger: 0.0,
                    travelTimeToPassenger: 0,
                    state: .requested,
                    tripType: .now,
                    rideType: self.selectedRideType,
                    tripDate: nil,
                    timestamp: nil
                )
            }
        }
    }

    func selectDestinationLocation(_ prediction: MKLocalSearchCompletion) {
        resolveCompletion(prediction) { [weak self] mapItem in
            guard let self = self, let mapItem = mapItem else { return }
            self.selectedUberLocation = UberLocation(title: mapItem.name ?? prediction.title, coordinate: mapItem.placemark.coordinate)
            self.destinationQuery = mapItem.name ?? prediction.title
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

        guard tripDistanceInMeters >= 0 else { return 0.0 }

        return type.computePrice(for: tripDistanceInMeters)
    }

    func createPickupAndDropoffRegionsForTrip() {
        guard let trip = trip else { return }
        LocationManager.shared.createPickupRegionForTrip(trip)
        LocationManager.shared.createDropoffRegionForTrip(trip)
    }

    func getDestinationRouteForAppleMaps(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D, completion: @escaping (MKPolyline?, TimeInterval, Double) -> Void) {
        AppleMapsRouting.route(from: from, to: to) { route in
            completion(route?.polyline, route?.expectedTravelTime ?? 0, route?.distance ?? 0)
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        DispatchQueue.main.async {
            self.results = completer.results
        }
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        AppLogger.error("Apple Maps autocomplete failed: \(error.localizedDescription)")
    }

    func configurePickupAndDropoffTimes(with expectedTravelTime: Double) {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        pickUpTime = formatter.string(from: Date())
        dropOffTime = formatter.string(from: Date() + expectedTravelTime)
    }

    func saveCompletedTrip(_ trip: Trip) {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("User not authenticated.")
            return
        }

        guard let tripId = trip.tripId else {
            print("Trip ID is nil.")
            return
        }

        do {
            let encodedTrip = try Firestore.Encoder().encode(trip)

            Firestore.firestore().collection("users")
                .document(uid)
                .collection("user-trips")
                .document(tripId)
                .setData(encodedTrip) { [weak self] error in
                    guard let self = self else { return }
                    if let error = error {
                        print("Error saving trip data: \(error.localizedDescription)")
                    } else {
                        self.mapState = .noInput
                        print("Trip data saved successfully.")
                    }
                }
        } catch {
            print("Error encoding trip data: \(error.localizedDescription)")
        }
    }
}

extension HomeViewModel: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        userLocation = location.coordinate
        
        DispatchQueue.main.async {
            self.updateCurrentLocationName(location: location)
        }
    }
    
    private func updateCurrentLocationName(location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] (placemarks, error) in
            guard let self = self else { return }
            if let placemark = placemarks?.first {
                DispatchQueue.main.async {
                    self.startLocationText = [
                        placemark.name,
                        placemark.locality,
                        placemark.administrativeArea,
                        placemark.country
                    ].compactMap { $0 }.joined(separator: ", ")
                }
            }
        }
    }
}
enum LocationFieldType {
    case start
    case destination
}
