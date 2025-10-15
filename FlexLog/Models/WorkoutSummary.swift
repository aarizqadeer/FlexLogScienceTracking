//
//  WorkoutSummary.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

struct WorkoutSummary: Identifiable {
    let id: UUID
    let name: String
    let subtitle: String
    let time: String
    let icon: String

    init(id: UUID = UUID(), name: String, subtitle: String, time: String, icon: String) {
        self.id = id
        self.name = name
        self.subtitle = subtitle
        self.time = time
        self.icon = icon
    }
}

extension WorkoutSummary {
    static let sample: [WorkoutSummary] = [
        WorkoutSummary(name: "Push Day", subtitle: "Chest & Triceps", time: "Today · 6:30 PM", icon: "figure.strengthtraining.traditional"),
        WorkoutSummary(name: "Mobility Flow", subtitle: "Recovery Routine", time: "Tomorrow · 7:00 AM", icon: "figure.cooldown"),
        WorkoutSummary(name: "Pull Day", subtitle: "Back & Biceps", time: "Thu · 6:45 PM", icon: "figure.strengthtraining.functional")
    ]
}








