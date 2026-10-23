import SwiftUI

@main
struct ThyroCareApp: App {
    @UIApplicationDelegateAdaptor(CareAppDelegate.self) private var appDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
