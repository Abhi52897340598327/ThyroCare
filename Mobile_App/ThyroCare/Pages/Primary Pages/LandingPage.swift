//
//  LandingPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/26/26.
//

import SwiftUI

struct LandingPage: View {
    let onAuthenticated: () -> Void

    @State private var showingLogin = false
    @State private var showingSignUp = false

    init(onAuthenticated: @escaping () -> Void = {}) {
        self.onAuthenticated = onAuthenticated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: 70)

                    ThyroCareLogo(width: Constants.logoWidth, height: Constants.logoHeight)

                    Text(Constants.appName)
                        .font(.system(size: 36, weight: .regular))
                        .foregroundStyle(.black)
                        .padding(.top, 28)

                    Spacer(minLength: 80)

                    VStack(spacing: 34) {
                        LandingButton(title: Constants.buttonTitles[0]) {
                            showingLogin = true
                        }

                        LandingButton(title: Constants.buttonTitles[1]) {
                            showingSignUp = true
                        }
                    }
                    .padding(.horizontal, 36)

                    Spacer(minLength: 96)
                }
            }
            .navigationDestination(isPresented: $showingLogin) {
                LoginPage()
            }
            .navigationDestination(isPresented: $showingSignUp) {
                SignUpPage()
            }
        }
    }
}

#Preview {
    LandingPage()
        .environmentObject(AuthManager())
}
