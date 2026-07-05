import SwiftUI

struct SignUpPage: View {
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

                if !authManager.accountMessage.isEmpty {
                    Text(authManager.accountMessage)
                        .font(.footnote)
                        .foregroundStyle(ThyroUI.coral)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                }

                LandingButton(title: Constants.createAccountString) {
                    authManager.signUp(username: username, email: email, password: password)
                }
            }
        }
    }
}

#Preview {
    SignUpPage()
        .environmentObject(AuthManager())
}
