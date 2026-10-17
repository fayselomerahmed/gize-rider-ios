//
//  SavedLocation.swift
//  GizeTransport
//
//  Created by User on 4/4/23.
//

import Foundation
//import FirebaseFirestore
import Firebase

struct SavedLocation: Codable {
    let title: String
    let address: String
    let coordinates: GeoPoint
    init(title: String, address: String, coordinates: GeoPoint) {
        self.title = title
        self.address = address
        self.coordinates = coordinates
    }
}
