//
//  RideRequestView.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/22/22.
//

import SwiftUI
import UserNotifications

struct RideRequestView: View {
    @State private var selectedRideType: RideType? = nil
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var isPreorderPresented = false
    let fcmManager = FCMNotificationManager()

    var body: some View {
        ZStack {
            VStack(spacing: 18) {
                handleIndicator
                locationDisplay
                suggestedRides
                actionRow
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 22)
            .gizePanel()
            .padding(.horizontal, 12)
            .padding(.bottom, 18)

            if homeViewModel.isLoading {
                LoadingView(isLoading: $homeViewModel.isLoading)
            }
        }
        .onAppear {
            if homeViewModel.rideTypes.isEmpty {
                loadRideTypes()
                homeViewModel.listenForRideTypes()
            }
        }
        .onDisappear {
            homeViewModel.detachRideTypesListener()
        }
    }

    private var handleIndicator: some View {
        Capsule()
            .fill(Color(.systemGray4))
            .frame(width: 44, height: 5)
            .padding(.top, 2)
    }

    private var locationDisplay: some View {
        HStack(alignment: .top, spacing: 14) {
            locationMarkers
            VStack(spacing: 14) {
                locationInfoText(homeViewModel.currentTrip?.pickupLocationName ?? "Current location", subtitle: "Pickup", time: homeViewModel.pickUpTime)
                if let location = homeViewModel.selectedUberLocation {
                    locationInfoText(location.title, subtitle: "Destination", time: homeViewModel.dropOffTime)
                }
            }
        }
        .padding(14)
        .background(Color.theme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
    }

    private var locationMarkers: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(Color.theme.darkGreen)
                .frame(width: 10, height: 10)
            Rectangle()
                .fill(Color.theme.darkGreen.opacity(0.25))
                .frame(width: 2, height: 34)
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.theme.ink)
                .frame(width: 10, height: 10)
        }
        .padding(.top, 8)
    }

    private func locationInfoText(_ location: String, subtitle: String, time: String?) -> some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(subtitle)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
                Text(location)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.theme.ink)
                    .lineLimit(1)
            }
            Spacer()
            if let time = time {
                Text(time)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color.theme.darkGreen)
            }
        }
    }

    private var suggestedRides: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Suggested rides")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.theme.ink)
                Spacer()
                Text("\(homeViewModel.rideTypes.count) options")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color.theme.mutedText)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(homeViewModel.rideTypes) { type in
                        rideTypeButton(for: type)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }

    private func rideTypeButton(for type: RideType) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(type.imageName)
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .frame(maxWidth: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(type.description)
                    .font(.system(size: 14, weight: .bold))
                    .lineLimit(1)
                Text(homeViewModel.computeRidePrice(forType: type).toCurrency())
                    .font(.system(size: 14, weight: .semibold))
                    .opacity(0.85)
            }
        }
        .padding(12)
        .frame(width: 126, height: 138)
        .foregroundColor(type == selectedRideType ? .white : Color.theme.ink)
        .background(type == selectedRideType ? Color.theme.darkGreen : Color.theme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(type == selectedRideType ? Color.clear : Color.black.opacity(0.05), lineWidth: 1)
        )
        .scaleEffect(type == selectedRideType ? 1.03 : 1)
        .onTapGesture {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                selectedRideType = type
            }
        }
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button("Confirm pickup") {
                handleConfirmPickup()
            }
            .buttonStyle(GizePrimaryButtonStyle())

            Button(action: {
                isPreorderPresented.toggle()
            }) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.theme.darkGreen)
                    .frame(width: 54, height: 54)
                    .background(Color.theme.softSurface)
                    .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
            }
            .sheet(isPresented: $isPreorderPresented) {
                if #available(iOS 16.0, *) {
                    PreOrderView()
                        .presentationDetents([.height(300), .medium])
                }
            }
        }
    }

    private func handleConfirmPickup() {
        guard let selectedRideType = selectedRideType else {
            print("DEBUG: No ride type selected.")
            return
        }

        DispatchQueue.main.async {
            homeViewModel.selectedRideType = selectedRideType
            homeViewModel.fetchClosestDriverAndRequestTrip(with: selectedRideType, tripType: .now)

            if let driverID = homeViewModel.trip?.driverUid {
                homeViewModel.fetchDriverFCMToken(driverUID: driverID) { token in
                    guard token != nil else {
                        print("DEBUG: Driver notification token is unavailable.")
                        return
                    }
                    fcmManager.sendMessageToDriver(driverId: driverID, title: "Ride Request", body: "A ride has been requested. Please confirm.")
                }
            }
        }
    }

    private func loadRideTypes() {
        homeViewModel.fetchRideTypes()
    }
}
