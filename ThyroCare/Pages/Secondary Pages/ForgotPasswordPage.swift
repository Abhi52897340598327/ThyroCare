//
//  ForgotPasswordPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 6/13/26.
//

import SwiftUI

struct ForgotPasswordPage: View {
    @State private var email = ""
    var body: some View {
        VStack {
            ThyroCareLogo(width: Constants.logoWidth, height: Constants.logoHeight)
            Text(Constants.forgotPasswordInstructions)
                .padding()
                .multilineTextAlignment(.center)
            OpenTextField(title: Constants.emailString, text: $email)
                .contentMargins(25)
                .padding()
            LandingButton(title: "Send email") {
                // TODO: Connect password reset flow.
            }
            .padding(.horizontal, 36)
        }
    }
}

#Preview {
    ForgotPasswordPage()
}
