//
//  DriverAnnotation.swift
//  GizeTransport
//
//  Created by User on 5/29/23.
//
import MapKit
import Firebase

class DriverAnnotation: NSObject, MKAnnotation {
   @objc dynamic var coordinate: CLLocationCoordinate2D
    let uid: String
    
    init(uid: String, coordinate: CLLocationCoordinate2D) {
        self.uid = uid
        self.coordinate = coordinate
    }
    
    func updatePosition(withCoordinate newCoordinate: CLLocationCoordinate2D) {
        // Check if the new coordinate is different from the current coordinate
        guard newCoordinate.latitude != coordinate.latitude || newCoordinate.longitude != coordinate.longitude else {
            // The coordinates are the same, no need to update
            return
        }

        // Update the coordinate with animation

            self.coordinate = newCoordinate
        
    }

    
}


