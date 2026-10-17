////
////  TripSerivice.swift
////  GizeTransport
////
////  Created by User on 10/14/23.
////
//
//import Firebase
//
//struct TripService {
//    
//    // MARK: - Properties
//    
//    var trip: Trip?
//    var user: User?
//        
//    // MARK: - Helpers
//    
//    private func updateTripState(_ trip: Trip, state: TripState, completion: ((Error?) -> Void)? = nil) {
//        Firestore.firestore().collection("rides").document(trip.tripId!).updateData(["tripState": state.rawValue], completion: completion)
//    }
//    
//    private func deleteTrip(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        Firestore.firestore().collection("rides").document(trip.tripId!).delete(completion: completion)
//    }
//}
//
//// MARK: - Driver API
//
//extension TripService {
//    func addTripObserverForDriver(listener: @escaping (QuerySnapshot?, Error?) -> Void) {
//        guard let currentUser = user, currentUser.accountType == .driver, let uid = currentUser.uid else { return }
//        Firestore.firestore().collection("rides").whereField("driverUid", isEqualTo: uid).addSnapshotListener(listener)
//    }
//    
//    func acceptTrip(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        guard let user = user, user.accountType == .driver else { return }
//                
//        COLLECTION_RIDES.document(trip.tripId).updateData(["tripState": MapViewState.tripAccepted.rawValue], completion: completion)
//    }
//    
//    func rejectTrip(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .rejectedByDriver, completion: completion)
//    }
//    
//    func didArriveAtPickupLocation(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .driverArrived, completion: completion)
//    }
//    
//    func didArriveAtDropffLocation(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .arrivedAtDestination, completion: completion)
//    }
//    
//    func pickupPassenger(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .inProgress, completion: completion)
//    }
//    
//    func dropoffPassenger(completion: ((Error?) -> Void)? = nil) {
//        guard let trip = trip else { return }
//        updateTripState(trip, state: .complete, completion: completion)
//    }
//}
//
//// MARK: - Passenger API
//
//extension TripService {
//    //TODO: Refactor passenger api code from HomeViewModel to here
//}
