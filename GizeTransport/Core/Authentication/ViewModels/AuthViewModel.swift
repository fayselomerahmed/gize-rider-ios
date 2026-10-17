//
//  AuthViewModel.swift
//  GizeTransport
//
//  Created by User on 3/30/23.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import FirebaseFirestoreSwift
import SwiftUI
import FirebaseMessaging

class AuthViewModel: ObservableObject {
    weak var viewController: UIViewController?
    @Published private(set) var userSession: FirebaseAuth.User?
    @Published private(set) var currentUser: User?
    @Published var isLoggingIn: Bool = false
    private var cancellables = Set<AnyCancellable>()
    private let service = UserService.shared
    @Published private(set) var isAuthenticated = false
    @Published var user: User?
    @Published var isLoading: Bool = false
    var authChanges = PassthroughSubject<Bool, Never>()

    init() {
        userSession = Auth.auth().currentUser
        fetchUser()
        setupAuthListener()
    }

    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.userSession = user
                self.authChanges.send(user != nil)
                if let user = user {
                    self.fetchUserDetails(firebaseUser: user)
                } else {
                    self.currentUser = nil
                }
            }
        }
    }

    private func fetchUserDetails(firebaseUser: FirebaseAuth.User?) {
        guard let firebaseUser = firebaseUser else {
            self.currentUser = nil
            return
        }

        let db = Firestore.firestore()
        let docRef = db.collection("users").document(firebaseUser.uid)

        docRef.getDocument { [weak self] (document, error) in
            guard let self = self else { return }
            guard let document = document, document.exists else {
                print("Document does not exist")
                self.currentUser = nil
                return
            }
            do {
                self.currentUser = try document.data(as: User.self)
            } catch {
                print("Error decoding user: \(error)")
                self.currentUser = nil
            }
        }
    }

    func signInWithPhoneNumber(_ phoneNumber: String) {
        self.isLoading = true
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] (verificationID, error) in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                print("Verification error: \(error.localizedDescription)")
                return
            }
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            print("Verification code sent successfully.")
            self.fetchUser()
        }
    }

    func verifyPhoneNumber(verificationCode: String, completion: @escaping (Bool) -> Void) {
        self.isLoading = true
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            print("Verification ID not found")
            self.isLoading = false
            return
        }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { [weak self] (authResult, error) in
            guard let self = self else { return }
            self.isLoading = false
            if let error = error {
                print("Error signing in: \(error.localizedDescription)")
                completion(false)
                return
            }

            // Successful login, now update the FCM token
            self.updateFCMToken()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isAuthenticated = true
                completion(true)
            }
            self.userSession = authResult?.user
            self.fetchUser()
        }
    }



    func sendVerificationCode(toPhoneNumber phoneNumber: String, completion: @escaping (Error?) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { verificationID, error in
            if let error = error {
                completion(error)
                return
            }
            UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
            completion(nil)
        }
    }

    func registerUser(phoneNumber: String, fullName: String, accountType: AccountType, completion: @escaping (Bool) -> Void) {
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil) { [weak self] verificationID, error in
            guard let self = self else { return }
            if let error = error {
                print("Phone verification failed: \(error.localizedDescription)")
                self.showAlert(message: "Phone verification failed: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let verificationID = verificationID {
                UserDefaults.standard.set(verificationID, forKey: "authVerificationID")
                UserDefaults.standard.set(fullName, forKey: "pendingFullName")
                UserDefaults.standard.set(accountType.rawValue, forKey: "pendingAccountType")
                print("Verification code sent successfully.")
                self.showAlert(message: "Verification code sent to your phone.")
                completion(true)
            } else {
                self.showAlert(message: "Failed to obtain verification ID.")
                completion(false)
            }
        }
    }


    func verifyRegistration(verificationCode: String, coordinates: GeoPoint, fullName: String, email: String) {
        guard let verificationID = UserDefaults.standard.string(forKey: "authVerificationID") else {
            showAlert(message: "Verification ID not found. Please start over the registration process.")
            return
        }

        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID, verificationCode: verificationCode)
        
        Auth.auth().signIn(with: credential) { [weak self] authResult, error in
            guard let self = self else { return }
            if let error = error {
                self.showAlert(message: "Failed to register user: \(error.localizedDescription)")
                return
            }
            guard let user = authResult?.user else {
                self.showAlert(message: "User data not available after authentication.")
                return
            }
            
            let profileImageUrl = "https://example.invalid/default-avatar.png"

            let newUser = User(
                fullname: fullName,
                email: email,
                uid: user.uid,
                coordinates: coordinates,
                accountType: .passenger,
                isActive: true,
                phonenumber: user.phoneNumber,
                profileImageUrl: profileImageUrl
            )
            
            do {
                try Firestore.firestore().collection("users").document(user.uid).setData(from: newUser)

                // Ensure FCM Token is requested immediately after registration
                DispatchQueue.main.async {
                    self.updateFCMToken() // Fetch and save the FCM token
                }
            } catch {
                print("Error saving user to Firestore: \(error.localizedDescription)")
            }
        }
    }


    private func showAlert(message: String) {
        guard let viewController = viewController else { return }
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func requestFCMToken() {
        #if targetEnvironment(simulator)
        AppLogger.info("Skipping FCM token fetch on Simulator.")
        return
        #else
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                AppLogger.info("Notification token refreshed.")
                self?.saveFCMToken(token)
            }
        }
        #endif
    }
    
    func updateFCMToken() {
        #if targetEnvironment(simulator)
        AppLogger.info("Skipping FCM token update on Simulator.")
        return
        #else
        Messaging.messaging().token { [weak self] token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
            } else if let token = token {
                AppLogger.info("Notification token refreshed.")
                self?.saveFCMToken(token)
            }
        }
        #endif
    }

    private func saveFCMToken(_ token: String) {
        guard let passengerUid = Auth.auth().currentUser?.uid else { return }

        let firestoreRef = Firestore.firestore().collection("users").document(passengerUid)
        
        // Save the token to Firestore
        firestoreRef.setData(["fcmToken": token], merge: true) { error in
            if let error = error {
                print("Error saving FCM token to Firestore: \(error.localizedDescription)")
            } else {
                print("FCM token successfully saved to Firestore.")
            }
        }
    }


    func signout() {
        do {
            if let currentToken = Messaging.messaging().fcmToken {
                removeFCMToken(currentToken)
            }
            try Auth.auth().signOut()
            self.userSession = nil
            self.isAuthenticated = false
            self.currentUser = nil
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }

    private func removeFCMToken(_ token: String) {
        guard let passengerUid = Auth.auth().currentUser?.uid else { return }
        let firestoreRef = Firestore.firestore().collection("users").document(passengerUid)
        firestoreRef.updateData(["fcmToken": FieldValue.delete()]) { error in
            if let error = error {
                print("Error removing FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token successfully removed.")
            }
        }
    }


    private func fetchUser() {
        service.$user
            .sink { completion in
                switch completion {
                case .finished:
                    print("User data retrieval completed successfully.")
                case let .failure(error):
                    print("Error fetching user: \(error.localizedDescription)")
                }
            } receiveValue: { [weak self] user in
                self?.currentUser = user
            }
            .store(in: &cancellables)
    }
}
