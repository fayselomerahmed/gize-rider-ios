//
//  TripAccptedView.swift
//  GizeDriver
//
//  Created by User on 7/15/23.
//

import SwiftUI

struct TripAcceptedView: View {
    @EnvironmentObject var viewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.theme.mutedText.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            if let trip = viewModel.trip {
                statusHeader(for: trip)
                driverCard(for: trip)
                routeCard(for: trip)
                safetyRow
                cancelButton
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 24)
        .gizePanel()
    }

    private func statusHeader(for trip: Trip) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Driver is on the way")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.theme.ink)

                Text("Meet at \(trip.pickupLocationName)")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.theme.mutedText)
                    .lineLimit(2)
            }

            Spacer()

            VStack(spacing: 2) {
                Text("\(trip.travelTimeToPassenger)")
                    .font(.system(size: 22, weight: .bold))
                Text("min")
                    .font(.system(size: 12, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(width: 62, height: 62)
            .background(Color.theme.darkGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color.theme.darkGreen.opacity(0.25), radius: 12, x: 0, y: 7)
        }
    }

    private func driverCard(for trip: Trip) -> some View {
        HStack(spacing: 14) {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 64, height: 64)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.theme.darkGreen.opacity(0.2), lineWidth: 1))

            VStack(alignment: .leading, spacing: 6) {
                Text(trip.driverName)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(Color.theme.ink)

                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .foregroundColor(Color.theme.warning)
                    Text("4.8 • Verified driver")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.theme.mutedText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 5) {
                Image("uber-black")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 82, height: 38)

                Text("Toyota Vitz")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.ink)

                Text("A55761-02")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.theme.mutedText)
            }
        }
        .padding(14)
        .background(Color.theme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.corner, style: .continuous))
    }

    private func routeCard(for trip: Trip) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            routeRow(icon: "mappin.circle.fill", title: "Pickup", value: trip.pickupLocationName, tint: Color.theme.darkGreen)
            Divider()
            routeRow(icon: "flag.checkered.circle.fill", title: "Destination", value: trip.dropofflocationName, tint: Color.theme.ink)
        }
        .padding(14)
        .background(Color.theme.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.corner, style: .continuous))
    }

    private func routeRow(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 19, weight: .bold))
                .foregroundColor(tint)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
                Text(value)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(Color.theme.ink)
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    private var safetyRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(Color.theme.darkGreen)

            Text("Share your ride details and check the plate before entering.")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.theme.mutedText)
                .lineLimit(2)

            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.theme.darkGreen.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
    }

    private var cancelButton: some View {
        Button {
            viewModel.cancelTripAsPassenger()
            AppLogger.info("Passenger cancelled trip.")
        } label: {
            Text("Cancel trip")
                .font(.system(size: 16, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .foregroundColor(Color.theme.danger)
                .background(Color.theme.danger.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TripAcceptedView_Previews: PreviewProvider {
    static var previews: some View {
        TripAcceptedView()
            .padding()
    }
}
