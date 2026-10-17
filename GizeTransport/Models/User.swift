//
//  User.swift
//  GizeTransport
//
//  Created by User on 4/2/23.
//

import FirebaseFirestoreSwift
import Firebase
import CoreLocation

enum AccountType: Int, Codable {
    case passenger
    case driver
}

struct User: Codable {
    @DocumentID var id: String? // Managed by Firestore when fetching data
    var fullname: String
//    var lastname: String
    var email: String
    let uid: String
    var coordinates: GeoPoint 
    var accountType: AccountType
    var homeLocation: SavedLocation?
    var workLocation: SavedLocation?
    var isActive: Bool?
    var phonenumber: String?
    var platform : String = "IOS"
    var profileImageUrl: String = ""

}
struct Driver: Codable {
    var uid: String
    var fullname: String
    var coordinates: GeoPoint
    var accountType: AccountType
    var cancellationCount: Int
    var rating: Double
    var fcmToken: String
    var platform: String
    // other driver-specific properties
}
