//
//  LocationSearchView.swift
//  UberSwiftUitutorial
//
//  Created by User on 12/6/22.
//
import SwiftUI

struct LocationSearchView: View {
    @EnvironmentObject var viewModel: HomeViewModel
    @FocusState private var focusedField: Field?
    @State private var isPresentingLocationPicker = false

    enum Field {
        case startLocation, destination
    }

    var body: some View {
        VStack {
            VStack {
                HStack {
                    VStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)

                        Rectangle()
                            .fill(Color.red)
                            .frame(width: 2, height: 24)

                        Circle()
                            .fill(Color.red)
                            .frame(width: 8, height: 8)
                    }
                    .padding(.leading, 16)

                    VStack {
                        TextField("Start Location", text: $viewModel.startLocationQuery, onEditingChanged: { isEditing in
                            if isEditing {
                                viewModel.activeField = .start
                            }
                        })
                        .font(.title3)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .focused($focusedField, equals: .startLocation)
                        .onChange(of: viewModel.startLocationQuery) { newValue in
                            viewModel.fetchPlaces(query: newValue)
                        }

                        HStack {
                            TextField("Enter Destination", text: $viewModel.destinationQuery, onEditingChanged: { isEditing in
                                if isEditing {
                                    viewModel.activeField = .destination
                                }
                            })
                            .font(.title3)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .focused($focusedField, equals: .destination)
                            .onChange(of: viewModel.destinationQuery) { newValue in
                                viewModel.fetchPlaces(query: newValue)
                            }

                            Button(action: {
                                isPresentingLocationPicker = true
                            }) {
                                Image(systemName: "map.fill")
                                    .foregroundColor(.green)
                                    .font(.title)
                            }
                            .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.top, 64)

                Divider()
                    .padding(.vertical)
            }
            .onTapGesture {
                dismissKeyboard()
            }

            LocationSearchResultsView(viewModel: viewModel, config: .ride)
                .opacity(viewModel.results.isEmpty ? 0 : 1)
                .animation(.easeInOut, value: viewModel.results.isEmpty)
        }
        .background(Color.white)
        .navigationBarTitle("Address", displayMode: .inline)
        .onAppear {
            focusedField = .destination
        }
        .fullScreenCover(isPresented: $isPresentingLocationPicker) {
            LocationPickerWrapperView(isPresented: $isPresentingLocationPicker)
                .environmentObject(viewModel)
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
