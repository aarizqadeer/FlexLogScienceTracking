//
//  WorkoutPlanSummary.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

struct WorkoutPlanSummary: Identifiable {
    let id: UUID
    let name: String
    let timeline: String
    let sessionsPerWeek: Int
    let progress: Double

    init(id: UUID = UUID(), name: String, timeline: String, sessionsPerWeek: Int, progress: Double) {
        self.id = id
        self.name = name
        self.timeline = timeline
        self.sessionsPerWeek = sessionsPerWeek
        self.progress = progress
    }
}

extension WorkoutPlanSummary {
    static let sample: [WorkoutPlanSummary] = [
        WorkoutPlanSummary(name: "Hypertrophy Cycle", timeline: "Sep 15 - Oct 15", sessionsPerWeek: 5, progress: 0.68),
        WorkoutPlanSummary(name: "Mobility Booster", timeline: "Oct 1 - Oct 30", sessionsPerWeek: 3, progress: 0.12),
        WorkoutPlanSummary(name: "Endurance Build", timeline: "Aug 20 - Nov 20", sessionsPerWeek: 4, progress: 0.45)
    ]
}
