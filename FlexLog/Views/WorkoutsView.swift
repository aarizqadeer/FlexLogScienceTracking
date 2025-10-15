//
//  WorkoutsView.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct WorkoutsView: View {
    @StateObject private var viewModel: WorkoutsViewModel
    @State private var selectedTemplate: WorkoutTemplateDetail?

    init(viewModel: WorkoutsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.filteredTemplates.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.filteredTemplates) { template in
                        Button {
                            selectedTemplate = template
                        } label: {
                            WorkoutTemplateRow(template: template)
                                .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $viewModel.searchText, prompt: "Find workout")
            .navigationTitle("Workouts")
            .background(Color.flexBackground.ignoresSafeArea())
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.clearError() }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateDetailView(template: template)
                    .presentationDetents([.medium, .large])
            }
        }
        .task { await viewModel.loadTemplates() }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.largeTitle)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
            Text("No workouts found")
                .font(.headline)
            Text("Create a workout template to get started.")
                .font(.subheadline)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .listRowSeparator(.hidden)
    }
}

struct WorkoutTemplateRow: View {
    let template: WorkoutTemplateDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.flexPrimary.opacity(0.2))
                    .frame(width: 52, height: 52)
                    .overlay(
                        Image(systemName: template.isFavorite ? "star.fill" : "figure.strengthtraining.traditional")
                            .font(.title3)
                            .foregroundStyle(template.isFavorite ? Color.flexPrimary : Color.flexOnSurfaceSecondary)
                    )
                VStack(alignment: .leading, spacing: 6) {
                    Text(template.name)
                        .font(.headline)
                        .foregroundStyle(Color.flexOnSurface)
                    Text(template.focusLabel)
                        .font(.subheadline)
                        .foregroundStyle(Color.flexOnSurfaceSecondary)
                    Label("\(template.sessionCount) sessions", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundStyle(Color.flexPrimary)
                }
                Spacer()
                Text(template.durationLabel)
                    .font(.caption)
                    .foregroundStyle(Color.flexOnSurfaceSecondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

#Preview {
    WorkoutsView(viewModel: WorkoutsViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
