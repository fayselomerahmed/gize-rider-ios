//
//  GeoPoint.swift
//  GizeTransport
//
//  Created by User on 6/24/23.
//

import Firebase
import CoreLocation
import FirebaseFirestore

extension GeoPoint {
    func toCoordinate() -> CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
    }

    func toCLLocation() -> CLLocation {
        return CLLocation(latitude: self.latitude, longitude: self.longitude)
    }
}

extension CLLocationCoordinate2D {
    var isUsableCoordinate: Bool {
        CLLocationCoordinate2DIsValid(self)
        && latitude.isFinite
        && longitude.isFinite
        && !(abs(latitude) < 0.0001 && abs(longitude) < 0.0001)
    }
}
