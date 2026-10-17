//
//  LoadingView.swift
//  GizeTransport
//
//  Created by User on 5/18/24.
////
//import SwiftUI
//
//struct LoadingView: View {
//    @EnvironmentObject var networkManager: NetworkManager
//    @Binding var isLoading: Bool
//
//    var body: some View {
//        VStack {
//            Image("logo")
//                .resizable()
//                .frame(width: 100, height: 100)
//                .padding()
//
//            if networkManager.isConnected {
//                Text("Connecting...")
//                    .font(.headline)
//                ProgressView()
//            } else {
//                Text("No Internet Connection")
//                    .font(.headline)
//                    .foregroundColor(.red)
//                Image(systemName: "exclamationmark.triangle.fill")
//                    .foregroundColor(.red)
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//        .background(Color.black.opacity(0.3).edgesIgnoringSafeArea(.all))
//        .transition(.opacity)
//    }
//}
