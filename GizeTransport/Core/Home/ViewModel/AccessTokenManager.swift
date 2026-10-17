//
//  AccessTokenManager.swift
//  GizeTransport
//
//  Created by User on 10/20/24.
//

//
//  AccessTokenManager.swift
//  GizeTransport
//
//  Created by User on 10/20/24.
//
import Foundation
import FirebaseFirestore
import FirebaseMessaging

// MARK: - FCMNotificationManager
class FCMNotificationManager {
    static let shared = FCMNotificationManager()
    private let db = Firestore.firestore()
    private var deviceFCMToken: String?

    init() {}

    private func fetchDeviceTokenIfNeeded(completion: @escaping (String?) -> Void) {
        if let deviceFCMToken {
            completion(deviceFCMToken)
            return
        }

        #if targetEnvironment(simulator)
        AppLogger.warning("Skipping FCM token fetch on Simulator because APNs is unavailable.")
        completion(nil)
        return
        #else
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM token: \(error.localizedDescription)")
                completion(nil)
            } else if let token = token {
                AppLogger.info("Successfully retrieved FCM token.")
                self.deviceFCMToken = token
                completion(token)
            } else {
                completion(nil)
            }
        }
        #endif
    }

    func sendAutomatedNotification(title: String, body: String) {
        guard let url = URL(string: AppConfig.notificationProxyURL) else {
            print("Invalid server URL.")
            return
        }

        fetchDeviceTokenIfNeeded { [weak self] deviceToken in
            guard let self = self, let deviceToken = deviceToken else {
                print("Device token is nil or unavailable.")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if let apiKey = AppConfig.notificationApiKey { request.setValue(apiKey, forHTTPHeaderField: "x-api-key") }

            let payload: [String: Any] = [
                "fcm_token": deviceToken,
                "title": title,
                "body": body
            ]

            do {
                request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
            } catch {
                print("Error serializing JSON: \(error.localizedDescription)")
                return
            }

            let task = URLSession.shared.dataTask(with: request) { _, response, error in
                if let error = error {
                    print("Error sending automated notification request: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Automated notification sent successfully.")
                    } else {
                        print("Failed to send automated notification. HTTP Status Code: \(httpResponse.statusCode)")
                    }
                }
            }
            task.resume()
        }
    }
    func sendMessageToDriver(driverId: String, title: String, body: String) {
        db.collection("users").document(driverId).getDocument { [weak self] document, error in
            if let error = error {
                print("Error fetching driver document: \(error)")
                return
            }

            guard let document = document, document.exists,
                  let fcmToken = document.data()?["fcmToken"] as? String else {
                print("DEBUG: Driver notification token is unavailable.")
                return
            }

            AppLogger.info("Retrieved FCM token for driver.")
            self?.sendNotificationRequestToServer(fcmToken: fcmToken, title: title, body: body)
        }
    }

    func sendNotificationRequestToServer(fcmToken: String, title: String, body: String) {
        guard let url = URL(string: AppConfig.notificationProxyURL) else {
            print("Invalid server URL.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let apiKey = AppConfig.notificationApiKey { request.setValue(apiKey, forHTTPHeaderField: "x-api-key") }

        let payload: [String: Any] = [
            "fcmToken": fcmToken,
            "title": title,
            "body": body
        ]

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
        } catch {
            print("Error serializing JSON: \(error.localizedDescription)")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("Error sending notification request: \(error.localizedDescription)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("Notification sent successfully.")
                } else {
                    print("Failed to send notification. HTTP Status Code: \(httpResponse.statusCode)")
                }
            }
        }
        task.resume()
    }

}

