//
//  ThyroCareApp.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/26/26.
//

import SwiftUI

@main
struct ThyroCareApp: App {
    @StateObject private var authManager = AuthManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .onAppear {
                    authManager.checkSession()
                }
        }
    }
}
