//
//  SettingsView.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import SwiftUI
import CoreData

struct SettingsView: View {
    init(viewModel: SettingsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    @StateObject private var viewModel: SettingsViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle(isOn: Binding(
                        get: { viewModel.useSystemAppearance },
                        set: { viewModel.setUseSystemAppearance($0) }
                    )) {
                        Label("Match System", systemImage: "iphone").foregroundColor(.flexOnSurface)
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.flexPrimary))

                    Toggle(isOn: Binding(
                        get: { viewModel.isDarkMode },
                        set: { viewModel.toggleDarkMode($0) }
                    )) {
                        Label("Dark Mode", systemImage: "moon.stars.fill")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.flexPrimary))
                    .disabled(viewModel.useSystemAppearance)
                }

                Section("Reminders") {
                    Toggle(isOn: Binding(
                        get: { viewModel.remindersEnabled },
                        set: { viewModel.toggleReminders($0) }
                    )) {
                        Label("Workout reminders", systemImage: "bell.badge.fill")
                    }
                    .toggleStyle(SwitchToggleStyle(tint: Color.flexPrimary))

                    if viewModel.remindersEnabled {
                        DatePicker(
                            "Reminder time",
                            selection: Binding(
                                get: { viewModel.reminderTime },
                                set: { viewModel.updateReminderTime($0) }
                            ),
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.compact)
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0")
                    LabeledContent("Build", value: "1")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.flexBackground)
            .navigationTitle("Settings")
            .alert(item: Binding<AlertMessage?>(
                get: {
                    guard let message = viewModel.errorMessage else { return nil }
                    return AlertMessage(message: message)
                },
                set: { _ in viewModel.errorMessage = nil }
            )) { alert in
                Alert(title: Text("Notifications"), message: Text(alert.message), dismissButton: .default(Text("OK")))
            }
        }
    }
}

private struct AlertMessage: Identifiable {
    let id = UUID()
    let message: String
}

#Preview {
    SettingsView(viewModel: SettingsViewModel())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
