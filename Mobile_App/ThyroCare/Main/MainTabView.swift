import SwiftUI

/// The five-destination workspace replaces the legacy seven-tab navigation.
struct MainTabView: View {
    let store: CareStore
    var body: some View {
        CareTabs(store: store)
    }
}
