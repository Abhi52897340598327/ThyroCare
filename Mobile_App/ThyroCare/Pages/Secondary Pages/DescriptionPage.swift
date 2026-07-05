import SwiftUI

struct DescriptionPage: View {
    let onContinue: () -> Void

    init(onContinue: @escaping () -> Void = {}) {
        self.onContinue = onContinue
    }

    var body: some View {
        ThyroPageScaffold(title: "Questionaire") {
            ThyroCard {
                ThyroSectionTitle("How ThyroCare works", subtitle: "Answer a few questions so the app can estimate thyroid risk and habits that may affect your labs.")

                LabVectorArt()
                    .frame(maxWidth: .infinity)

                Text("You will enter age, biological sex, recent TSH, T3, and T4 levels, treatment history, medication details, diet balance, and medication timing.")
                    .font(.body)
                    .foregroundStyle(.secondary)

                Toggle("Agree with terms and conditions", isOn: .constant(true))
                    .tint(ThyroUI.teal)
                Toggle("Confirm you're 13 or older", isOn: .constant(true))
                    .tint(ThyroUI.teal)

                LandingButton(title: "Continue", action: onContinue)
            }
        }
    }
}

#Preview {
    DescriptionPage()
}
