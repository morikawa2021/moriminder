//
//  NotificationManager.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import UserNotifications
import CoreData

/// 通知の時間ポイントタイプ
enum TimePointType: String {
    case startTime = "starttime"
    case deadline = "deadline"

    var displayName: String {
        switch self {
        case .startTime: return "開始時刻"
        case .deadline: return "期限"
        }
    }
}

class NotificationManager {
    private let center = UNUserNotificationCenter.current()

    // MARK: - Authorization

    /// 通知権限の要求
    func requestAuthorization() async throws {
        let granted = try await center.requestAuthorization(options: [
            .alert, .sound, .badge
        ])

        guard granted else {
            throw NotificationError.authorizationDenied
        }
    }

    /// 通知権限の状態を確認
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    /// タスクの全ての通知をスケジュール
    func scheduleNotifications(for task: Task) async throws {
        print("🔔 通知スケジュール開始: \(task.title ?? "無題")")

        // 開始時刻の通知
        if let startDateTime = task.startDateTime {
            switch task.startTimeNotificationType {
            case .once:
                try await scheduleOnceNotification(for: task, at: startDateTime, type: .startTime)
            case .remind:
                try await scheduleReminders(for: task, type: .startTime)
                // リマインドの場合、最終通知も含まれる（スケジュールはReminderServiceで処理）
            case .none:
                break
            }
        }

        // 期限の通知
        if let deadline = task.deadline {
            switch task.deadlineNotificationType {
            case .once:
                try await scheduleOnceNotification(for: task, at: deadline, type: .deadline)
            case .remind:
                try await scheduleReminders(for: task, type: .deadline)
                // リマインドの場合、最終通知も含まれる（スケジュールはReminderServiceで処理）
            case .none:
                break
            }
        }
    }

    /// 1回のみの通知をスケジュール
    func scheduleOnceNotification(for task: Task, at date: Date, type: TimePointType) async throws {
        print("🔔 1回通知スケジュール: \(task.title ?? "無題") - \(type.displayName)")

        guard date > Date() else {
            print("❌ 通知時刻が過去です: \(date)")
            return
        }

        // 通知権限を確認
        let authorizationStatus = await checkAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.authorizationDenied
        }

        let content = UNMutableNotificationContent()
        let baseTitle = task.title ?? "タスク"
        content.title = formatNotificationTitle(baseTitle, for: task)
        content.body = "\(type.displayName)です"
        content.sound = .default
        content.categoryIdentifier = "NOTIFICATION_ONCE"

        // 重要度設定
        content.interruptionLevel = mapPriorityToInterruptionLevel(task)

        // スケジュール
        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        components.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let identifier = "\(type.rawValue)_once_\(task.id?.uuidString ?? UUID().uuidString)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
        print("✅ 1回通知スケジュール成功: \(task.title ?? "無題") - \(type.displayName) at \(date)")
    }

    /// リマインド通知をスケジュール（ReminderServiceに委譲）
    func scheduleReminders(for task: Task, type: TimePointType) async throws {
        let reminderService = ReminderService(notificationManager: self)
        try await reminderService.scheduleReminder(for: task, type: type)
    }

    /// リマインド通知（個別）をスケジュール
    func scheduleReminderNotification(for task: Task, at date: Date, type: TimePointType, isFinal: Bool = false) async throws {
        guard date > Date() else {
            print("警告: リマインド時刻が過去です: \(date)")
            return
        }

        // 通知権限を確認
        let authorizationStatus = await checkAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.authorizationDenied
        }

        let content = UNMutableNotificationContent()
        let baseTitle = task.title ?? "タスク"
        content.title = formatNotificationTitle(baseTitle, for: task)

        // 本文を設定
        let targetDate: Date?
        switch type {
        case .startTime:
            targetDate = task.startDateTime
        case .deadline:
            targetDate = task.deadline
        }

        if let targetDate = targetDate {
            let remainingSeconds = targetDate.timeIntervalSince(date)
            let remainingMinutes = Int(remainingSeconds / 60)

            if isFinal {
                content.body = "\(type.displayName)です"
            } else if remainingMinutes > 60 {
                let hours = remainingMinutes / 60
                let minutes = remainingMinutes % 60
                if minutes > 0 {
                    content.body = "\(type.displayName)まであと\(hours)時間\(minutes)分"
                } else {
                    content.body = "\(type.displayName)まであと\(hours)時間"
                }
            } else if remainingMinutes > 0 {
                content.body = "\(type.displayName)まであと\(remainingMinutes)分"
            } else if remainingMinutes == 0 {
                content.body = "\(type.displayName)です"
            } else {
                let overMinutes = abs(remainingMinutes)
                content.body = "\(type.displayName)を\(overMinutes)分過ぎています"
            }
        } else {
            content.body = "タスクを確認してください"
        }

        content.sound = .default
        content.categoryIdentifier = "NOTIFICATION_REMINDER"

        // 重要度設定
        content.interruptionLevel = mapPriorityToInterruptionLevel(task)

        // スケジュール
        var components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: date
        )
        components.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        let suffix = isFinal ? "final" : String(Int(date.timeIntervalSince1970))
        let identifier = "\(type.rawValue)_reminder_\(task.id?.uuidString ?? UUID().uuidString)_\(suffix)"
        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        try await center.add(request)
    }

    // MARK: - Cancel Notifications

    /// タスクの全ての通知をキャンセル
    func cancelNotifications(for task: Task) async {
        guard let taskId = task.id?.uuidString else { return }

        let pendingRequests = await center.pendingNotificationRequests()

        // 新しい形式の通知IDプレフィックス
        let prefixes = [
            "starttime_once_\(taskId)",
            "starttime_reminder_\(taskId)",
            "deadline_once_\(taskId)",
            "deadline_reminder_\(taskId)",
            // 旧形式との互換性（マイグレーション期間中）
            "alarm_\(taskId)",
            "reminder_\(taskId)"
        ]

        let taskNotificationIds = pendingRequests
            .filter { request in
                prefixes.contains { request.identifier.hasPrefix($0) }
            }
            .map { $0.identifier }

        if !taskNotificationIds.isEmpty {
            print("🗑️ タスクの通知をキャンセル: \(task.title ?? "無題") - \(taskNotificationIds.count)個")
            center.removePendingNotificationRequests(withIdentifiers: taskNotificationIds)
        }
    }

    /// 特定のタイムポイントの通知をキャンセル
    func cancelNotifications(for task: Task, type: TimePointType) async {
        guard let taskId = task.id?.uuidString else { return }

        let pendingRequests = await center.pendingNotificationRequests()
        let prefix = "\(type.rawValue)_"

        let notificationIds = pendingRequests
            .filter { $0.identifier.hasPrefix(prefix) && $0.identifier.contains(taskId) }
            .map { $0.identifier }

        if !notificationIds.isEmpty {
            print("🗑️ \(type.displayName)の通知をキャンセル: \(task.title ?? "無題") - \(notificationIds.count)個")
            center.removePendingNotificationRequests(withIdentifiers: notificationIds)
        }
    }

    /// 通知が配信された後、次の通知をスケジュール
    func scheduleNextReminderAfterDelivery(for task: Task, deliveredAt: Date, type: TimePointType) async throws {
        guard !task.isCompleted else { return }

        let reminderService = ReminderService(notificationManager: self)
        try await reminderService.scheduleNextReminder(for: task, from: deliveredAt, type: type)
    }

    // MARK: - Helper Methods

    /// 重要度を通知重要度にマッピング
    private func mapPriorityToInterruptionLevel(_ task: Task) -> UNNotificationInterruptionLevel {
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            switch priority {
            case .high:
                return .timeSensitive
            case .medium:
                return .active
            case .low:
                return .passive
            }
        }
        return .active
    }

    /// 通知タイトルに日時情報を追加
    private func formatNotificationTitle(_ baseTitle: String, for task: Task) -> String {
        let targetDate = task.startDateTime ?? task.deadline

        guard let targetDate = targetDate else {
            return baseTitle
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        formatter.timeZone = TimeZone(identifier: "Asia/Tokyo")
        let dateString = formatter.string(from: targetDate)

        return "\(baseTitle) (\(dateString))"
    }

    // MARK: - Query Methods

    /// 予定されている通知の一覧を取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }

    /// 配信済みの通知の一覧を取得
    func getDeliveredNotifications() async -> [UNNotification] {
        return await center.deliveredNotifications()
    }

    /// 通知の詳細情報を取得（デバッグ用）
    func getNotificationDetails() async -> NotificationDetails {
        let pendingRequests = await center.pendingNotificationRequests()
        let settings = await center.notificationSettings()

        // 通知を種類別に分類
        let startTimeOnce = pendingRequests.filter { $0.identifier.hasPrefix("starttime_once_") }
        let startTimeReminders = pendingRequests.filter { $0.identifier.hasPrefix("starttime_reminder_") }
        let deadlineOnce = pendingRequests.filter { $0.identifier.hasPrefix("deadline_once_") }
        let deadlineReminders = pendingRequests.filter { $0.identifier.hasPrefix("deadline_reminder_") }

        print("📋 通知予定取得: 総数 \(pendingRequests.count)")
        print("  - 開始時刻通知（1回）: \(startTimeOnce.count)個")
        print("  - 開始時刻リマインド: \(startTimeReminders.count)個")
        print("  - 期限通知（1回）: \(deadlineOnce.count)個")
        print("  - 期限リマインド: \(deadlineReminders.count)個")

        // 通知の時刻を抽出
        let allDates = pendingRequests.compactMap { request -> Date? in
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                return Calendar.current.date(from: trigger.dateComponents)
            }
            return nil
        }.sorted()

        return NotificationDetails(
            totalCount: pendingRequests.count,
            alarmCount: startTimeOnce.count + deadlineOnce.count,
            reminderCount: startTimeReminders.count + deadlineReminders.count,
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            alertStyle: settings.alertStyle,
            soundSetting: settings.soundSetting,
            badgeSetting: settings.badgeSetting,
            lockScreenSetting: settings.lockScreenSetting,
            notificationCenterSetting: settings.notificationCenterSetting,
            alarmDates: [],
            reminderDates: allDates,
            allNotifications: pendingRequests.map { request in
                NotificationInfo(
                    identifier: request.identifier,
                    title: request.content.title,
                    body: request.content.body,
                    scheduledDate: (request.trigger as? UNCalendarNotificationTrigger).flatMap {
                        Calendar.current.date(from: $0.dateComponents)
                    },
                    categoryIdentifier: request.content.categoryIdentifier,
                    interruptionLevel: request.content.interruptionLevel
                )
            }
        )
    }
}

// 通知詳細情報の構造体
struct NotificationDetails {
    let totalCount: Int
    let alarmCount: Int
    let reminderCount: Int
    let authorizationStatus: UNAuthorizationStatus
    let alertSetting: UNNotificationSetting
    let alertStyle: UNAlertStyle
    let soundSetting: UNNotificationSetting
    let badgeSetting: UNNotificationSetting
    let lockScreenSetting: UNNotificationSetting
    let notificationCenterSetting: UNNotificationSetting
    let alarmDates: [Date]
    let reminderDates: [Date]
    let allNotifications: [NotificationInfo]
}

struct NotificationInfo {
    let identifier: String
    let title: String
    let body: String
    let scheduledDate: Date?
    let categoryIdentifier: String
    let interruptionLevel: UNNotificationInterruptionLevel
}
