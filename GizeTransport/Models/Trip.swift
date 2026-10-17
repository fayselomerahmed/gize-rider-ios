//
//  Trip.swift
//  GizeTransport
//
//  Created by User on 6/6/23.
//




import Firebase
import FirebaseFirestoreSwift
import CoreLocation

enum TripState: Int , Codable {
    case requested
    case rejected
    case accepted
    case arrived
    case noTrip
    case passengerCancelled
    case driverCancelled
    case starttrip
    case tripCompleted
    case preorder
    case preordersuccesful
    
}

enum TripType: Int , Codable {
    case now
    case preorder
    
}
struct Trip: Codable, Identifiable  {
    @DocumentID var tripId: String?
    let passengerUid: String
    let driverUid: String
    let passengerName: String
    let driverName: String
    var passengerLocation: GeoPoint?
    let driverLocation: GeoPoint
    var pickupLocationName: String
    var dropofflocationName: String
    var pickupLocationAddress: String
    var pickupLocation: GeoPoint
    var dropoffLocation: GeoPoint
    var tripCost: Double
    var distanceToPassenger: Double
    var travelTimeToPassenger: Int
    var preOrderDate: Date?
    var preOrderTime: Date?
    var state : TripState
    var tripType: TripType
    var rideType: RideType?
    var tripDate: Date?
    var timestamp: Timestamp?
    var driverToken: String?
    var platform: String = "IOS"
    var dropoffLocationCoordinates: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: dropoffLocation.latitude, longitude: dropoffLocation.longitude)
    }
    
    var pickupLocationCoordiantes: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: pickupLocation.latitude, longitude: pickupLocation.longitude)
    }
    
    var dropoffUberLocation: UberLocation {
        return UberLocation(title: dropofflocationName, coordinate: dropoffLocationCoordinates)
    }
    
    var passengerFirstNameUppercased: String {
        let components = passengerName.components(separatedBy: " ")
        guard let firstName = components.first else { return passengerName.uppercased() }
        
        return firstName.uppercased()
    }
    // Use a computed property to get the ID, avoiding setting it manually
    var id: String {
        return tripId ?? ""
    }
    mutating func updateCost(with distance: Double) {
        self.tripCost = distance
    }
}




