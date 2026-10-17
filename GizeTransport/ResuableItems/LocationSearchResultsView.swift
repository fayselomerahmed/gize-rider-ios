//
//  LocationSearchResultsView.swift
//  GizeTransport
//
//  Created by User on 4/4/23.
//
import SwiftUI
import MapKit

struct LocationSearchResultsView: View {
    @ObservedObject var viewModel: HomeViewModel
    var config: LocationResultsViewConfig
    
    var body: some View {
        List(viewModel.results, id: \.self) { result in
            VStack(alignment: .leading) {
                Text(result.title)
                    .font(.headline)
                Text(result.subtitle)
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            .onTapGesture {
                if viewModel.activeField == .start {
                    viewModel.selectStartLocation(result)
                } else if viewModel.activeField == .destination {
                    viewModel.selectDestinationLocation(result)
//                    self.viewModel.mapState = .locationSelected
                }
            }
        }
    }
}




















