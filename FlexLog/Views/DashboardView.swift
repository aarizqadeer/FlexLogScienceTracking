//
//  DashboardView.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct DashboardView: View {
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTemplate: WorkoutTemplateDetail?
    @State private var showQuickLogSheet = false
    @State private var quickLogDuration: Double = 30
    @State private var quickLogVolume: Double = 0
    @State private var quickLogExercises: Int = 0

    init(viewModel: DashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    statsCard
                    upcomingWorkoutsSection
                    recentSessionsSection
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
            }
            .background(Color.flexBackground.ignoresSafeArea())
            .navigationTitle("Dashboard")
            .toolbar { toolbarContent }
            .alert("Something went wrong", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { _ in viewModel.errorMessage = nil }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateDetailView(template: template) {
                    Task {
                        let volume = generateFixedWorkoutVolume(for: template)
                        await viewModel.addQuickSession(linkedTemplateID: template.id,
                                                        volume: volume,
                                                        duration: 30 * 60,
                                                        exercises: template.exercises.count)
                        selectedTemplate = nil
                    }
                }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showQuickLogSheet) {
                QuickLogSheet(duration: $quickLogDuration,
                              volume: $quickLogVolume,
                              exercises: $quickLogExercises,
                              onSave: {
                                  let durationSeconds = quickLogDuration * 60
                                  Task {
                                      await viewModel.addQuickSession(linkedTemplateID: selectedTemplate?.id,
                                                                       volume: quickLogVolume,
                                                                       duration: durationSeconds,
                                                                       exercises: quickLogExercises)
                                      showQuickLogSheet = false
                                  }
                              })
                .presentationDetents([.medium])
            }
        }
        .task { await viewModel.loadDashboard() }
    }

    private var statsCard: some View {
        let stats = viewModel.stats
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.1), radius: 12, y: 6)
            VStack(alignment: .leading, spacing: 16) {
                Text("Today's Focus")
                    .font(.title3.bold())
                    .foregroundStyle(Color.flexOnSurface)
                Text(stats.todayFocus)
                    .font(.callout)
                    .foregroundStyle(Color.flexOnSurfaceSecondary)
                HStack {
                    statBlock(title: "Sessions", value: "\(stats.weekSessions)")
                    Spacer()
                    statBlock(title: "Volume", value: stats.weekVolume.formatted(.number.precision(.fractionLength(1))) + " lbs")
                    Spacer()
                    statBlock(title: "Streak", value: "\(stats.currentStreak) days")
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: stats.todayFocus)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Color.flexPrimary.opacity(0.7))
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(Color.flexOnSurface)
        }
    }

    private var upcomingWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Upcoming Workouts")
            ForEach(viewModel.upcomingWorkouts) { template in
                Button {
                    selectedTemplate = template
                } label: {
                    UpcomingWorkoutRow(template: template)
                }
                .buttonStyle(.plain)
                .transition(.opacity.combined(with: .move(edge: .trailing)))
            }
            if viewModel.upcomingWorkouts.isEmpty {
                emptyState(message: "Add workouts to your plan to see them here.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var recentSessionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader(title: "Recent Sessions")
            ForEach(viewModel.recentSessions) { session in
                RecentSessionRow(session: session)
            }
            if viewModel.recentSessions.isEmpty {
                emptyState(message: "No sessions logged yet. Tap Quick Log to start.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(Color.flexOnBackground)
            Spacer()
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                quickLogVolume = 0
                quickLogDuration = 30
                quickLogExercises = 0
                showQuickLogSheet = true
            } label: {
                Label("Quick Log", systemImage: "plus.circle.fill")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.flexPrimary)
        }
    }

    private func generateFixedWorkoutVolume(for template: WorkoutTemplateDetail) -> Double {
        // Фиксированные объемы для конкретных тренировок
        if let fixedVolume = getFixedVolume(for: template.name) {
            return fixedVolume
        }

        let exerciseCount = template.exercises.count

        // Базовый объем на упражнение (в фунтах) - фиксированный для каждой тренировки
        let baseVolumePerExercise = 150.0

        // Множитель на основе типа тренировки (focus area) - влияет на итоговый объем
        let focusMultiplier = getFocusMultiplier(for: template.focusArea)

        // Множитель на основе опыта (количество сессий) - прогрессия по мере тренировок
        let experienceMultiplier = getExperienceMultiplier(for: template.sessionCount)

        // Рассчитываем базовый объем на основе количества упражнений
        let baseVolume = Double(exerciseCount) * baseVolumePerExercise

        // Применяем множители для получения фиксированного, но адаптивного объема
        let finalVolume = baseVolume * focusMultiplier * experienceMultiplier

        // Минимальный объем для тренировки - гарантия достаточной нагрузки
        let minVolume = max(400.0, Double(exerciseCount) * 80.0)

        // Возвращаем максимум из рассчитанного объема и минимального
        // Таким образом каждая тренировка имеет фиксированный объем, но адаптированный под её характеристики
        return max(finalVolume, minVolume)
    }

    private func getFixedVolume(for templateName: String) -> Double? {
        let name = templateName.lowercased()

        switch name {
        case "functional core":
            return 750.0
        case "lower body strength":
            return 680.0
        case "push power":
            return 1000.0
        default:
            return nil // Не фиксированный объем, рассчитываем динамически
        }
    }

    private func getFocusMultiplier(for focusArea: String?) -> Double {
        guard let focus = focusArea?.lowercased() else { return 1.0 }

        switch focus {
        case "push":
            return 1.2 // Push тренировки обычно имеют больший объем
        case "pull":
            return 1.1 // Pull тренировки немного меньше
        case "legs":
            return 1.3 // Legs тренировки часто самые тяжелые
        case "upper body", "upper":
            return 1.15
        case "lower body", "lower":
            return 1.25
        case "full body", "full":
            return 1.0 // Стандартный множитель для full body
        case "cardio":
            return 0.8 // Кардио тренировки обычно имеют меньший объем
        case "strength":
            return 1.4 // Силовые тренировки имеют большой объем
        case "power":
            return 1.35 // Power тренировки тоже интенсивные
        default:
            return 1.0
        }
    }

    private func getExperienceMultiplier(for sessionCount: Int) -> Double {
        // На основе количества выполненных сессий корректируем объем
        switch sessionCount {
        case 0...2:
            return 0.9 // Новички - меньше объем
        case 3...10:
            return 1.0 // Средний уровень
        case 11...25:
            return 1.1 // Опытные атлеты
        case 26...50:
            return 1.2 // Продвинутые
        default:
            return 1.25 // Эксперты
        }
    }

    private func emptyState(message: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.title2)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
            Text(message)
                .font(.footnote)
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.04), radius: 6, y: 3)
        )
    }
}

private struct UpcomingWorkoutRow: View {
    let template: WorkoutTemplateDetail

    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.flexPrimary.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: template.isFavorite ? "star.fill" : "figure.strengthtraining.traditional")
                        .font(.headline)
                        .foregroundStyle(template.isFavorite ? Color.flexPrimary : Color.flexOnSurfaceSecondary)
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)
                    .foregroundStyle(Color.flexOnBackground)
                Text(template.focusLabel)
                    .font(.subheadline)
                    .foregroundStyle(Color.flexOnBackgroundSecondary)
                Label("\(template.sessionCount) sessions", systemImage: "flame.fill")
                    .font(.caption)
                    .foregroundStyle(Color.flexPrimary)
            }
            Spacer()
            Text(template.durationLabel)
                .font(.caption)
                .foregroundStyle(Color.flexOnSurfaceSecondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
        )
    }
}

private struct RecentSessionRow: View {
    let session: TrainingSessionSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(session.templateName ?? "Custom Session")
                    .font(.headline)
                    .foregroundStyle(Color.flexOnSurface)
                Spacer()
                Text(session.date, style: .date)
                    .font(.caption)
                    .foregroundStyle(Color.flexOnSurfaceSecondary)
            }
            HStack(spacing: 16) {
                Label(session.totalVolume.formatted(.number.precision(.fractionLength(0))) + " lbs", systemImage: "scalemass")
                Label("\(Int(session.totalDuration / 60)) min", systemImage: "timer")
                Label("\(session.totalExercises) exercises", systemImage: "list.bullet")
            }
            .font(.caption)
            .foregroundStyle(Color.flexOnSurfaceSecondary)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.flexSurface)
                .shadow(color: Color.black.opacity(0.05), radius: 6, y: 3)
        )
    }
}

private struct QuickLogSheet: View {
    @Binding var duration: Double
    @Binding var volume: Double
    @Binding var exercises: Int
    var onSave: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Quick session info") {
                    Stepper(value: $duration, in: 5...240, step: 5) {
                        Label("Duration", systemImage: "timer")
                        Text("\(Int(duration)) min")
                            .font(.callout)
                    }
                    Stepper(value: $volume, in: 0...20000, step: 25) {
                        Label("Volume", systemImage: "scalemass")
                        Text("\(Int(volume)) lbs")
                            .font(.callout)
                    }
                    Stepper(value: $exercises, in: 0...30) {
                        Label("Exercises", systemImage: "list.bullet")
                        Text("\(exercises)")
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Quick Log")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: onSave)
                }
            }
        }
    }
}

struct WorkoutTemplateDetailView: View {
    let template: WorkoutTemplateDetail
    var quickAction: (() -> Void)? = nil

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Overview")) {
                    LabeledContent("Focus", value: template.focusLabel)
                    LabeledContent("Created", value: template.createdAt.formatted(date: .abbreviated, time: .omitted))
                    if let notes = template.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.body)
                    }
                }

                Section(header: Text("Exercises")) {
                    ForEach(template.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(exercise.name)
                                    .font(.headline)
                                Spacer()
                                if let rest = exercise.restInterval {
                                    Label("Rest \(Int(rest))s", systemImage: "hourglass")
                                        .font(.caption)
                                        .foregroundStyle(Color.flexOnSurfaceSecondary)
                                }
                            }
                            if let target = exercise.targetMuscle {
                                Text(target)
                                    .font(.caption)
                                    .foregroundStyle(Color.flexOnSurfaceSecondary)
                            }
                            if let instructions = exercise.instructions {
                                Text(instructions)
                                    .font(.footnote)
                                    .foregroundStyle(Color.flexOnSurfaceSecondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(template.name)
            .toolbar {
                if let quickAction {
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: quickAction) {
                            Label("Log", systemImage: "plus")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DashboardView(viewModel: DashboardViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
