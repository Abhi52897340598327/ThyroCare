//
//  MainTabView.swift
//  ThyroCare
//
//  Created by Abhiraam Venigalla on 5/26/26.
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: AppTab.MainTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab(Constants.homeString, systemImage: Constants.homeImage, value: AppTab.MainTab.home) {
                VerifiedUserPage {
                    selectedTab = .dashboard
                }
            }
            
            Tab(Constants.questionaireString, systemImage: Constants.questionaireImage, value: AppTab.MainTab.questionaire) {
                NavigationStack {
                    QuestionairePage()
                }
            }

            Tab(Constants.summaryString, systemImage: Constants.summaryImage, value: AppTab.MainTab.summary) {
                SummaryPage()
            }
            
            Tab(Constants.dashboardString, systemImage: Constants.dashboardImage, value: AppTab.MainTab.dashboard) {
                DashboardPage {
                    selectedTab = .home
                }
            }

            Tab(Constants.predictionString, systemImage: Constants.diagnosisImage, value: AppTab.MainTab.prediction) {
                PredictionPage()
            }

            Tab(Constants.pictureString, systemImage: Constants.pictureImage, value: AppTab.MainTab.picture) {
                NavigationStack {
                    PicturePage()
                }
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthManager())
}
