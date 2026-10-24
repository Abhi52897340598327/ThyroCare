import SwiftUI

struct LoginPage: View {
    var store: CareStore?

    @State private var username = ""
    @State private var password = ""
    
    @EnvironmentObject private var authManager: AuthManager
    private var startString: String {
        Constants.loginString
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
                    OpenTextField(title: store == nil ? Constants.usernameString : Constants.emailString, text: $username)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    SecureField(Constants.passwordString, text: $password)
                        .padding()
                        .background(Color.gray.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 36)

                if let message = store?.errorMessage, !message.isEmpty {
                    Text(message)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 36)
                    NavigationLink("Sign Up") {
                        SignUpPage(store: store)
                    }
                    .foregroundStyle(.blue)
                }

                LandingButton(title: startString) {
                    if let store {
                        Task { await store.authenticate(email: username, password: password, name: "", register: false) }
                    }
                }
                .disabled(store?.isWorking == true)
                .padding(.horizontal, 36)
                .padding(.top, 12)
                Button("Forgot Password") {
                    store?.errorMessage = "Password recovery is not yet connected. Contact support for account assistance."
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
