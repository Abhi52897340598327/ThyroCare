//
//  VerifiedUserPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/30/26.
//

// basically page without the login or signup option

import SwiftUI

struct VerifiedUserPage: View {
    let onViewDashboard: () -> Void

    init(onViewDashboard: @escaping () -> Void = {}) {
        self.onViewDashboard = onViewDashboard
    }

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 70)

                ThyroCareLogo(width: 260, height: 260)

                Text(Constants.appName)
                    .font(.system(size: 36, weight: .regular))
                    .foregroundStyle(.black)
                    .padding(.top, 28)

                Spacer(minLength: 80)

                VStack(spacing: 34) {
                    LandingButton(title: Constants.buttonTitles[2], action: onViewDashboard)
                }
                .padding(.horizontal, 36)

                Spacer(minLength: 96)
            }
        }
    }
}

#Preview {
    VerifiedUserPage()
}
