//
//  NotificationService.swift
//  FlexLog
//
//  Created by Вадим Дзюба on 01.10.2025.
//

import Foundation
import UserNotifications

final class NotificationService {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private init() {}

    func requestAuthorization() async throws {
        let options: UNAuthorizationOptions = [.alert, .sound, .badge]
        let granted = try await center.requestAuthorization(options: options)
        guard granted else { throw NotificationError.authorizationDenied }
    }

    func scheduleDailyReminder(at date: Date) async throws {
        try await requestAuthorizationIfNeeded()

        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let content = UNMutableNotificationContent()
        content.title = "Workout Reminder"
        content.body = "Time to check in with your FlexLog plan."
        content.sound = .default

        let request = UNNotificationRequest(identifier: Identifiers.dailyReminder,
                                            content: content,
                                            trigger: trigger)
        try await center.add(request)
    }

    func cancelDailyReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifiers.dailyReminder])
    }

    private func requestAuthorizationIfNeeded() async throws {
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return
        case .denied:
            throw NotificationError.authorizationDenied
        case .notDetermined:
            try await requestAuthorization()
        @unknown default:
            return
        }
    }
}

extension NotificationService {
    enum NotificationError: LocalizedError {
        case authorizationDenied

        var errorDescription: String? {
            switch self {
            case .authorizationDenied:
                return "Notifications are disabled. Enable them in Settings to receive reminders."
            }
        }
    }

    private enum Identifiers {
        static let dailyReminder = "flexlog.daily.reminder"
    }
}
