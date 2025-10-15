//
//  DashboardViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import Combine

@MainActor
final class DashboardViewModel: ObservableObject {
    struct DashboardStats {
        let todayFocus: String
        let weekSessions: Int
        let weekVolume: Double
        let currentStreak: Int
    }

    @Published private(set) var stats: DashboardStats = .init(todayFocus: "Recovery", weekSessions: 0, weekVolume: 0, currentStreak: 0)
    @Published private(set) var upcomingWorkouts: [WorkoutTemplateDetail] = []
    @Published private(set) var recentSessions: [TrainingSessionSummary] = []
    @Published var errorMessage: String?
    @Published var isLoading = false

    private let workoutService: WorkoutDataService

    init(workoutService: WorkoutDataService? = nil) {
        self.workoutService = workoutService ?? WorkoutDataService.shared
    }

    func loadDashboard() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try workoutService.bootstrapDefaultsIfNeeded()
            let templates = try workoutService.fetchTemplateDetails()
            let sessions = try workoutService.fetchSessions()
            upcomingWorkouts = Array(templates.prefix(3))
            recentSessions = Array(sessions.prefix(5))
            stats = makeStats(from: sessions, templates: templates)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addQuickSession(linkedTemplateID: UUID? = nil,
                         volume: Double,
                         duration: TimeInterval,
                         exercises: Int) async {
        do {
            let session = try workoutService.createQuickSession(linkedTemplateID: linkedTemplateID,
                                                               volume: volume,
                                                               duration: duration,
                                                               exercises: exercises)
            recentSessions.insert(session, at: 0)
            recentSessions = Array(recentSessions.prefix(5))

            // Обновляем статистику для всех шаблонов после создания сессии
            updateTemplateStats()

            stats = makeStats(from: recentSessions, templates: upcomingWorkouts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func updateTemplateStats() {
        // Обновляем sessionCount для каждого шаблона в upcomingWorkouts
        for index in upcomingWorkouts.indices {
            if let updatedTemplate = try? workoutService.templateDetail(id: upcomingWorkouts[index].id) {
                upcomingWorkouts[index] = updatedTemplate
            }
        }
    }

    func templateDetail(for id: UUID) -> WorkoutTemplateDetail? {
        try? workoutService.templateDetail(id: id)
    }

    func clearError() {
        errorMessage = nil
    }

    private func makeStats(from sessions: [TrainingSessionSummary], templates: [WorkoutTemplateDetail]) -> DashboardStats {
        let calendar = Calendar.current
        let thisWeek = sessions.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear) }
        let weekSessions = thisWeek.count
        let weekVolume = thisWeek.reduce(0) { $0 + $1.totalVolume }

        let streak = calculateStreak(from: sessions.map(\.date))
        let todayFocus = templates.first?.focusLabel ?? "Recovery"

        return DashboardStats(
            todayFocus: todayFocus,
            weekSessions: weekSessions,
            weekVolume: weekVolume,
            currentStreak: streak
        )
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
