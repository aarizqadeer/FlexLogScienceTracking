//
//  PlansViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import Combine

@MainActor
final class PlansViewModel: ObservableObject {
    @Published private(set) var plans: [WorkoutPlanDetail] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let workoutService: WorkoutDataService

    init(workoutService: WorkoutDataService? = nil) {
        self.workoutService = workoutService ?? WorkoutDataService.shared
    }

    func loadPlans() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try workoutService.bootstrapDefaultsIfNeeded()
            plans = try workoutService.fetchPlans(referenceDate: Date())
        } catch {
            errorMessage = error.localizedDescription
            plans = []
        }
    }

    func clearError() {
        errorMessage = nil
    }

    func createQuickPlan(workoutsPerWeek: Int,
                         exercisesPerWorkout: Int,
                         targetDuration: Int,
                         targetVolume: Int) async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try workoutService.createQuickPlan(name: makePlanName(),
                                               workoutsPerWeek: workoutsPerWeek,
                                               exercisesPerWorkout: exercisesPerWorkout,
                                               targetDuration: targetDuration,
                                               targetVolume: targetVolume)
            plans = try workoutService.fetchPlans(referenceDate: Date())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func makePlanName() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return "Plan \(formatter.string(from: Date()))"
    }
}
