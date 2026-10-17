//
//  HomeView.swift
//  GizeTransport
//
//  Created by User on 11/15/22.
//

import SwiftUI
import CoreLocation

struct HomeView: View {
    @State private var mapState = MapViewState.noInput
    @State private var showSideMenu = false
    @State private var showLocationSearchView = false
    @State private var recenterTrigger = 0
    @EnvironmentObject var locationViewModel: LocationSearchViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var homeViewModel: HomeViewModel
    @ObservedObject private var locationManager = LocationManager.shared
    @State private var userLocation: CLLocation?
    @StateObject var viewModel = NetworkViewModel()
    @EnvironmentObject var networkManager: NetworkManager
    @State private var isShowingTripCompletedView = false

    var body: some View {
        Group {
            if authViewModel.userSession == nil {
                LoginView(viewModel: authViewModel)
            } else if let user = authViewModel.currentUser {
                NavigationStack {
                    GeometryReader { proxy in
                        let drawerWidth = min(326, proxy.size.width * 0.84)

                        ZStack(alignment: .leading) {
                            if showSideMenu {
                                SideMenuView(user: user)
                                    .frame(width: drawerWidth)
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            }

                            mapView
                                .offset(x: showSideMenu ? drawerWidth : 0)
                                .shadow(color: showSideMenu ? Color.black.opacity(0.24) : .clear, radius: 18, x: -4, y: 8)

                            if showSideMenu {
                                Color.black.opacity(0.18)
                                    .edgesIgnoringSafeArea(.all)
                                    .offset(x: drawerWidth)
                                    .onTapGesture {
                                        withAnimation(.easeInOut(duration: 0.28)) {
                                            showSideMenu = false
                                        }
                                    }
                            }
                        }
                        .animation(.spring(response: 0.32, dampingFraction: 0.9), value: showSideMenu)
                    }
                    .edgesIgnoringSafeArea(.bottom)
                    .onAppear {
                        viewModel.startNetworkConnection()
                        // Clear trip if already completed
                        if homeViewModel.trip?.state == .tripCompleted && !isShowingTripCompletedView {
                            homeViewModel.clearCurrentTrip()
                            self.mapState = .noInput
                        }
                    }
                    .onDisappear {
                        cleanup()
                    }
                    // Add the .alert modifier here
                    .alert(item: $homeViewModel.alertItem) { alertItem in
                        if let secondaryButton = alertItem.secondaryButton {
                            Alert(
                                title: alertItem.title,
                                message: alertItem.message,
                                primaryButton: alertItem.primaryButton ?? .default(Text("OK")),
                                secondaryButton: secondaryButton
                            )
                        } else {
                            Alert(
                                title: alertItem.title,
                                message: alertItem.message,
                                dismissButton: alertItem.primaryButton
                            )
                        }
                    }
                    // Move the .toolbar modifier here
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            if mapState == .tripAccepted {
                                Button(action: {
                                    homeViewModel.confirmTripCancellation()
                                }) {
                                    Text("Cancel Trip")
                                        .foregroundColor(.red)
                                }
                            } else {
                                EmptyView() // Ensures that content is always returned
                            }
                        }
                    }
                }
            } else {
                // Handle the case where user is nil
                EmptyView()
            }
        }
        .background(BackgroundLocationSearchView(isActive: $showLocationSearchView))
    }

    private func cleanup() {
        locationManager.stopLocationUpdates()
        homeViewModel.removeAllListeners()
        viewModel.stopNetworkConnection()
    }
}

struct BackgroundLocationSearchView: View {
    @Binding var isActive: Bool
    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        if isActive {
            LocationSearchView()
        } else {
            EmptyView()
        }
    }
}

private struct LocationPermissionCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "location.slash.fill")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 30, height: 30)
                    .background(Color.theme.warning)
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Location off")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(Color.theme.ink)
                    Text("Tap to enable live pickup")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.theme.mutedText)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.7), lineWidth: 1)
            )
            .shadow(color: GizeUI.softShadow, radius: 12, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Enable location access")
    }
}

extension HomeView {
    var mapView: some View {
        ZStack(alignment: .bottom) {
            ZStack(alignment: .top) {
                UberMapViewRepresentable(mapState: $mapState, recenterTrigger: $recenterTrigger)
                    .ignoresSafeArea()

                if mapState == .searchingForLocation {
                    withAnimation(.bouncy) {
                        LocationSearchView()
                    }
                }

                MapViewActionButton(mapState: $mapState, showSideMenu: $showSideMenu)
                    .buttonStyle(PlainButtonStyle())
                    .padding(.leading)
                    .padding(.top, 4)

                VStack(alignment: .trailing, spacing: 10) {
                    Button {
                        if locationManager.isLocationDenied {
                            openAppSettings()
                        } else {
                            locationManager.requestLocationPermission()
                        }
                        recenterTrigger += 1
                    } label: {
                        Image(systemName: locationManager.isLocationAuthorized ? "location.fill" : "location.slash.fill")
                            .gizeFloatingIcon()
                    }
                    .accessibilityLabel("Center map on my location")

                    if locationManager.isLocationDenied {
                        LocationPermissionCard {
                            locationManager.requestLocationPermission()
                            openAppSettings()
                        }
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 4)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .frame(maxHeight: .infinity)

            if let user = authViewModel.currentUser {
                homeViewModel.viewForState(mapState, user: user)
                    .transition(.move(edge: .bottom))

                if user.accountType == .passenger {
                    passengerViews(for: mapState)
                } else {
                    driverViews(for: mapState)
                }
            }

            if mapState == .noInput {
                LocationSearchActivationView()
                    .padding(.bottom, 16)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            mapState = .searchingForLocation
                        }
                    }
            }

            // Move BackgroundLocationSearchView here
            BackgroundLocationSearchView(isActive: $showLocationSearchView)
                .environmentObject(homeViewModel)
        }
        .edgesIgnoringSafeArea(.bottom)
        .onReceive(LocationManager.shared.$userLocation) { location in
            if let location = location {
                homeViewModel.userLocation = location.coordinate
            }
        }
        .onReceive(homeViewModel.$selectedUberLocation) { location in
            if location != nil {
                self.mapState = .locationSelected
            }
        }
        .onReceive(homeViewModel.$trip) { trip in
            if let trip = trip {
                withAnimation(.spring()) {
                    updateMapState(for: trip.state)
                }
            } else {
                self.mapState = .noInput
            }
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString),
              UIApplication.shared.canOpenURL(settingsURL) else { return }
        UIApplication.shared.open(settingsURL)
    }

    private func passengerViews(for state: MapViewState) -> some View {
        Group {
            switch state {
            case .locationSelected, .polylineAdded:
                RideRequestView()
                    .transition(.move(edge: .bottom))

            case .tripRejected:
                EmptyView()
            case .tripAccepted:
                TripAcceptedView()
                    .transition(.move(edge: .bottom))
            case .tripRequested:
                TripLoadingView()
                    .transition(.move(edge: .bottom))
            case .tripStarted:
                TripStartedView()
                    .transition(.move(edge: .bottom))
            case .preordered:
                PreOrderView()
                    .transition(.move(edge: .bottom))
            case .preordersuccessful:
                PreorderSuccessView()
                    .transition(.move(edge: .bottom))
            case .tripCompleted:
                TripCompletedView(isPresented: $isShowingTripCompletedView)
                    .onDisappear {
                        // Clear the trip data when the receipt is dismissed
                        homeViewModel.clearCurrentTrip()
                        self.mapState = .noInput
                    }
                    .transition(.move(edge: .bottom))
            default:
                EmptyView()
            }
        }
    }

    private func driverViews(for state: MapViewState) -> some View {
        Group {
            if let trip = homeViewModel.trip {
                switch state {
                case .tripRequested:
                    AcceptTripView(trip: trip)
                        .transition(.move(edge: .bottom))
                case .tripAccepted:
                    PickupPassengerView(trip: trip)
                        .transition(.move(edge: .bottom))
                default:
                    EmptyView()
                }
            }
        }
    }

    private func updateMapState(for tripState: TripState) {
        switch tripState {
        case .requested:
            self.mapState = .tripRequested
        case .rejected:
            self.mapState = .tripRejected
            homeViewModel.clearCurrentTrip()
        case .accepted:
            self.mapState = .tripAccepted
        case .passengerCancelled, .driverCancelled:
            self.mapState = .tripCancelledByPassenger
            homeViewModel.clearCurrentTrip()
        case .arrived:
            self.mapState = .tripArrived
        case .noTrip:
            self.mapState = .noInput
        case .preorder:
            // Handle preordered state if needed
            break
        case .starttrip:
            self.mapState = .tripStarted
        case .tripCompleted:
            self.mapState = .tripCompleted
            self.isShowingTripCompletedView = true
            // Do not clear trip here; wait until the receipt is dismissed
        case .preordersuccesful:
            self.mapState = .preordersuccessful
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(LocationSearchViewModel())
            .environmentObject(HomeViewModel())
            .environmentObject(NetworkManager())
    }
}
