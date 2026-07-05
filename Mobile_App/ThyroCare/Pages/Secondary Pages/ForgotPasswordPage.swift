import SwiftUI

struct ForgotPasswordPage: View {
    @State private var email = ""
    @State private var sentCode = false

    var body: some View {
        ThyroPageScaffold(title: "Forgot Password?") {
            ThyroCard {
                ThyroidVectorArt()
                    .frame(maxWidth: .infinity)

                ThyroSectionTitle("Reset access", subtitle: Constants.forgotPasswordInstructions)

                OpenTextField(title: Constants.emailString, text: $email)

                LandingButton(title: "Send email") {
                    withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                        sentCode = true
                    }
                }
            }

            if sentCode {
                ThyroCard {
                    ThyroSectionTitle("Check your inbox")
                    Text("A verification code has been prepared for the next step.")
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }
}

#Preview {
    ForgotPasswordPage()
}
