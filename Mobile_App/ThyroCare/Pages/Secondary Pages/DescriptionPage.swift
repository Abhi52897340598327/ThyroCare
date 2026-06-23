//
//  DescriptionPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/30/26.
//

import SwiftUI

struct DescriptionPage: View {
    let onContinue: () -> Void

    init(onContinue: @escaping () -> Void = {}) {
        self.onContinue = onContinue
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 34) {
                Spacer()

                Text(Constants.descriptionAppString)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.black)
                    .multilineTextAlignment(.center)

                LandingButton(title: Constants.proceduralString, action: onContinue)

                Spacer()
            }
            .padding(.horizontal, 36)
        }
    }
}

#Preview {
    DescriptionPage()
}
