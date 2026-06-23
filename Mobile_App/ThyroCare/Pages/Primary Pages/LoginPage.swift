import SwiftUI

struct LoginPage: View {

    @State private var username = ""
    @State private var password = ""
    
    @EnvironmentObject private var authManager: AuthManager
    private var startString: String {
        authManager.accountExists(username: username) ? Constants.welcomeBackString : Constants.loginString
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ThyroCareLogo(width: Constants.logoWidth, height: Constants.logoHeight)

                Text(startString)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.black)

                VStack(spacing: 18) {
                    OpenTextField(title: Constants.usernameString, text: $username)

                    SecureField(Constants.passwordString, text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 36)

                if !authManager.accountMessage.isEmpty {
                    Text(authManager.accountMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    NavigationLink("Sign Up") {
                        SignUpPage()
                    }
                    .foregroundStyle(.blue)
                }

                LandingButton(title: startString) {
                    authManager.logIn(username: username, password: password)
                }
                .padding(.horizontal, 36)
                .padding(.top, 12)
                NavigationLink("Forgot Password") {
                    ForgotPasswordPage()
                }
                .foregroundStyle(.blue)

                Spacer()
            }
        }
    }
}

#Preview {
    LoginPage()
        .environmentObject(AuthManager())
}
