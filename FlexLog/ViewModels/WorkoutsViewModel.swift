//
//  WorkoutsViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import Combine

@MainActor
final class WorkoutsViewModel: ObservableObject {
    @Published private(set) var templates: [WorkoutTemplateDetail] = []
    @Published var searchText: String = "" {
        didSet { applyFilter() }
    }
    @Published private(set) var filteredTemplates: [WorkoutTemplateDetail] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var isLoading = false

    private let workoutService: WorkoutDataService

    init(workoutService: WorkoutDataService? = nil) {
        self.workoutService = workoutService ?? WorkoutDataService.shared
    }

    func loadTemplates() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            try workoutService.bootstrapDefaultsIfNeeded()
            templates = try workoutService.fetchTemplateDetails()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func templateDetail(id: UUID) -> WorkoutTemplateDetail? {
        try? workoutService.templateDetail(id: id)
    }

    func clearError() {
        errorMessage = nil
    }

    private func applyFilter() {
        let text = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            filteredTemplates = templates
            return
        }
        filteredTemplates = templates.filter { template in
            template.name.localizedCaseInsensitiveContains(text) ||
            template.focusLabel.localizedCaseInsensitiveContains(text)
        }
    }
}
