import SwiftUI

struct VerificationPage: View {
    @State private var code: Int = 0
    @State private var verified = false

    var body: some View {
        ThyroPageScaffold(title: "Verification") {
            ThyroCard {
                LabVectorArt()
                    .frame(maxWidth: .infinity)

                ThyroSectionTitle("Enter code", subtitle: Constants.verificationPageInstructions)

                OpenTextField("Code", $code)

                LandingButton(title: "Verify Code") {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        verified = true
                    }
                }
            }

            if verified {
                ThyroCard {
                    MetricRow(title: "Verification", value: "Complete", color: ThyroUI.teal)
                    Text("Your account is ready to continue.")
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

#Preview {
    VerificationPage()
}
