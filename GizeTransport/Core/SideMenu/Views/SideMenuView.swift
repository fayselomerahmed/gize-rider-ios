//
//  SideMenuView.swift
//  GizeTransport
//
//  Created by User on 4/2/23.
//

import SwiftUI

struct SideMenuView: View {
    @State private var user: User
    @EnvironmentObject var viewModel: AuthViewModel
    @ObservedObject private var locationManager = LocationManager.shared
    private let trip: Trip?

    init(user: User, trip: Trip? = nil) {
        self._user = State(initialValue: user)
        self.trip = trip
    }

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    brandHeader
                    profileHeader
                    tripReadinessCard
                    primaryNavigation
                    accountNavigation
                    supportSection
                    signOutButton
                    footer
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(Color.theme.surface)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.black.opacity(0.06))
                    .frame(width: 1)
                    .ignoresSafeArea()
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "location.north.line.fill")
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 38, height: 38)
                .background(Color.theme.darkGreen)
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text("Gize Transport")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(Color.theme.ink)

                Text("Passenger")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
            }

            Spacer()

            Text(user.accountType == .passenger ? "RIDER" : "DRIVER")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color.theme.darkGreen)
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Color.theme.darkGreen.opacity(0.1))
                .clipShape(Capsule())
        }
    }

    private var profileHeader: some View {
        NavigationLink(destination: UserProfileView(user: $user)) {
            HStack(spacing: 14) {
                profileImage

                VStack(alignment: .leading, spacing: 6) {
                    Text(user.fullname.isEmpty ? "Passenger account" : user.fullname)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color.theme.ink)
                        .lineLimit(1)

                    Text(user.email.isEmpty ? "Complete your profile" : user.email)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.theme.mutedText)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Label("Verified rider", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.theme.darkGreen)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Color.theme.darkGreen.opacity(0.1))
                    .clipShape(Capsule())
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
            }
            .padding(14)
            .gizePanel()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var profileImage: some View {
        Group {
            if user.profileImageUrl.isEmpty {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(Color.theme.darkGreen)
                    .background(Color.theme.darkGreen.opacity(0.12))
            } else {
                AsyncImage(url: URL(string: user.profileImageUrl)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            }
        }
        .frame(width: 62, height: 62)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.theme.darkGreen.opacity(0.16), lineWidth: 1))
    }

    private var tripReadinessCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trip readiness")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(Color.theme.ink)

                    Text(locationManager.isLocationDenied ? "Enable location for accurate pickup and gate guidance." : "Location, alerts, and pre-orders are ready.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color.theme.mutedText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "shield.checkered")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundColor(Color.theme.darkGreen)
                    .frame(width: 38, height: 38)
                    .background(Color.theme.darkGreen.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            }

            HStack(spacing: 10) {
                StatusPill(
                    title: "GPS",
                    value: locationManager.isLocationAuthorized ? "On" : "Off",
                    icon: locationManager.isLocationAuthorized ? "location.fill" : "location.slash.fill",
                    isWarning: !locationManager.isLocationAuthorized
                )
                StatusPill(title: "Support", value: "24/7", icon: "headphones", isWarning: false)
            }
        }
        .padding(14)
        .background(Color.theme.softSurface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.corner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GizeUI.corner, style: .continuous)
                .stroke(Color.theme.darkGreen.opacity(0.12), lineWidth: 1)
        )
    }

    private var primaryNavigation: some View {
        SidePanelSection(title: "Ride tools") {
            VStack(spacing: 10) {
                ForEach(SideMenuOptionViewModel.allCases) { option in
                    NavigationLink(destination: destinationView(for: option)) {
                        SideMenuOptionView(viewModel: option)
                            .padding(.horizontal, 14)
                            .background(Color.theme.surface)
                            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous)
                                    .stroke(Color.black.opacity(0.04), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    private var accountNavigation: some View {
        SidePanelSection(title: "Account") {
            VStack(spacing: 10) {
                NavigationLink(destination: SettingsView(user: $user)) {
                    DrawerActionRow(icon: "gearshape.fill", title: "Settings", subtitle: "Profile, payment, and app preferences")
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(destination: PassengerSafetyCenter()) {
                    DrawerActionRow(icon: "cross.case.fill", title: "Safety center", subtitle: "Emergency contacts and trip safety")
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    private var supportSection: some View {
        SidePanelSection(title: "Help") {
            NavigationLink(destination: PassengerSupportCenter()) {
                DrawerActionRow(icon: "message.fill", title: "Support", subtitle: "Get help with a ride or payment")
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    private var signOutButton: some View {
        Button {
            AppLogger.info("Sign out requested.")
            viewModel.signout()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 36, height: 36)
                    .background(Color.theme.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Sign out")
                        .font(.system(size: 15, weight: .bold))
                    Text("End this passenger session")
                        .font(.system(size: 12, weight: .medium))
                        .opacity(0.76)
                }

                Spacer()
            }
            .foregroundColor(Color.theme.danger)
            .padding(14)
            .background(Color.theme.danger.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Sign out")
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Gize Transport")
                .font(.system(size: 12, weight: .black))
                .foregroundColor(Color.theme.ink)
            Text("Version \(appVersion)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(Color.theme.mutedText)
        }
        .padding(.top, 4)
    }

    private func destinationView(for option: SideMenuOptionViewModel) -> some View {
        switch option {
        case .history:
            return AnyView(TripHistoryView())
        case .notification:
            return AnyView(Notification(notificationTitle: "Trip alerts", notificationBody: "Your ride confirmations, driver arrivals, and service updates will appear here."))
        case .preorder:
            return AnyView(PreOrder())
        }
    }
}

private struct SidePanelSection<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(Color.theme.mutedText)
                .padding(.horizontal, 2)

            content
        }
    }
}

private struct DrawerActionRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(Color.theme.darkGreen)
                .frame(width: 40, height: 40)
                .background(Color.theme.darkGreen.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.theme.ink)
                    .lineLimit(1)

                Text(subtitle)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(Color.theme.mutedText)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(Color.theme.mutedText)
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
        .contentShape(Rectangle())
    }
}

private struct StatusPill: View {
    let title: String
    let value: String
    let icon: String
    let isWarning: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isWarning ? Color.theme.warning : Color.theme.darkGreen)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
                Text(value)
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(isWarning ? Color.theme.warning : Color.theme.ink)
            }
            Spacer()
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(isWarning ? Color.theme.warning.opacity(0.12) : Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct PassengerSupportCenter: View {
    var body: some View {
        ProductionInfoScreen(
            title: "Support",
            icon: "message.fill",
            items: [
                ("Ride issue", "Report pickup, drop-off, or fare problems."),
                ("Payment help", "Get support for failed payments or receipts."),
                ("Lost item", "Contact your driver after a completed trip.")
            ]
        )
    }
}

private struct PassengerSafetyCenter: View {
    var body: some View {
        ProductionInfoScreen(
            title: "Safety center",
            icon: "cross.case.fill",
            items: [
                ("Share trip", "Send your live ride details to trusted contacts."),
                ("Airport guidance", "Use gate and pickup notes before requesting."),
                ("Emergency", "Keep emergency actions visible during active trips.")
            ]
        )
    }
}

private struct ProductionInfoScreen: View {
    let title: String
    let icon: String
    let items: [(String, String)]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 54, height: 54)
                    .background(Color.theme.darkGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                Text(title)
                    .font(.system(size: 28, weight: .black))
                    .foregroundColor(Color.theme.ink)

                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.0)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color.theme.ink)
                        Text(item.1)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.theme.mutedText)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.theme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
                }
            }
            .padding(18)
        }
        .background(Color.theme.softSurface.opacity(0.45))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
