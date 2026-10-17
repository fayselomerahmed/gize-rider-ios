//
//  TripStartedView.swift
//  GizeTransport
//
//  Created by User on 10/12/23.
//

import SwiftUI

struct TripStartedView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel

    var body: some View {
        VStack(spacing: 18) {
            Capsule()
                .fill(Color.theme.mutedText.opacity(0.25))
                .frame(width: 44, height: 5)
                .padding(.top, 8)

            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Trip in progress")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.theme.ink)

                    Text("Relax. We will keep the map and arrival updates live while you ride.")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color.theme.mutedText)
                        .lineLimit(2)
                }

                Spacer()

                RideInProgressSpinner(lineWidth: 4, height: 48, width: 48)
            }

            HStack(spacing: 12) {
                insight(icon: "clock.fill", title: "ETA", value: homeViewModel.dropOffTime ?? "Updating")
                insight(icon: "shield.fill", title: "Safety", value: "Active")
                insight(icon: "map.fill", title: "Route", value: "Live")
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 22)
        .gizePanel()
    }

    private func insight(icon: String, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color.theme.darkGreen)

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.theme.mutedText)

            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.theme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.theme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
    }
}
