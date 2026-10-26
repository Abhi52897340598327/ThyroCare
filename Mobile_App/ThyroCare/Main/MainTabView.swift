import SwiftUI

/// Original dashboard and presentation, with server-backed account ownership.
struct MainTabView: View {
    let store: CareStore
    @State private var selectedTab: AppTab.MainTab = .home
    @State private var showDailyTasks = false
    // Presentation adapter for the existing dashboard; never used to authenticate.
    @StateObject private var presentationIdentity = AuthManager()

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Constants.homeString, systemImage: Constants.homeImage, value: AppTab.MainTab.home) {
                NavigationStack {
                    if showDailyTasks {
                        DailyTasksView(
                            store: store,
                            onBackToHome: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showDailyTasks = false
                                }
                            },
                            onNavigateToTab: { tab in
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showDailyTasks = false
                                    selectedTab = tab
                                }
                            }
                        )
                    } else {
                        VerifiedUserPage(
                            onViewDashboard: { selectedTab = .dashboard },
                            onOpenDailyTasks: {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    showDailyTasks = true
                                }
                            }
                        )
                    }
                }
            }
            Tab("Questionnaire", systemImage: Constants.questionaireImage, value: AppTab.MainTab.questionaire) {
                NavigationStack {
                    QuestionairePage(store: store, onGoToDashboard: {
                        selectedTab = .dashboard
                    })
                }
            }
            Tab(Constants.dashboardString, systemImage: Constants.dashboardImage, value: AppTab.MainTab.dashboard) {
                DashboardPage(
                    store: store,
                    onNavigateToMessages: { selectedTab = .messages },
                    onNavigateToScanMeal: { selectedTab = .picture }
                ) {
                    Task { await store.logout() }
                }
            }
            Tab(Constants.predictionString, systemImage: Constants.diagnosisImage, value: AppTab.MainTab.prediction) {
                PredictionPage {
                    selectedTab = .dashboard
                }
            }
            Tab(Constants.medicationString, systemImage: Constants.medicationImage, value: AppTab.MainTab.medication) {
                NavigationStack { MedicationLogPage(store: store) }
            }
            Tab(Constants.pictureString, systemImage: Constants.pictureImage, value: AppTab.MainTab.picture) {
                NavigationStack { PicturePage(store: store) }
            }
            Tab(Constants.messagesString, systemImage: Constants.messagesImage, value: AppTab.MainTab.messages) {
                NavigationStack { MessageClinicianPage(store: store) }
            }
        }
        .environmentObject(presentationIdentity)
        .safeAreaInset(edge: .top, alignment: .trailing) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if selectedTab == .home {
                        showDailyTasks.toggle()
                    } else {
                        selectedTab = .home
                        showDailyTasks = true
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: Constants.profileImage).font(.title3)
                    Text(store.session?.user.name ?? Constants.usernameString)
                        .font(.subheadline.weight(.semibold)).lineLimit(1)
                }
                .foregroundStyle(ThyroUI.navy)
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(Color.white.opacity(0.95))
                .clipShape(Capsule())
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 2)
            }
            .accessibilityLabel("Profile and daily tasks")
            .padding(.top, 8).padding(.trailing, 16).padding(.bottom, 8)
        }
        .sheet(isPresented: Binding(get: { store.showQuestionnaire }, set: { store.showQuestionnaire = $0 })) {
            NavigationStack {
                QuestionairePage(store: store, onGoToDashboard: {
                    store.showQuestionnaire = false
                    selectedTab = .dashboard
                })
            }
        }
        .onAppear { presentationIdentity.userName = store.session?.user.name ?? "" }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ThyroCareNavigateToMessages"))) { _ in
            selectedTab = .messages
        }
        .task {
            while !Task.isCancelled {
                await store.synchronize()
                try? await Task.sleep(nanoseconds: 3_000_000_000)
            }
        }
    }
}
