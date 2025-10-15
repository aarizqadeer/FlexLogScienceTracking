//
//  PlansView.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct PlansView: View {
    @StateObject private var viewModel: PlansViewModel
    @State private var showingConfigurator = false
    @State private var workoutsPerWeek: Double = 3
    @State private var exercisesPerWorkout: Double = 8
    @State private var sessionDuration: Double = 60
    @State private var weeklyVolume: Double = 5000

    init(viewModel: PlansViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.plans.isEmpty {
                    emptyState
                } else {
                    ForEach(viewModel.plans) { plan in
                        WorkoutPlanRow(plan: plan)
                            .listRowInsets(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                            .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.plain)
            .background(Color.flexBackground.ignoresSafeArea())
            .navigationTitle("Plans")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingConfigurator = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.clearError() }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
        .task { await viewModel.loadPlans() }
        .sheet(isPresented: $showingConfigurator) {
            NavigationStack {
                Form {
                    Section("Weekly structure") {
                        Stepper(value: $workoutsPerWeek, in: 1...14, step: 1) {
                            HStack {
                                Label("Workouts per week", systemImage: "calendar.badge.plus")
                                Spacer()
                                Text("\(Int(workoutsPerWeek))")
                                    .font(.headline)
                            }
                        }

                        Stepper(value: $exercisesPerWorkout, in: 1...25, step: 1) {
                            HStack {
                                Label("Exercises per workout", systemImage: "list.bullet")
                                Spacer()
                                Text("\(Int(exercisesPerWorkout))")
                                    .font(.headline)
                            }
                        }
                    }

                    Section("Targets") {
                        Stepper(value: $sessionDuration, in: 10...180, step: 5) {
                            HStack {
                                Label("Duration per workout", systemImage: "timer")
                                Spacer()
                                Text("\(Int(sessionDuration)) min")
                                    .font(.headline)
                            }
                        }

                        Stepper(value: $weeklyVolume, in: 500...20000, step: 250) {
                            HStack {
                                Label("Weekly volume", systemImage: "scalemass")
                                Spacer()
                                Text("\(Int(weeklyVolume)) lbs")
                                    .font(.headline)
                            }
                        }
                    }
                }
                .navigationTitle("New Plan")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") { showingConfigurator = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            Task {
                                await viewModel.createQuickPlan(workoutsPerWeek: Int(workoutsPerWeek),
                                                                exercisesPerWorkout: Int(exercisesPerWorkout),
                                                                targetDuration: Int(sessionDuration),
                                                                targetVolume: Int(weeklyVolume))
                            }
                            showingConfigurator = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var emptyState: some View {
        VStack(alignment: .center, spacing: 12) {
            Image(systemName: "calendar")
                .font(.largeTitle)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
            Text("No plans yet")
                .font(.headline)
            Text("Create a workout plan to track your training schedule.")
                .font(.subheadline)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .listRowSeparator(.hidden)
    }
}

struct WorkoutPlanRow: View {
    let plan: WorkoutPlanDetail

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.headline)
                        .foregroundStyle(Color.flexOnSurface)
                    Text(plan.timeline)
                        .font(.subheadline)
                        .foregroundStyle(Color.flexOnSurfaceSecondary)
                }
                Spacer()
                Text("\(plan.sessionsPerWeek)x/week")
                    .font(.caption)
                    .foregroundStyle(Color.flexOnSurfaceSecondary)
            }
            VStack(alignment: .leading, spacing: 8) {
                ProgressView(value: plan.progress) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(Color.flexOnSurfaceSecondary)
                }
                .progressViewStyle(.linear)
                .tint(Color.flexPrimary)

                HStack {
                    Label("Completed: \(plan.completedSessions)", systemImage: "checkmark.circle.fill")
                    Spacer()
                    Label("Target: \(plan.totalSessionsTarget)", systemImage: "target")
                }
                .font(.caption)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.06), radius: 8, y: 4)
        )
    }
}

#Preview {
    PlansView(viewModel: PlansViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
