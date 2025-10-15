//
//  SettingsViewModel.swift
//  FlexLog
//
//  Created by Вадим Дзюба на 01.10.2025.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isDarkMode: Bool
    @Published var remindersEnabled: Bool
    @Published var reminderTime: Date
    @Published var errorMessage: String?
    @Published var useSystemAppearance: Bool

    private let notificationService: NotificationService
    private var cancellables: Set<AnyCancellable> = []

    init(notificationService: NotificationService? = nil) {
        self.notificationService = notificationService ?? .shared
        if let storedMode = UserDefaults.standard.object(forKey: Keys.darkMode) as? Bool {
            self.isDarkMode = storedMode
            self.useSystemAppearance = false
        } else {
            self.isDarkMode = Self.systemInterfaceStyle == .dark
            self.useSystemAppearance = true
        }
        self.remindersEnabled = UserDefaults.standard.bool(forKey: Keys.remindersEnabled)
        let storedTime = UserDefaults.standard.object(forKey: Keys.reminderTime) as? Date
        self.reminderTime = storedTime ?? Self.defaultReminder

        applyInterfaceStyle()
        observeLifecycle()
    }

    func toggleDarkMode(_ isOn: Bool) {
        if useSystemAppearance {
            setUseSystemAppearance(false)
        }
        isDarkMode = isOn
        UserDefaults.standard.set(isOn, forKey: Keys.darkMode)
        applyInterfaceStyle()
    }

    func setUseSystemAppearance(_ isOn: Bool) {
        useSystemAppearance = isOn
        if isOn {
            UserDefaults.standard.removeObject(forKey: Keys.darkMode)
            syncWithSystemAppearance()
        } else {
            UserDefaults.standard.set(isDarkMode, forKey: Keys.darkMode)
            applyInterfaceStyle()
        }
    }

    func toggleReminders(_ isOn: Bool) {
        remindersEnabled = isOn
        UserDefaults.standard.set(isOn, forKey: Keys.remindersEnabled)

        Task {
            if isOn {
                do {
                    try await notificationService.scheduleDailyReminder(at: reminderTime)
                    saveReminderTime(reminderTime)
                } catch {
                    remindersEnabled = false
                    UserDefaults.standard.set(false, forKey: Keys.remindersEnabled)
                    notificationService.cancelDailyReminder()
                    errorMessage = error.localizedDescription
                }
            } else {
                notificationService.cancelDailyReminder()
                clearReminderTime()
            }
        }
    }

    func updateReminderTime(_ newValue: Date) {
        reminderTime = newValue
        saveReminderTime(newValue)

        Task {
            guard remindersEnabled else { return }
            do {
                try await notificationService.scheduleDailyReminder(at: newValue)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleSystemAppearanceChange(_ scheme: ColorScheme) {
        guard useSystemAppearance else { return }
        let isDark = scheme == .dark
        if isDarkMode != isDark {
            isDarkMode = isDark
            applyInterfaceStyle()
        }
    }

    private func applyInterfaceStyle() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        if useSystemAppearance {
            windowScene.keyWindow?.overrideUserInterfaceStyle = .unspecified
        } else {
            windowScene.keyWindow?.overrideUserInterfaceStyle = isDarkMode ? .dark : .light
        }
    }

    private func saveReminderTime(_ date: Date) {
        UserDefaults.standard.set(date, forKey: Keys.reminderTime)
    }

    private func clearReminderTime() {
        UserDefaults.standard.removeObject(forKey: Keys.reminderTime)
    }

    private func observeLifecycle() {
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.syncWithSystemAppearance()
            }
            .store(in: &cancellables)
    }

    private func syncWithSystemAppearance() {
        guard useSystemAppearance else { return }
        let systemDark = Self.systemInterfaceStyle == .dark
        if isDarkMode != systemDark {
            isDarkMode = systemDark
        }
        applyInterfaceStyle()
    }
}

private extension SettingsViewModel {
    static var defaultReminder: Date {
        var components = DateComponents()
        components.hour = 18
        components.minute = 30
        return Calendar.current.date(from: components) ?? Date()
    }

    static var systemInterfaceStyle: UIUserInterfaceStyle {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let style = scene.keyWindow?.traitCollection.userInterfaceStyle else {
            return .unspecified
        }
        return style
    }

    enum Keys {
        static let darkMode = "flexlog.isDarkMode"
        static let remindersEnabled = "flexlog.remindersEnabled"
        static let reminderTime = "flexlog.reminderTime"
    }
}
