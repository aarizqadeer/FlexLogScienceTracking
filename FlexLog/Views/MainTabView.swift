//  MainTabView.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct MainTabView: View {
    @StateObject private var viewModel = AppTabViewModel()

    var body: some View {
        TabView(selection: $viewModel.selectedTab) {
            DashboardView(viewModel: DashboardViewModel())
                .tabItem {
                    Label("Dashboard", systemImage: "chart.bar.xaxis")
                }
                .tag(AppTab.dashboard)

            WorkoutsView(viewModel: WorkoutsViewModel())
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell")
                }
                .tag(AppTab.workouts)

            ProgressScreen(viewModel: ProgressViewModel())
                .tabItem {
                    Label("Progress", systemImage: "chart.pie.fill")
                }
                .tag(AppTab.progress)

            PlansView(viewModel: PlansViewModel())
                .tabItem {
                    Label("Plans", systemImage: "calendar")
                }
                .tag(AppTab.plans)

            SettingsView(viewModel: SettingsViewModel())
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(AppTab.settings)
        }
        .accentColor(Color.flexPrimary)
        .onAppear { viewModel.setupAppearance() }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
