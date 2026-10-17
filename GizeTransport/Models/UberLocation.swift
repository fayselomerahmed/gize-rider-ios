//
//  UberLocation.swift
//  GizeTransport
//
//  Created by User on 6/21/23.
//

import CoreLocation

struct UberLocation : Identifiable {
    let id = NSUUID().uuidString
    let title: String
    let coordinate: CLLocationCoordinate2D
}
