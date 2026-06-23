//
//  ContentView.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/26/26.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        if authManager.isLoggedIn {
            authenticatedContent
        } else {
            LandingPage {
                authManager.logIn(username: "Guest", password: "guest")
            }
        }
    }

    private var authenticatedContent: some View {
        Group {
            if authManager.shouldShowDescription {
                DescriptionPage {
                    authManager.finishDescription()
                }
            } else {
                MainTabView()
            }
        }
        .safeAreaInset(edge: .top, alignment: .trailing) {
            userIndicator
                .padding(.top, 8)
                .padding(.trailing, 16)
                .padding(.bottom, 8)
        }
    }

    private var userIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: Constants.profileImage)
                .font(.title3)

            Text(authManager.userName.isEmpty ? Constants.usernameString : authManager.userName)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(.black)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.9))
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager())
}
