//
//  AppTabViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import Combine

final class AppTabViewModel: ObservableObject {
    @Published var selectedTab: AppTab = .dashboard

    func setupAppearance() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(Color.flexSurface)
        tabBarAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.flexPrimary)
        tabBarAppearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(Color.flexPrimary)
        ]
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
