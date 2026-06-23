import SwiftUI
import Combine

final class AuthManager: ObservableObject {
    @Published var isLoggedIn = false
    @Published var userName = ""
    @Published var shouldShowDescription = false
    @Published var accountMessage = ""

    private let activeUserNameKey = "userName"
    private let registeredUserNameKey = "registeredUserName"
    private let registeredEmailKey = "registeredEmail"

    func checkSession() {
        if let savedUserName = UserDefaults.standard.string(forKey: activeUserNameKey) {
            userName = savedUserName
            isLoggedIn = true
        } else {
            isLoggedIn = false
        }
    }

    func accountExists(username: String) -> Bool {
        let normalizedUsername = username.trimmedAndLowercased
        let savedUsername = UserDefaults.standard.string(forKey: registeredUserNameKey)?.trimmedAndLowercased

        return !normalizedUsername.isEmpty && normalizedUsername == savedUsername
    }

    func accountExists(username: String, email: String) -> Bool {
        let normalizedEmail = email.trimmedAndLowercased
        let savedEmail = UserDefaults.standard.string(forKey: registeredEmailKey)?.trimmedAndLowercased

        return accountExists(username: username) ||
            (!normalizedEmail.isEmpty && normalizedEmail == savedEmail)
    }

    func logIn(username: String, password: String) {
        guard !username.isEmpty, !password.isEmpty else {
            isLoggedIn = false
            accountMessage = "Please enter your username and password."
            return
        }

        guard accountExists(username: username) else {
            isLoggedIn = false
            shouldShowDescription = false
            accountMessage = "No account found for that username."
            return
        }

        userName = username
        isLoggedIn = true
        shouldShowDescription = false
        accountMessage = ""
        UserDefaults.standard.set(username, forKey: activeUserNameKey)
    }

    func signUp(username: String, email: String, password: String) {
        guard !username.isEmpty, !email.isEmpty, !password.isEmpty else {
            isLoggedIn = false
            accountMessage = "Please fill in all fields."
            return
        }

        guard !accountExists(username: username, email: email) else {
            isLoggedIn = false
            shouldShowDescription = false
            accountMessage = "An account already exists for that username or email."
            return
        }

        userName = username
        isLoggedIn = true
        shouldShowDescription = true
        accountMessage = ""
        UserDefaults.standard.set(username, forKey: activeUserNameKey)
        UserDefaults.standard.set(username, forKey: registeredUserNameKey)
        UserDefaults.standard.set(email, forKey: registeredEmailKey)
    }

    func finishDescription() {
        shouldShowDescription = false
    }

    func logOut() {
        userName = ""
        isLoggedIn = false
        shouldShowDescription = false
        accountMessage = ""
        UserDefaults.standard.removeObject(forKey: activeUserNameKey)
    }
}

private extension String {
    var trimmedAndLowercased: String {
        trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
