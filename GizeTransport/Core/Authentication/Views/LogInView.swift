//
//  LogInView.swift
//  GizeTransport
//
//  Created by User on 3/28/23.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: AuthViewModel
    @State private var phoneNumber: String = "+251"
    @State private var verificationCode: [String] = Array(repeating: "", count: 6)
    @FocusState private var focusedField: Int?
    @State private var shouldShowOTPFields = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    @State private var isNavigatingToHome = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.theme.softSurface.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        header
                        formCard
                        legalCopy
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 36)
                    .padding(.bottom, 28)
                }

                if isLoading || viewModel.isAuthenticated {
                    LoadingView(isLoading: $isLoading)
                        .transition(.opacity)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("Login"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .background(
                NavigationLink(destination: HomeView(), isActive: $isNavigatingToHome) {
                    EmptyView()
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image("logo")
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: GizeUI.softShadow, radius: 14, x: 0, y: 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Welcome to Gize")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(Color.theme.ink)
                Text(shouldShowOTPFields ? "Enter the 6-digit code sent to your phone." : "Sign in with your mobile number to request a safe ride.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color.theme.mutedText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var formCard: some View {
        VStack(spacing: 18) {
            phoneNumberField
            if shouldShowOTPFields {
                otpFields
            }
            actionButtons
        }
        .padding(18)
        .gizePanel()
    }

    private var phoneNumberField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Mobile number")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.theme.mutedText)

            HStack(spacing: 12) {
                Image("ethiopian_flag")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 34, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))

                TextField("Phone no.", text: $phoneNumber)
                    .keyboardType(.phonePad)
                    .font(.system(size: 17, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(Color.theme.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: GizeUI.compactCorner, style: .continuous))
        }
    }

    private var otpFields: some View {
        HStack(spacing: 8) {
            ForEach(0..<6, id: \.self) { index in
                TextField("", text: $verificationCode[index])
                    .multilineTextAlignment(.center)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .frame(width: 42, height: 52)
                    .background(Color.theme.fieldSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(focusedField == index ? Color.theme.darkGreen : Color.clear, lineWidth: 1.5)
                    )
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .focused($focusedField, equals: index)
                    .onChange(of: verificationCode[index]) { newValue in
                        let filtered = String(newValue.filter { "0123456789".contains($0) }.prefix(1))
                        verificationCode[index] = filtered
                        if filtered.count == 1 && index < verificationCode.count - 1 {
                            focusedField = index + 1
                        } else if filtered.isEmpty && index > 0 {
                            focusedField = index - 1
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(shouldShowOTPFields ? "Resend code" : "Continue") {
                sendCode()
            }
            .buttonStyle(GizePrimaryButtonStyle())

            if shouldShowOTPFields {
                Button("Verify and continue") {
                    verifyCode()
                }
                .buttonStyle(GizePrimaryButtonStyle())
            }

            NavigationLink(destination: RegistrationView()) {
                Text("Create new account")
            }
            .buttonStyle(GizeSecondaryButtonStyle())
        }
    }

    private var legalCopy: some View {
        VStack(spacing: 6) {
            Text("By continuing, you agree to Gize Terms & Conditions and Privacy Policy.")
                .font(.footnote)
                .foregroundColor(Color.theme.mutedText)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 8)
    }

    private func sendCode() {
        isLoading = true
        viewModel.sendVerificationCode(toPhoneNumber: phoneNumber) { error in
            isLoading = false
            if let error = error {
                alertMessage = "Failed to send verification code: \(error.localizedDescription)"
                showAlert = true
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                    shouldShowOTPFields = true
                    focusedField = 0
                }
            }
        }
    }

    private func verifyCode() {
        isLoading = true
        viewModel.verifyPhoneNumber(verificationCode: verificationCode.joined()) { success in
            isLoading = false
            if success {
                isNavigatingToHome = true
            } else {
                alertMessage = "Verification failed. Please try again."
                showAlert = true
            }
        }
    }
}
