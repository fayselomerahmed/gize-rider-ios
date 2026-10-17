//
//  FirebaseService.swift
//  GizeTransport
//
//  Created by User on 5/27/24.
//

import Foundation
//import FirebaseStorage
import FirebaseFirestore

class FirebaseService {
    
    static let shared = FirebaseService()
    
//    private let storageRef: StorageReference = {
//        guard let storage = Storage.storage().reference() else {
//            fatalError("Firebase Storage is not configured correctly.")
//        }
//        return storage
//    }()
    
    private let firestore = Firestore.firestore()
    
//    func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
//        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
//            completion(.failure(NSError(domain: "Invalid image data", code: -1, userInfo: nil)))
//            return
//        }
//        
//        let imageRef = storageRef.child("images/\(UUID().uuidString).jpg")
//        
//        imageRef.putData(imageData, metadata: nil) { metadata, error in
//            if let error = error {
//                completion(.failure(error))
//                return
//            }
//            
//            imageRef.downloadURL { url, error in
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let url = url else {
//                    completion(.failure(NSError(domain: "Invalid URL", code: -1, userInfo: nil)))
//                    return
//                }
//                
//                completion(.success(url.absoluteString))
//            }
//        }
//    }
    
    func storeRideData(imageURL: String, rideType: RideType, distance: Double, completion: @escaping (Error?) -> Void) {
        let price = rideType.computePrice(for: distance)
        
        let rideData: [String: Any] = [
            "imageURL": imageURL,
            "rideType": rideType.description,
            "price": price,
            "timestamp": Date().timeIntervalSince1970
        ]
        
        firestore.collection("rides").addDocument(data: rideData) { error in
            completion(error)
        }
    }
    
    func fetchInitialTarifs(completion: @escaping (Result<[String: Double], Error>) -> Void) {
        firestore.collection("appConfig").document("InitialTarif").getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let value = snapshot?.data() as? [String: Double] else {
                completion(.failure(NSError(domain: "Invalid data format", code: -1, userInfo: nil)))
                return
            }
            completion(.success(value))
        }
    }
    
    func fetchRates(for time: Date, completion: @escaping (Result<[String: [String: Double]], Error>) -> Void) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let timeOfDay = (hour >= 22 || hour < 6) ? "night" : "day"
        
        firestore.collection("appConfig").document("VehicleType").getDocument { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let vehicleType = snapshot?.data(),
                  let value = vehicleType[timeOfDay] as? [String: [String: Double]] else {
                completion(.failure(NSError(domain: "Invalid data format", code: -1, userInfo: nil)))
                return
            }
            completion(.success(value))
        }
    }
}
