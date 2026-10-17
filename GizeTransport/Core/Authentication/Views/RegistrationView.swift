//
//  RegistrationView.swift
//  GizeTransport
//
//  Created by User on 3/28/23.
//

import SwiftUI
import CoreLocation
import FirebaseFirestore

struct RegistrationView: View {
    @StateObject var viewModel = AuthViewModel()
    @StateObject private var locationManager = LocationManager()  // Correctly initialized as a StateObject
    @State private var fullName: String = ""
    @State private var middleName: String = "" // Added for middle name
    @State private var lastName: String = "" // Added for last name
    @State private var password: String = "" // Added for password
    @State private var country: String = "Ethiopia" // Added for country
    @State private var city: String = "" // Added for city
    @State private var phoneNumber: String = "+251"
    @State private var showingOTPView = false
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var email = ""
    var body: some View {
        NavigationView {
            VStack {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                
                VStack(spacing: 20) {
                    TextField("Full Name", text: $fullName)
                        .padding()
                        .frame(height: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    TextField("Email", text: $email)
                        .padding()
                        .frame(height: 50)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 20)
                    
                    HStack {
                        Image("ethiopian_flag") // Use an image asset for the flag
                            .resizable()
                            .frame(width: 30, height: 20)
                            .padding(.leading, 16)
                        TextField("Phone", text: $phoneNumber)
                            .keyboardType(.numberPad)
                            .padding()
                            .frame(height: 50)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.trailing, 20)
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                
                Button(action: registerAndSendOTP) {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("REGISTER")
                                .foregroundColor(.white)
                                .bold()
                        }
                        Spacer()
                    }
                }
                .padding()
                .background(Color.darkGreen)
                .cornerRadius(10)
                .padding(.horizontal)
                .padding(.top, 20)
                
                Spacer()
                
                HStack {
                    Text("Already have an account?")
                        .foregroundColor(.gray)
                    NavigationLink(destination: LoginView(viewModel: viewModel)) {
                        Text("Login")
                            .foregroundColor(.darkGreen)
                            .underline()
                    }
                }
                .padding(.bottom, 16)
            }
            .navigationTitle("Register")
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Registration"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingOTPView) {
                let coordinates = locationManager.userLocation.map { GeoPoint(latitude: $0.coordinate.latitude, longitude: $0.coordinate.longitude) }
                ?? GeoPoint(latitude: 0, longitude: 0) // Provide a default GeoPoint if userLocation is nil
                
                OTPVerificationView(
                    phoneNumber: phoneNumber,
                    coordinates: coordinates,
                    fullName: fullName,
                    email: email,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private func registerAndSendOTP() {
        isLoading = true
        guard !phoneNumber.isEmpty, !fullName.isEmpty else {
            isLoading = false
            alertMessage = "Please enter all required fields."
            showAlert = true
            return
        }
        
        guard let location = locationManager.userLocation else {
            isLoading = false
            alertMessage = "Location not available"
            showAlert = true
            return
        }
        
        viewModel.registerUser(phoneNumber: phoneNumber, fullName: fullName, accountType: .passenger) { success in
            self.isLoading = false
            if success {
                self.showingOTPView = true
            } else {
                self.alertMessage = "Registration failed. Please try again."
                self.showAlert = true
            }
        }
    }
}

struct OTPVerificationView: View {
    var phoneNumber: String
    var coordinates: GeoPoint
    var fullName: String
    var email: String?
    @State private var otpCode: String = ""
    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.presentationMode) var presentationMode
    @State private var showAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack {
            Text("Enter the OTP sent to \(phoneNumber)")
                .padding(.bottom, 20)
                .multilineTextAlignment(.center)

            TextField("OTP Code", text: $otpCode)
                .keyboardType(.numberPad)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            Button(action: verifyOTP) {
                HStack {
                    Spacer()
                    Text("Verify")
                        .foregroundColor(.white)
                        .bold()
                    Spacer()
                }
            }
            .padding()
            .background(Color.darkGreen)
            .cornerRadius(10)
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Verification"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .padding()
        .navigationTitle("Enter OTP")
        .onAppear {
            sendOTP()
        }
    }
    
    private func sendOTP() {
        viewModel.sendVerificationCode(toPhoneNumber: phoneNumber) { error in
            if let error = error {
                alertMessage = "Failed to send OTP: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    private func verifyOTP() {
        viewModel.verifyRegistration(verificationCode: otpCode, coordinates: coordinates, fullName: fullName, email: email ?? "")
        alertMessage = "Verification successful"
        showAlert = true
        viewModel.updateFCMToken()
        presentationMode.wrappedValue.dismiss()
    }
}

@available(iOS 16.0, *)
struct RegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        RegistrationView()
    }
}
