//
//  MapViewActionButtion.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/6/22.
//

import SwiftUI

struct MapViewActionButton: View {
    @Binding var mapState: MapViewState
    @Binding var showSideMenu: Bool
    @EnvironmentObject var viewModel: HomeViewModel
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.25)) {
                actionForState(mapState)
            }
        }) {
            Image(systemName: imageNameForState(mapState))
                .gizeFloatingIcon()
        }
        .accessibilityLabel(imageNameForState(mapState) == "line.3.horizontal" ? "Open menu" : "Back")
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    func actionForState(_ state: MapViewState) {
        switch state {
        case .noInput, .manualTrip, .preordersuccessful:
            showSideMenu.toggle()
        case .searchingForLocation:
            mapState = .noInput
        case .locationSelected,
             .polylineAdded,
             .tripRejected,
             .tripAccepted,
             .tripRequested,
             .tripCancelledByDriver,
             .tripCancelledByPassenger,
             .tripCompleted:
            mapState = .noInput
            viewModel.selectedUberLocation = nil
        case .tripArrived:
            mapState = .tripArrived
        case .noTrip:
            mapState = .noInput
        case .preordered:
            mapState = .preordered
        case .tripStarted:
            mapState = .tripStarted
        }
    }

    func imageNameForState(_ state: MapViewState) -> String {
        switch state {
        case .noInput, .noTrip, .preordersuccessful:
            return "line.3.horizontal"
        default:
            return "arrow.left"
        }
    }
}
