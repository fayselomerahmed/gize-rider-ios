# Gize Rider

Gize Rider is the passenger-side SwiftUI prototype in a two-app ride-sharing learning project. It explores location search, pickup and destination selection, driver discovery, trip requests, and trip-status screens.

> This is a portfolio prototype, not a production ride service. It has no verified production backend, Firebase security rules, payment system, or end-to-end passenger/driver release validation. Do not use it for real rides or real passenger data.

## What it demonstrates

- SwiftUI screens and view models for sign-in, location search, saved places, ride selection, trip progress, and trip history.
- MapKit for map presentation and route calculations.
- Core Location with foreground, user-authorized location access.
- Firebase Authentication, Firestore, and Firebase Messaging integration points.
- Trip-state-driven UI for request, acceptance, arrival, cancellation, and completion.

## How the code is organized

| Area | Responsibility |
| --- | --- |
| Core/Authentication | Sign-in and registration UI and state |
| Core/LocationSearch | Place search, map selection, and saved-place UI |
| Core/Home | Passenger home state, map presentation, and request coordination |
| Trips/Passengers | Passenger-facing trip and progress screens |
| Models | User, trip, ride, location, and display state |
| Services / Managers | Firebase access, location, and supporting integration code |

The passenger app models the ride from the person asking for a trip. A separate [Gize Driver app](https://github.com/fayselomerahmed/gize-driver-ios) models the driver workflow. Although both projects use Firebase-related code, their shared backend contract and live end-to-end behavior have not been validated.

## Run locally

1. Install Xcode and CocoaPods.
2. In this directory, run pod install.
3. Add your own Firebase iOS configuration as GizeTransport/GoogleService-Info.plist (ignored by Git).
4. Configure a unique bundle identifier and your own signing team in Xcode.
5. Open GizeTransport.xcworkspace and run the GizeTransport scheme on a simulator.

Never add service-account keys, FCM server credentials, signing files, real user records, or production location data to this repository. A Firebase client configuration is not a substitute for restrictive server-side Firebase rules.

## Privacy and security boundaries

- Location is sensitive. Request it only when the ride flow needs it, explain the purpose, and honor denied/restricted permission states.
- Keep passenger/driver identity, phone numbers, device tokens, precise coordinates, and trip documents out of logs and source fixtures.
- Notification delivery must go through a trusted authenticated backend. Privileged FCM credentials must never be shipped in an iOS app.
- Before connecting a Firebase project, define and test Authentication, Firestore, and Realtime Database access rules. This repository does not include or verify those rules.
- See [SECURITY.md](SECURITY.md) before reporting a security concern.

## Validation status

The source was reviewed for embedded credentials and personal sample data. Debug output that could expose user/trip details or notification tokens was removed or redacted, and fake sample profile details were removed. The app has **not** had a complete Xcode simulator build or passenger-to-driver integration test in this environment. No claim of production readiness is made.

## Attribution

Some files retain UberSwiftUI/tutorial author headers. Those attributions remain in place; this project does not claim all source code or artwork is original. Third-party names, marks, and assets belong to their respective owners. No open-source redistribution license is granted by this portfolio publication.
