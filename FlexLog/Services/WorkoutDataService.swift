//
//  WorkoutDataService.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import CoreData

struct ExerciseDetail: Identifiable, Hashable {
    let id: UUID
    let name: String
    let targetMuscle: String?
    let instructions: String?
    let restInterval: TimeInterval?
    let order: Int?
}

struct WorkoutTemplateDetail: Identifiable, Hashable {
    let id: UUID
    let name: String
    let focusArea: String?
    let notes: String?
    let colorHex: String?
    let createdAt: Date
    let updatedAt: Date?
    let isFavorite: Bool
    let exercises: [ExerciseDetail]
    let sessionCount: Int

    var durationLabel: String {
        let totalExercises = exercises.count
        guard totalExercises > 0 else { return "45 min" }
        let estimate = max(30, totalExercises * 10)
        return "≈ \(estimate) min"
    }

    var focusLabel: String {
        focusArea ?? "Full body"
    }
}

struct TrainingEntrySummary: Identifiable {
    let id: UUID
    let exerciseName: String
    let sets: Int
    let reps: Int
    let weight: Double
    let duration: TimeInterval
    let totalVolume: Double
}

struct TrainingSessionSummary: Identifiable {
    let id: UUID
    let date: Date
    let duration: TimeInterval
    let templateName: String?
    let notes: String?
    let entries: [TrainingEntrySummary]
    let loggedVolume: Double?
    let loggedDuration: TimeInterval?
    let loggedExercises: Int?

    var totalVolume: Double {
        loggedVolume ?? entries.reduce(0) { $0 + $1.totalVolume }
    }

    var totalExercises: Int {
        loggedExercises ?? entries.count
    }

    var totalDuration: TimeInterval {
        loggedDuration ?? max(duration, entries.reduce(0) { $0 + $1.duration })
    }
}

struct WorkoutPlanDetail: Identifiable {
    let id: UUID
    let name: String
    let startDate: Date?
    let endDate: Date?
    let schedule: String?
    let notes: String?
    let templates: [WorkoutTemplateDetail]
    let workoutsPerWeek: Int
    let completedSessions: Int
    let totalSessionsTarget: Int

    var sessionsPerWeek: Int {
        max(workoutsPerWeek, templates.count)
    }

    var progress: Double {
        guard totalSessionsTarget > 0 else { return 0 }
        return min(1, Double(completedSessions) / Double(totalSessionsTarget))
    }

    var timeline: String {
        switch (startDate, endDate) {
        case let (start?, end?):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
        case let (start?, nil):
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "From \(formatter.string(from: start))"
        default:
            return "No schedule"
        }
    }
}

enum WorkoutDataServiceError: LocalizedError {
    case templateNotFound
    case coreDataError(Error)

    var errorDescription: String? {
        switch self {
        case .templateNotFound:
            return "Unable to find the requested workout."
        case .coreDataError(let error):
            return error.localizedDescription
        }
    }
}

final class WorkoutDataService {
    static let shared = WorkoutDataService(context: PersistenceController.shared.container.viewContext)

    private let context: NSManagedObjectContext
    private let defaults: UserDefaults

    private struct DefaultsKey {
        static let seededTemplates = "flexlog.seededDefaultTemplates"
    }

    private struct PlanWindow {
        let start: Date
        let endExclusive: Date
        let weeks: Int
    }

    init(context: NSManagedObjectContext, defaults: UserDefaults = .standard) {
        self.context = context
        self.defaults = defaults
    }

    func bootstrapDefaultsIfNeeded() throws {
        let fetchRequest: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        fetchRequest.fetchLimit = 1

        if try context.count(for: fetchRequest) > 0 { return }
        if defaults.bool(forKey: DefaultsKey.seededTemplates) { return }

        let now = Date()

        let templatePayloads: [(name: String, focus: String, color: String, isFavorite: Bool, exercises: [(String, String, String, Int)])] = [
            (
                name: "Push Power",
                focus: "Chest & Triceps",
                color: "FF6B35",
                isFavorite: true,
                exercises: [
                    ("Barbell Bench Press", "Chest", "4×8 @ moderate weight", 90),
                    ("Incline Dumbbell Press", "Chest", "3×10", 75),
                    ("Cable Fly", "Chest", "3×15 slow tempo", 60),
                    ("Dips", "Triceps", "3×AMRAP", 60),
                    ("Overhead Triceps Extension", "Triceps", "3×12", 60)
                ]
            ),
            (
                name: "Lower Body Strength",
                focus: "Legs & Glutes",
                color: "FF8C42",
                isFavorite: false,
                exercises: [
                    ("Back Squat", "Quads", "5×5 heavy", 120),
                    ("Romanian Deadlift", "Hamstrings", "4×8", 90),
                    ("Walking Lunges", "Glutes", "3×12 per leg", 75),
                    ("Leg Press", "Quads", "3×15", 60),
                    ("Calf Raises", "Calves", "4×20", 45)
                ]
            ),
            (
                name: "Functional Core",
                focus: "Core Stability",
                color: "FFA552",
                isFavorite: true,
                exercises: [
                    ("Plank", "Core", "4×60 sec hold", 45),
                    ("Hanging Leg Raise", "Core", "4×10", 60),
                    ("Cable Woodchopper", "Obliques", "3×12 each side", 60),
                    ("Swiss Ball Rollout", "Core", "3×15", 60),
                    ("Farmer Carry", "Full Body", "4×40m", 90)
                ]
            )
        ]

        for payload in templatePayloads {
            let template = WorkoutTemplate(context: context)
            template.id = UUID()
            template.name = payload.name
            template.focusArea = payload.focus
            template.colorHex = payload.color
            template.isFavorite = payload.isFavorite
            template.createdAt = now
            template.updatedAt = now
            template.notes = "Auto-generated default template"

            for (index, exercisePayload) in payload.exercises.enumerated() {
                let exercise = Exercise(context: context)
                exercise.id = UUID()
                exercise.name = exercisePayload.0
                exercise.targetMuscle = exercisePayload.1
                exercise.instructions = exercisePayload.2
                exercise.restInterval = Double(exercisePayload.3)
                exercise.order = Int16(index)
                template.addToExercises(exercise)
            }
        }

        try context.save()
        defaults.set(true, forKey: DefaultsKey.seededTemplates)
    }

    func fetchTemplateDetails() throws -> [WorkoutTemplateDetail] {
        let request: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutTemplate.createdAt, ascending: true)]
        let templates = try context.fetch(request)
        return templates.map(makeTemplateDetail)
    }

    func templateDetail(id: UUID) throws -> WorkoutTemplateDetail {
        let request: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        guard let template = try context.fetch(request).first else {
            throw WorkoutDataServiceError.templateNotFound
        }
        return makeTemplateDetail(template)
    }

    func fetchPlans(referenceDate: Date = Date()) throws -> [WorkoutPlanDetail] {
        let request: NSFetchRequest<WorkoutPlan> = WorkoutPlan.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WorkoutPlan.startDate, ascending: true)]
        let plans = try context.fetch(request)
        return plans.map { plan in
            let templates = (plan.templates as? Set<WorkoutTemplate> ?? []).map(makeTemplateDetail).sorted { $0.createdAt < $1.createdAt }
            let workoutsPerWeek = parseWorkoutsPerWeek(from: plan.schedule, fallback: templates.count)
            let window = makePlanWindow(start: plan.startDate, end: plan.endDate, reference: referenceDate)
            let sessions = fetchSessions(for: plan, between: window.start, and: window.endExclusive)
            let totalWeeks = max(1, window.weeks)
            let totalSessionsTarget = max(1, workoutsPerWeek * totalWeeks)
            let completedSessions = sessions.map(makeSessionSummary).reduce(0) { count, summary in
                let hasLoggedMetrics = (summary.loggedDuration ?? 0) > 0 ||
                    (summary.loggedVolume ?? 0) > 0 ||
                    (summary.loggedExercises ?? 0) > 0
                let hasEntries = !summary.entries.isEmpty
                return hasLoggedMetrics || hasEntries ? count + 1 : count
            }

            return WorkoutPlanDetail(
                id: plan.id ?? UUID(),
                name: plan.name ?? "Untitled",
                startDate: plan.startDate,
                endDate: plan.endDate,
                schedule: plan.schedule,
                notes: plan.notes,
                templates: templates,
                workoutsPerWeek: workoutsPerWeek,
                completedSessions: completedSessions,
                totalSessionsTarget: totalSessionsTarget
            )
        }
    }

    func createQuickPlan(name: String,
                         workoutsPerWeek: Int,
                         exercisesPerWorkout: Int,
                         targetDuration: Int,
                         targetVolume: Int) throws {
        let startDate = Date()
        let endDate = Calendar.current.date(byAdding: .weekOfYear, value: 8, to: startDate)

        let schedule = "\(workoutsPerWeek) workouts/week"
        let notesLines = [
            "Exercises/workout: \(exercisesPerWorkout)",
            "Target duration: \(targetDuration) min",
            "Target volume: \(targetVolume) lbs"
        ]
        let notes = notesLines.joined(separator: "\n")

        let plan = WorkoutPlan(context: context)
        plan.id = UUID()
        plan.name = name
        plan.startDate = startDate
        plan.endDate = endDate
        plan.schedule = schedule
        plan.notes = notes
        plan.isActive = true
        plan.templates = NSSet(array: [])

        try context.save()
    }

    func fetchSessions(since startDate: Date? = nil) throws -> [TrainingSessionSummary] {
        let request: NSFetchRequest<TrainingSession> = TrainingSession.fetchRequest()
        if let startDate {
            request.predicate = NSPredicate(format: "date >= %@", startDate as CVarArg)
        }
        request.sortDescriptors = [NSSortDescriptor(keyPath: \TrainingSession.date, ascending: false)]
        let sessions = try context.fetch(request)
        return sessions.map(makeSessionSummary)
    }

    func createQuickSession(linkedTemplateID: UUID? = nil,
                            volume: Double?,
                            duration: TimeInterval?,
                            exercises: Int?) throws -> TrainingSessionSummary {
        let session = TrainingSession(context: context)
        session.id = UUID()
        session.date = Date()
        session.duration = 0
        session.mood = nil
        session.notes = "Quick log"

        if let templateID = linkedTemplateID,
           let template = try? templateManagedObject(id: templateID) {
            session.template = template
        }

        if let volume {
            session.loggedVolume = volume
        }
        if let duration {
            session.loggedDuration = duration
        }
        if let exercises {
            session.loggedExercises = Int16(exercises)
        }

        try context.save()
        return makeSessionSummary(session)
    }

    private func templateManagedObject(id: UUID) throws -> WorkoutTemplate? {
        let request: NSFetchRequest<WorkoutTemplate> = WorkoutTemplate.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }

    private func makeTemplateDetail(_ template: WorkoutTemplate) -> WorkoutTemplateDetail {
        let exerciseSet = template.exercises as? Set<Exercise> ?? []
        let sortedExercises = exerciseSet.sorted { lhs, rhs in
            Int(lhs.order) < Int(rhs.order)
        }
        let exercises = sortedExercises.map { exercise in
            ExerciseDetail(
                id: exercise.id ?? UUID(),
                name: exercise.name ?? "Exercise",
                targetMuscle: exercise.targetMuscle,
                instructions: exercise.instructions,
                restInterval: exercise.restInterval,
                order: Int(exercise.order)
            )
        }

        return WorkoutTemplateDetail(
            id: template.id ?? UUID(),
            name: template.name ?? "Workout",
            focusArea: template.focusArea,
            notes: template.notes,
            colorHex: template.colorHex,
            createdAt: template.createdAt ?? Date(),
            updatedAt: template.updatedAt,
            isFavorite: template.isFavorite,
            exercises: exercises,
            sessionCount: (template.sessions as? Set<TrainingSession>)?.count ?? 0
        )
    }

    private func makeSessionSummary(_ session: TrainingSession) -> TrainingSessionSummary {
        let entrySet = session.entries as? Set<TrainingEntry> ?? []
        let entries = entrySet.map { entry -> TrainingEntrySummary in
            let entryDuration = entry.time
            let entrySets = Int(entry.sets)
            let entryReps = Int(entry.reps)
            let entryWeight = entry.weight
            let volume = entryWeight * Double(entryReps) * Double(entrySets)

            return TrainingEntrySummary(
                id: entry.id ?? UUID(),
                exerciseName: entry.exercise?.name ?? "",
                sets: entrySets,
                reps: entryReps,
                weight: entryWeight,
                duration: entryDuration,
                totalVolume: volume
            )
        }

        return TrainingSessionSummary(
            id: session.id ?? UUID(),
            date: session.date ?? Date(),
            duration: session.duration,
            templateName: session.template?.name,
            notes: session.notes,
            entries: entries,
            loggedVolume: session.loggedVolume,
            loggedDuration: session.loggedDuration,
            loggedExercises: Int(session.loggedExercises)
        )
    }

    private func parseWorkoutsPerWeek(from schedule: String?, fallback: Int) -> Int {
        guard let schedule else { return max(1, fallback) }
        let components = schedule.components(separatedBy: CharacterSet.decimalDigits.inverted)
        if let number = components.compactMap({ Int($0) }).first {
            return max(1, number)
        }
        return max(1, fallback)
    }

    private func computeTotalWeeks(startDate: Date?, endDate: Date?, referenceDate: Date) -> Int {
        guard let start = startDate else { return 1 }
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start)
        let endCandidate = min(endDate ?? referenceDate, referenceDate)
        guard endCandidate >= startDay else { return 1 }
        let endDay = calendar.startOfDay(for: endCandidate)
        let components = calendar.dateComponents([.weekOfYear], from: startDay, to: endDay)
        let weeks = (components.weekOfYear ?? 0) + 1
        return max(1, weeks)
    }

    private func fetchSessions(for plan: WorkoutPlan,
                               between startDate: Date,
                               and endDate: Date) -> [TrainingSession] {
        let request: NSFetchRequest<TrainingSession> = TrainingSession.fetchRequest()
        let datePredicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)

        if let templates = plan.templates as? Set<WorkoutTemplate>, !templates.isEmpty {
            let templateIDs = templates.compactMap { $0.id }
            let templatePredicate = NSPredicate(format: "template.id IN %@", templateIDs as NSArray)
            let unassignedPredicate = NSPredicate(format: "template == nil")
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                datePredicate,
                NSCompoundPredicate(orPredicateWithSubpredicates: [templatePredicate, unassignedPredicate])
            ])
        } else {
            request.predicate = datePredicate
        }

        do {
            return try context.fetch(request)
        } catch {
            return []
        }
    }

    private func makePlanWindow(start: Date?, end: Date?, reference: Date) -> PlanWindow {
        let calendar = Calendar.current
        let startDay = calendar.startOfDay(for: start ?? reference)
        let endCandidate = min(end ?? reference, reference)
        let rawEndDay = calendar.startOfDay(for: max(startDay, endCandidate))
        let endExclusive = calendar.date(byAdding: .day, value: 1, to: rawEndDay) ?? rawEndDay
        let daySpan = calendar.dateComponents([.day], from: startDay, to: rawEndDay).day ?? 0
        let weeks = max(1, Int(ceil(Double(daySpan + 1) / 7.0)))
        return PlanWindow(start: startDay, endExclusive: endExclusive, weeks: weeks)
    }
}
