import SwiftUI

struct SignUpPage: View {
    var store: CareStore?
    @EnvironmentObject private var authManager: AuthManager

    @State private var username = ""
    @State private var password = ""
    @State private var email = ""

    var body: some View {
        ThyroPageScaffold(title: Constants.signUpString) {
            ThyroCard {
                ThyroidVectorArt()
                    .frame(maxWidth: .infinity)

                ThyroSectionTitle("Create Account", subtitle: "Set up your ThyroCare profile before starting the questionnaire.")

                OpenTextField(title: Constants.usernameString, text: $username)

                SecureField(Constants.passwordString, text: $password)
                    .padding()
                    .background(ThyroUI.softGray)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                OpenTextField(title: Constants.emailString, text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()

                if let message = store?.errorMessage, !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(ThyroUI.coral)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                Text("Use at least 12 characters for your password.").font(.footnote)

                LandingButton(title: Constants.createAccountString) {
                    if let store {
                        Task { await store.authenticate(email: email, password: password, name: username, register: true) }
                    }
                }
            }
        }
    }
}

#Preview {
    SignUpPage()
        .environmentObject(AuthManager())
}
