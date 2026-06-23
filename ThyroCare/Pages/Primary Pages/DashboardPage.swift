//
//  DashboardPage.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 6/13/26.
//

import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject private var authManager: AuthManager
    let onLogout: () -> Void

    init(onLogout: @escaping () -> Void = {}) {
        self.onLogout = onLogout
    }

    var body: some View {
        VStack(spacing: 16) {
            Text("\(Constants.welcomeString) \(authManager.userName)")
                .font(.title2)

            Button(Constants.logoutString) {
                authManager.logOut()
                onLogout()
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    DashboardPage()
        .environmentObject(AuthManager())
}
