//
//  Color.swift
//  GizeTransport
//
//  Created by User on 6/21/23.
//

import SwiftUI
import MapKit
import CoreLocation

extension Color {
    static let theme = ColorTheme()
}

struct ColorTheme {
    let backgroundColor = Color("BackgroundColor")
    let secondaryBackgroundColor = Color("SecondaryBackgroundColor")
    let primaryTextColor = Color("PrimaryTextColor")
    let darkGreen = Color("DarkGreen")

    let ink = Color(red: 0.06, green: 0.08, blue: 0.07)
    let mutedText = Color(red: 0.42, green: 0.46, blue: 0.45)
    let surface = Color(.systemBackground)
    let softSurface = Color(.secondarySystemBackground)
    let fieldSurface = Color(.tertiarySystemBackground)
    let success = Color("DarkGreen")
    let danger = Color(.systemRed)
    let warning = Color(.systemOrange)
}

enum GizeUI {
    static let corner: CGFloat = 18
    static let compactCorner: CGFloat = 12
    static let panelShadow = Color.black.opacity(0.14)
    static let softShadow = Color.black.opacity(0.08)
}

struct GizePanelModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.corner, style: .continuous))
            .shadow(color: GizeUI.panelShadow, radius: 22, x: 0, y: 10)
    }
}

struct GizePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundColor(.white)
            .background(configuration.isPressed ? Color.theme.darkGreen.opacity(0.78) : Color.theme.darkGreen)
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: Color.theme.darkGreen.opacity(configuration.isPressed ? 0.12 : 0.24), radius: 12, x: 0, y: 7)
    }
}

struct GizeSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .bold))
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .foregroundColor(Color.theme.darkGreen)
            .background(Color.theme.softSurface)
            .overlay(
                RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous)
                    .stroke(Color.theme.darkGreen.opacity(0.18), lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

struct GizeFloatingIconButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color.theme.ink)
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial)
            .clipShape(Circle())
            .overlay(Circle().stroke(Color.white.opacity(0.7), lineWidth: 1))
            .shadow(color: GizeUI.softShadow, radius: 12, x: 0, y: 6)
    }
}

extension View {
    func gizePanel() -> some View {
        modifier(GizePanelModifier())
    }

    func gizeFloatingIcon() -> some View {
        modifier(GizeFloatingIconButton())
    }
}

enum AppConfig {
    private static func value(for key: String) -> String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: key) as? String else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static var appleMapsProvider: String {
        "MapKit"
    }

    static var notificationProxyURL: String {
        value(for: "GizeNotificationProxyURL") ?? "https://example.invalid/notifications"
    }

    static var notificationApiKey: String? {
        value(for: "GizeNotificationProxyAPIKey")
    }

    static var legacyFCMEndpoint: String {
        "https://fcm.googleapis.com/fcm/send"
    }

    static var legacyFCMServerKey: String? {
        // Privileged server credentials must never be embedded in an iOS app.
        nil
    }
}

enum AppLogger {
    static func info(_ message: String) {
        #if DEBUG
        print("INFO: \(message)")
        #endif
    }

    static func warning(_ message: String) {
        #if DEBUG
        print("WARNING: \(message)")
        #endif
    }

    static func error(_ message: String) {
        #if DEBUG
        print("ERROR: \(message)")
        #endif
    }
}



extension CLPlacemark {
    var formattedAddress: String {
        [name, thoroughfare, locality, administrativeArea, country]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
    }
}

enum AppleMapsRouting {
    static func route(from origin: CLLocationCoordinate2D,
                      to destination: CLLocationCoordinate2D,
                      completion: @escaping (MKRoute?) -> Void) {
        guard origin.isValidAppleMapsCoordinate,
              destination.isValidAppleMapsCoordinate,
              CLLocation(latitude: origin.latitude, longitude: origin.longitude)
                .distance(from: CLLocation(latitude: destination.latitude, longitude: destination.longitude)) > 5 else {
            DispatchQueue.main.async {
                completion(nil)
            }
            return
        }

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = .automobile

        MKDirections(request: request).calculate { response, error in
            if let error = error {
                AppLogger.warning("Apple Maps routing unavailable: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion(response?.routes.first)
            }
        }
    }
}

extension CLLocationCoordinate2D {
    var isValidAppleMapsCoordinate: Bool {
        CLLocationCoordinate2DIsValid(self) && latitude.isFinite && longitude.isFinite
    }
}
