//
//  FlexLogApp.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

@main
struct FlexLogApp: App {
    private let persistenceController = PersistenceController.shared
    private let gatekeeper = AppGatekeeper()

    @State private var gatekeeperOutcome: GatekeeperOutcome? = nil
    @UIApplicationDelegateAdaptor(OrientationAppDelegate.self) private var orientationDelegate

    var body: some Scene {
        WindowGroup {
            content
                .task { await determineInitialScreen() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let outcome = gatekeeperOutcome {
            switch outcome {
            case .showTraining(_, let trainingLink):
                TrainingHostView(trainingLink: trainingLink)
            case .showMainApp:
                MainTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        } else {
            Color.black.ignoresSafeArea()
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
        }
    }

    private func determineInitialScreen() async {
        if let cached = gatekeeper.cachedOutcome() {
            await MainActor.run {
                gatekeeperOutcome = cached
                TrainingOrientationManager.configure(for: cached)
            }
            return
        }

        do {
            let decision = try await gatekeeper.bootstrapDecision()
            await MainActor.run {
                gatekeeperOutcome = decision
                TrainingOrientationManager.configure(for: decision)
            }
        } catch {
            await MainActor.run {
                gatekeeperOutcome = .showMainApp
                TrainingOrientationManager.configure(for: .showMainApp)
            }
        }
    }
}
