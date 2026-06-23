//
//  SignUpPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/30/26.
//

import SwiftUI

struct SignUpPage: View {
    @EnvironmentObject private var authManager: AuthManager

    @State private var username = ""
    @State private var password = ""
    @State private var email = ""
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ThyroCareLogo(width: 260, height: 260)

                Text(Constants.signUpString)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(spacing: 18) {
                    OpenTextField(title: Constants.usernameString, text: $username)

                    SecureField(Constants.passwordString, text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    OpenTextField(title: Constants.emailString, text: $email)
                }
                .padding(.horizontal, 36)

                if !authManager.accountMessage.isEmpty {
                    Text(authManager.accountMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                }

                LandingButton(title: Constants.createAccountString) {
                    authManager.signUp(username: username, email: email, password: password)
                }
                .padding(.horizontal, 36)
                .padding(.top, 12)

                Spacer()
            }
        }
    }
}

#Preview {
    SignUpPage()
        .environmentObject(AuthManager())
}
