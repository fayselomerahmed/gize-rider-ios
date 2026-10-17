//
//  RatingView.swift
//  GizeTransport
//
//  Created by User on 10/15/23.
//

//import SwiftUI
//
//struct Rating: View {
//    @Binding var rating: Double
//
//    var body: some View {
//        HStack {
//            ForEach(1..<6) { index in
//                Image(systemName: index <= Int(rating) ? "star.fill" : "star")
//                    .resizable()
//                    .aspectRatio(contentMode: .fit)
//                    .frame(width: 30, height: 30)
//                    .foregroundColor(.yellow)
//                    .onTapGesture {
//                        rating = Double(index)
//                    }
//            }
//        }
//        .padding()
//    }
//}
//
//struct RatingView: View {
//    @State private var rating: Double = 5.0
//    @EnvironmentObject var homeViewModel: HomeViewModel
//
//    var body: some View {
//        VStack {
//            Text("Rate Your Driver")
//                .font(.title)
//                .padding()
//
//            Rating(rating: $rating)
//
//            Text("Rating: \(Int(rating))")
//
//            Button("Submit Rating") {
//                homeViewModel.noTrip()
//                // Handle the submission logic here (e.g., sending feedback and rating to a server)
//                print("Rating: \(rating)")
//            }
//            .padding()
//            .foregroundColor(.white)
//            .background(Color.blue)
//            .cornerRadius(10)
//        }
//        .padding()
//        .background(Color.theme.backgroundColor)
//        .cornerRadius(16)
//        .shadow(color: Color.theme.secondaryBackgroundColor, radius: 20)
//    }
//}
//
//struct RatingView_Previews: PreviewProvider {
//    static var previews: some View {
//        RatingView()
//    }
//}
