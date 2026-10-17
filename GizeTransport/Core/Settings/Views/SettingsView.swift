//
//  SettingsView.swift
//  GizeTransport
//
//  Created by User on 4/3/23.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Binding var user: User

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                accountCard
                settingsSection
                privacySection
                signOutButton
            }
            .padding(18)
        }
        .background(Color.theme.softSurface.opacity(0.45))
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var accountCard: some View {
        NavigationLink(destination: UserProfileView(user: $user)) {
            HStack(spacing: 14) {
                avatar

                VStack(alignment: .leading, spacing: 6) {
                    Text(user.fullname.isEmpty ? "Passenger account" : user.fullname)
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(Color.theme.ink)
                        .lineLimit(1)

                    Text(user.email.isEmpty ? "Add an email address" : user.email)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color.theme.mutedText)
                        .lineLimit(1)

                    Label("Edit profile", systemImage: "pencil")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color.theme.darkGreen)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(Color.theme.mutedText)
            }
            .padding(16)
            .gizePanel()
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var avatar: some View {
        Group {
            if user.profileImageUrl.isEmpty {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(15)
                    .foregroundColor(Color.theme.darkGreen)
                    .background(Color.theme.darkGreen.opacity(0.12))
            } else {
                AsyncImage(url: URL(string: "\(user.profileImageUrl)?t=\(Date().timeIntervalSince1970)")) { image in
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

    private var settingsSection: some View {
        SettingsPanelSection(title: "Ride preferences") {
            VStack(spacing: 10) {
                SettingsActionRow(icon: "creditcard.fill", title: "Payment methods", subtitle: "Cards, wallet, and receipts")
                SettingsActionRow(icon: "location.fill", title: "Saved places", subtitle: "Home, work, and airport gates")
                SettingsActionRow(icon: "bell.badge.fill", title: "Notifications", subtitle: "Ride alerts and service updates")
            }
        }
    }

    private var privacySection: some View {
        SettingsPanelSection(title: "Privacy and safety") {
            VStack(spacing: 10) {
                SettingsActionRow(icon: "hand.raised.fill", title: "Privacy controls", subtitle: "Location and account visibility")
                SettingsActionRow(icon: "shield.lefthalf.filled", title: "Safety settings", subtitle: "Emergency contact and trip sharing")
            }
        }
    }

    private var signOutButton: some View {
        Button {
            AppLogger.info("Sign out requested from settings.")
            viewModel.signout()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 40, height: 40)
                    .background(Color.theme.danger.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
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
    }
}

private struct SettingsPanelSection<Content: View>: View {
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

            content
        }
    }
}

private struct SettingsActionRow: View {
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
        }
        .padding(14)
        .background(Color.theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous)
                .stroke(Color.black.opacity(0.04), lineWidth: 1)
        )
    }
}
