import SwiftUI

/// Original dashboard and seven-tab presentation, with server-backed account ownership.
struct MainTabView: View {
    let store: CareStore
    @State private var selectedTab: AppTab.MainTab = .home
    @State private var showingRecords = false
    // Presentation adapter for the existing dashboard; never used to authenticate.
    @StateObject private var presentationIdentity = AuthManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Constants.homeString, systemImage: Constants.homeImage, value: AppTab.MainTab.home) {
                VerifiedUserPage { selectedTab = .dashboard }
            }
            Tab("Questionnaire", systemImage: Constants.questionaireImage, value: AppTab.MainTab.questionaire) {
                NavigationStack { QuestionairePage() }
            }
            Tab(Constants.summaryString, systemImage: Constants.summaryImage, value: AppTab.MainTab.summary) {
                SummaryPage()
            }
            Tab(Constants.dashboardString, systemImage: Constants.dashboardImage, value: AppTab.MainTab.dashboard) {
                DashboardPage { Task { await store.logout() } }
            }
            Tab(Constants.predictionString, systemImage: Constants.diagnosisImage, value: AppTab.MainTab.prediction) {
                PredictionPage()
            }
            Tab(Constants.medicationString, systemImage: Constants.medicationImage, value: AppTab.MainTab.medication) {
                MedicationLogPage()
            }
            Tab(Constants.pictureString, systemImage: Constants.pictureImage, value: AppTab.MainTab.picture) {
                NavigationStack { PicturePage() }
            }
        }
        .environmentObject(presentationIdentity)
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button { showingRecords = true } label: {
                HStack(spacing: 6) {
                    Image(systemName: Constants.profileImage).font(.title3)
                    Text(store.session?.user.name ?? Constants.usernameString)
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                .foregroundStyle(.black)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.9))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel("Profile, saved records and care")
            .padding(.top, 8).padding(.trailing, 16).padding(.bottom, 8)
        }
        .sheet(isPresented: $showingRecords) { CareTabs(store: store) }
        .sheet(isPresented: Binding(get: { store.showQuestionnaire }, set: { store.showQuestionnaire = $0 })) {
            NavigationStack { QuestionairePage() }
        }
        .onAppear { presentationIdentity.userName = store.session?.user.name ?? "" }
    }
}
