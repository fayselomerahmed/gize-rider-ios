//
//  RideType.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/22/22.
//

import FirebaseFirestore

struct RideType: Identifiable, Equatable, Codable {
    
    let id: Int
    let name: String
    let description: String
    let baseFare: Double
    let perKilometerRate: Double
    let imageName: String

    static func == (lhs: RideType, rhs: RideType) -> Bool {
        return lhs.id == rhs.id
    }


    init(id: Int, name: String, description: String, baseFare: Double, perKilometerRate: Double, imageName: String) {
        self.id = id
        self.name = name
        self.description = description
        self.baseFare = baseFare
        self.perKilometerRate = perKilometerRate
        self.imageName = imageName
    }

    static func fetchRideTypes(completion: @escaping ([RideType]) -> Void) {
        let db = Firestore.firestore()
        db.collection("RideTypes").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching ride types: \(error)")
                completion([])
                return
            }

            guard let documents = snapshot?.documents else {
                completion([])
                return
            }

            let rideTypes = documents.compactMap { document -> RideType? in
                guard
                    let id = document["id"] as? Int,
                    let name = document["name"] as? String,
                    let description = document["description"] as? String,
                    let baseFare = document["baseFare"] as? Double,
                    let perKilometerRate = document["perKilometerRate"] as? Double,
                    let imageName = document["imageName"] as? String
                else {
                    return nil
                }
                return RideType(
                    id: id,
                    name: name,
                    description: description,
                    baseFare: baseFare,
                    perKilometerRate: perKilometerRate,
                    imageName: imageName
                )
            }

            completion(rideTypes)
        }
    }

    func computePrice(for distanceInMeters: Double) -> Double {
        let distanceInKilometers = distanceInMeters / 1000.0
        return (distanceInKilometers * perKilometerRate) + baseFare
    }
}

//    func handleRide(image: UIImage, distance: Double, completion: @escaping (Error?) -> Void) {
//        FirebaseService.shared.uploadImage(image) { result in
//            switch result {
//            case .success(let imageURL):
//                FirebaseService.shared.storeRideData(imageURL: imageURL, rideType: self, distance: distance) { error in
//                    completion(error)
//                }
//            case .failure(let error):
//                completion(error)
//            }
//        }
//    }

class RideTypeViewModel: ObservableObject {
    @Published var rideTypes: [RideType] = []

    func loadRideTypes() {
        RideType.fetchRideTypes { [weak self] fetchedRideTypes in
            DispatchQueue.main.async {
                self?.rideTypes = fetchedRideTypes
            }
        }
    }
}
extension RideType {
    static var defaultRideType: RideType {
        return RideType(id: 0, name: "Default", description: "Default ride", baseFare: 0.0, perKilometerRate: 0.0, imageName: "defaultImage")
    }
}
