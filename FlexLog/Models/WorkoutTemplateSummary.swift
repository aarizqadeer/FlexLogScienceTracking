//
//  WorkoutTemplateSummary.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation

struct WorkoutTemplateSummary: Identifiable {
    let id: UUID
    let name: String
    let focusArea: String
    let duration: String
    let sessionCount: Int
    let isFavorite: Bool

    init(id: UUID = UUID(), name: String, focusArea: String, duration: String, sessionCount: Int, isFavorite: Bool) {
        self.id = id
        self.name = name
        self.focusArea = focusArea
        self.duration = duration
        self.sessionCount = sessionCount
        self.isFavorite = isFavorite
    }
}

extension WorkoutTemplateSummary {
    static let sample: [WorkoutTemplateSummary] = [
        WorkoutTemplateSummary(name: "Push Power", focusArea: "Chest & Triceps", duration: "60 min", sessionCount: 12, isFavorite: true),
        WorkoutTemplateSummary(name: "Lower Body Strength", focusArea: "Legs & Glutes", duration: "70 min", sessionCount: 8, isFavorite: false),
        WorkoutTemplateSummary(name: "Functional Core", focusArea: "Core Stability", duration: "45 min", sessionCount: 10, isFavorite: true)
    ]
}
