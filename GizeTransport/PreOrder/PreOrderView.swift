import SwiftUI

struct PreOrderView: View {
    @EnvironmentObject var homeViewModel: HomeViewModel
    @State private var selectedDate = Date()
    @State private var selectedTime = Date()

    var body: some View {
        VStack {
            dragIndicator
            title
            datePickerSection
            confirmButton
        }
  
        .padding(.horizontal)
        .padding(.bottom, 24)
        .background(Color.theme.backgroundColor)
        .cornerRadius(35)
        .overlay(
            RoundedRectangle(cornerRadius: 35)
                .stroke(Color.gray, lineWidth: 0.5)
        )
        .frame(height: UIScreen.main.bounds.height / 2)
    }

    private var dragIndicator: some View {
        Capsule()
            .foregroundColor(Color(.systemGray5))
            .frame(width: 48, height: 6)
            .padding(.top, 8)
    }

    private var title: some View {
        Text("PRE ORDER TRIP")
            .font(.largeTitle)
            .padding(.top)
    }

    private var datePickerSection: some View {
        VStack {
            DatePicker("Select Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .padding()
            DatePicker("Select Time", selection: $selectedTime, in: Date()..., displayedComponents: .hourAndMinute)
                .padding()
        }
    }

    private var confirmButton: some View {
        Button("Confirm") {
            guard let selectedRideType = homeViewModel.selectedRideType else {
                print("DEBUG: No ride type selected.")
                return
            }

            homeViewModel.fetchClosestDriverAndRequestTrip(with: selectedRideType, tripType: .preorder)
            homeViewModel.preordered()
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.darkGreen)
        .cornerRadius(10)
        .foregroundColor(.white)
    }
}

struct Preorder: View {
    @StateObject var homeViewModel = HomeViewModel()
    @State private var showPreOrderView = false

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .bottom) {
                
                if showPreOrderView {
                    preOrderSheet(geometry: geometry)
                        .transition(.move(edge: .bottom)) // Transition for sliding in
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height / 2)
            .edgesIgnoringSafeArea(.all)
            .animation(.easeInOut, value: showPreOrderView) // Animate the transition
        }
    }



    private func preOrderSheet(geometry: GeometryProxy) -> some View {
        PreOrderView()
            .environmentObject(homeViewModel)
            .frame(width: geometry.size.width, height: geometry.size.height / 2)
          
            .cornerRadius(15)
            .offset(y: showPreOrderView ? 0 : geometry.size.height)
    }
}

// Ensure Color.theme.backgroundColor is defined or replace with a concrete color
