//
//  ProgressViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import Combine

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published private(set) var metrics: [ProgressMetric] = []
    @Published private(set) var sessions: [TrainingSessionSummary] = []
    @Published private(set) var errorMessage: String?

    private let workoutService: WorkoutDataService

    init(workoutService: WorkoutDataService? = nil) {
        self.workoutService = workoutService ?? WorkoutDataService.shared
    }

    func loadMetrics() async {
        do {
            try workoutService.bootstrapDefaultsIfNeeded()
            sessions = try workoutService.fetchSessions()
            metrics = makeMetrics(from: sessions)
        } catch {
            errorMessage = error.localizedDescription
            metrics = []
        }
    }

    func clearError() {
        errorMessage = nil
    }

    private func makeMetrics(from sessions: [TrainingSessionSummary]) -> [ProgressMetric] {
        guard !sessions.isEmpty else { return [] }
        let calendar = Calendar.current
        let lastSevenDays = sessions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        let volume = lastSevenDays.reduce(0) { $0 + $1.totalVolume }
        let totalSessions = sessions.count
        let streak = calculateStreak(from: sessions.map(\.date))

        return [
            ProgressMetric(title: "Weekly Volume", value: volume.formatted(.number.precision(.fractionLength(0))) + " lbs", trend: trendLabel(value: volume)),
            ProgressMetric(title: "Sessions Completed", value: "\(totalSessions)", trend: trendLabel(value: Double(lastSevenDays.count))),
            ProgressMetric(title: "Current Streak", value: "\(streak) days", trend: streak > 0 ? "+1" : "0"),
            ProgressMetric(title: "Last Session", value: sessions.first?.date.formatted(date: .abbreviated, time: .shortened) ?? "—", trend: "")
        ]
    }

    private func trendLabel(value: Double) -> String {
        guard value > 0 else { return "" }
        return value > 0 ? "+" + value.formatted(.number.precision(.fractionLength(0))) : "0"
    }

    private func calculateStreak(from dates: [Date]) -> Int {
        let calendar = Calendar.current
        let sorted = dates.sorted(by: >)
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for date in sorted {
            let start = calendar.startOfDay(for: date)
            if start == currentDate {
                streak += 1
                guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDate) else { break }
                currentDate = previousDay
            } else if start > currentDate {
                continue
            } else {
                break
            }
        }
        return streak
    }
}
