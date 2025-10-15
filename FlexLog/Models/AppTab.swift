//
//  AppTab.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case workouts
    case progress
    case plans
    case settings

    var id: String { rawValue }
}








