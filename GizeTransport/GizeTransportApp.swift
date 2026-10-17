//
//  GizeTransportApp.swift
//  GizeTransport
//
//  Created by User on 12/23/22.

import SwiftUI
import Firebase
import FirebaseMessaging
import UserNotifications
import FirebaseCore
import FirebaseAppCheck

class AppDelegate: UIResponder, UIApplicationDelegate, MessagingDelegate, UNUserNotificationCenterDelegate {

    let gcmMessageIDKey = "gcm.message_id"
    private var hasAPNSToken = false

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Configure Firebase
        FirebaseApp.configure()

#if DEBUG
let providerFactory = AppCheckDebugProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory)
#else
let providerFactory = AppAttestProviderFactory()
AppCheck.setAppCheckProviderFactory(providerFactory)
#endif



        // Add Auth State Listener
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                AppLogger.info("User is signed in.")
                UserService.shared.fetchUser()
            } else {
                AppLogger.info("No user is signed in.")
            }
        }

        // Set Messaging Delegate
        Messaging.messaging().delegate = self

        // Request Notification Permissions
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                #if targetEnvironment(simulator)
                AppLogger.info("Skipping APNs registration on Simulator.")
                #else
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
                #endif
            } else {
                AppLogger.warning("Notification permission denied: \(String(describing: error))")
            }
        }

        return true
    }

    // MARK: - Remote Notification Registration

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        AppLogger.error("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Set APNS token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
        hasAPNSToken = true
        AppLogger.info("APNs device token registered successfully.")

        // Fetch and update FCM token
        fetchAndUpdateFCMToken()
    }



    private func uploadDeviceTokenToFirestore(token: String) {
        guard let uid = Auth.auth().currentUser?.uid else {
            AppLogger.warning("User is not logged in.")
            return
        }
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.setData(["apnsToken": token], merge: true) { error in
            if let error = error {
                AppLogger.error("Error updating APNs token: \(error.localizedDescription)")
            } else {
                AppLogger.info("APNs token successfully updated in Firestore.")
            }
        }
    }
    func fetchAndUpdateFCMToken() {
        #if targetEnvironment(simulator)
        AppLogger.info("Skipping FCM token fetch on Simulator until APNs is available on a physical device.")
        return
        #else
        guard hasAPNSToken else {
            AppLogger.warning("Skipping FCM token fetch until APNs token is available.")
            return
        }
        Messaging.messaging().token { token, error in
            if let error = error {
                AppLogger.error("Error fetching FCM token: \(error.localizedDescription)")
                return
            }
            guard let token = token else {
                AppLogger.warning("FCM token is nil.")
                return
            }
            AppLogger.info("Successfully retrieved FCM token.")
            // Update FCM token in Firestore
            self.updateFCMToken(fcmToken: token)
        }
        #endif
    }    // MARK: - Messaging Delegate

    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        AppLogger.info("Firebase registration token refreshed.")
        updateFCMToken(fcmToken: fcmToken)
    }

    private func updateFCMToken(fcmToken: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let docRef = Firestore.firestore().collection("users").document(uid)
        docRef.setData(["fcmToken": fcmToken], merge: true) { error in
            if let error = error {
                AppLogger.error("Error updating FCM token: \(error.localizedDescription)")
            } else {
                AppLogger.info("FCM token successfully updated in Firestore.")
            }
        }
    }

    // MARK: - UNUserNotificationCenter Delegate Methods

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        // Handle notification payload
        if userInfo[gcmMessageIDKey] != nil {
            AppLogger.info("Received remote notification message.")
        }
        AppLogger.info("Received remote notification.")
        completionHandler(.newData)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Handle foreground notification
        let userInfo = notification.request.content.userInfo
        AppLogger.info("Foreground notification received.")
        completionHandler([.alert, .badge, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        // Handle notification response
        let userInfo = response.notification.request.content.userInfo
        AppLogger.info("User interacted with notification.")
        completionHandler()
    }
}


@main
struct GizeTransportApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var userService = UserService.shared
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var networkManager = NetworkManager.shared
    @State private var isLoading = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                if isLoading || userService.isLoading || authViewModel.isLoading {
                    LoadingView(isLoading: $isLoading)
                        .environmentObject(networkManager)
                } else {
                    if Auth.auth().currentUser == nil {
                        LoginView(viewModel: authViewModel)
                            .environmentObject(networkManager)
                    } else {
                        HomeView()
                            .environmentObject(authViewModel)
                            .environmentObject(homeViewModel)
                            .environmentObject(userService)
                            .environmentObject(networkManager)
                    }
                }
                NetworkStatusView()
                    .environmentObject(networkManager)
            }
            .onAppear {
                performInitialSetup()
            }
        }
    }

    private func performInitialSetup() {
        DispatchQueue.global(qos: .background).async {
            // Perform Firebase setup and data fetching asynchronously
            removeSimulatedDelay()

            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }

    private func removeSimulatedDelay() {
        // Add any required asynchronous tasks here
    }
}



struct LaunchScreenWrapper: View {
    @Binding var isLoading: Bool

    var body: some View {
        ZStack {
            if isLoading {
                LoadingView(isLoading: $isLoading)
            }
        }
    }
}

struct NetworkStatusView: View {
    @EnvironmentObject var networkManager: NetworkManager

    var body: some View {
        if !networkManager.isConnected {
            HStack(spacing: 10) {
                Image(systemName: "wifi.slash")
                    .font(.system(size: 15, weight: .bold))

                Text("Connection lost. Some trip updates may be delayed.")
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .foregroundColor(Color.theme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .background(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous)
                    .stroke(Color.theme.warning.opacity(0.35), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
            .shadow(color: GizeUI.softShadow, radius: 12, x: 0, y: 6)
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .frame(maxHeight: .infinity, alignment: .top)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}


struct LoadingView: View {
    @EnvironmentObject var networkManager: NetworkManager
    @Binding var isLoading: Bool

    var body: some View {
        VStack {
            Image("logo")
                .resizable()
                .frame(width: 150, height: 150)
                .padding()

            if networkManager.isConnected {
                Text("Gize Transport")
                    .font(.headline)
                ProgressView()
            } else {
                Text("No Internet Connection")
                    .font(.headline)
                    .foregroundColor(.red)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
        .transition(.opacity)
    }
}
