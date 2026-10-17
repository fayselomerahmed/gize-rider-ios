//
//  UserService.swift
//  GizeTransport
//
//  Created by User on 6/1/23.
//


import Firebase
import SwiftUI
import FirebaseFirestoreSwift

class UserService: ObservableObject {

    static let shared = UserService()
    @Published var user: User?
    @Published var error: Error?
    @Published var isAuthenticated = false
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false

    private init() {
        DispatchQueue.main.async {
            print("DEBUG: Did init user service")
            self.loadUserFromCache()
            self.fetchUser()
        }
    }

    func sendVerificationCode(toPhoneNumber phoneNumber: String, completion: @escaping (Error?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(error)
            } else {
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                completion(nil)
            }
        }
    }

    func verifyPhoneNumber(verificationCode: String, completion: @escaping (Error?) -> Void) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            completion(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Missing verification ID"]))
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            if let error = error {
                completion(error)
            } else {
                self?.fetchUser()
                self?.isAuthenticated = true
                completion(nil)
            }
        }
    }

    func loadUserFromCache() {
        if let data = UserDefaults.standard.data(forKey: "cachedUser"),
           let cachedUser = try? JSONDecoder().decode(User.self, from: data) {
            self.user = cachedUser
            self.isAuthenticated = true
        }
    }

    func cacheUser(_ user: User) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: "cachedUser")
        }
    }

    func fetchUser() {
        guard let uid = Auth.auth().currentUser?.uid else {
            print("DEBUG: No current user ID")
            return
        }

        DispatchQueue.main.async {
            self.isLoading = true
        }

        Firestore.firestore().collection("users").document(uid).getDocument { [weak self] snapshot, error in
            DispatchQueue.main.async {
                self?.isLoading = false
            }

            if let error = error {
                DispatchQueue.main.async {
                    print("DEBUG: Error fetching user from Firestore: \(error.localizedDescription)")
                    self?.handleError(error)
                }
                return
            }

            guard let snapshot = snapshot, snapshot.exists else {
                DispatchQueue.main.async {
                    print("DEBUG: User document does not exist in Firestore")
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "User document does not exist in Firestore"])
                    self?.handleError(error)
                }
                return
            }

            do {
                let user = try snapshot.data(as: User.self)
                DispatchQueue.main.async {
                    self?.user = user
                    self?.cacheUser(user)
                    self?.isAuthenticated = true
                    AppLogger.info("Passenger account loaded.")
                }
            } catch {
                DispatchQueue.main.async {
                    print("DEBUG: Error decoding user data from Firestore: \(error.localizedDescription)")
                    self?.handleError(error)
                }
            }
        }
    }

    func handleError(_ error: Error) {
        DispatchQueue.main.async {
            self.error = error
            self.user = nil
            self.isAuthenticated = false
            self.showAlert = true
            self.logOutUser()
        }
    }

    func logOutUser() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.user = nil
                self.isAuthenticated = false
                print("DEBUG: User has been logged out")
            }
        } catch let signOutError as NSError {
            DispatchQueue.main.async {
                print("DEBUG: Error signing out: \(signOutError.localizedDescription)")
                self.error = signOutError
            }
        }
    }
}
