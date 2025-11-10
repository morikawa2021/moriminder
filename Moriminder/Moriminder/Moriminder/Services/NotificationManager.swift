//
//  NotificationManager.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import UserNotifications
import CoreData

class NotificationManager {
    private let center = UNUserNotificationCenter.current()
    
    // 通知権限の要求
    func requestAuthorization() async throws {
        // .provisionalを削除して、通常の通知権限のみを要求
        // これにより、デフォルト設定でロック画面、通知センター、バナーがすべてONになる可能性が高くなります
        let granted = try await center.requestAuthorization(options: [
            .alert, .sound, .badge
        ])

        guard granted else {
            throw NotificationError.authorizationDenied
        }
    }
    
    // 通知権限の状態を確認
    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }
    
    // アラーム通知のスケジュール
    func scheduleAlarm(for task: Task) async throws {
        guard let alarmDateTime = task.alarmDateTime else { return }
        guard alarmDateTime > Date() else {
            print("警告: アラーム時刻が過去です: \(alarmDateTime)")
            return
        }
        
        // 通知権限を確認
        let authorizationStatus = await checkAuthorizationStatus()
        guard authorizationStatus == .authorized || authorizationStatus == .provisional else {
            throw NotificationError.authorizationDenied
        }
        
        let content = UNMutableNotificationContent()
        content.title = "アラーム: \(task.title ?? "タスク")"
        content.body = "設定時刻になりました"
        if let soundName = task.alarmSound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }
        content.categoryIdentifier = "ALARM"
        
        // 重要度設定（アラームは重要なので、デフォルトでtimeSensitive）
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            content.interruptionLevel = mapPriorityToInterruptionLevel(priority)
        } else {
            // 優先度が設定されていない場合でも、アラームは重要なのでtimeSensitiveに設定
            content.interruptionLevel = .timeSensitive
        }
        
        // スケジュール
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: alarmDateTime
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "alarm_\(task.id?.uuidString ?? UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    // リマインド通知のスケジュール
    func scheduleReminder(for task: Task) async throws {
        guard task.reminderEnabled else { return }
        
        let reminderService = ReminderService(notificationManager: self)
        try await reminderService.scheduleReminder(for: task)
    }
    
    // リマインド通知のスケジュール（個別）
    func scheduleReminderNotification(for task: Task, at date: Date) async throws {
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
        content.title = "リマインド: \(task.title ?? "タスク")"
        if let category = task.category, let categoryName = category.name {
            content.body = "カテゴリ: \(categoryName)"
        } else {
            content.body = "タスクを確認してください"
        }
        content.sound = .default
        content.categoryIdentifier = "REMINDER"
        
        // 重要度設定（優先度が設定されていない場合はactiveをデフォルトとする）
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            content.interruptionLevel = mapPriorityToInterruptionLevel(priority)
        } else {
            // 優先度が設定されていない場合は通常の通知レベル
            content.interruptionLevel = .active
        }
        
        // スケジュール
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            ),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "reminder_\(task.id?.uuidString ?? UUID().uuidString)_\(Int(date.timeIntervalSince1970))",
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
    }
    
    // 通知のキャンセル（全て）
    func cancelNotifications(for task: Task) async {
        guard let taskId = task.id?.uuidString else { return }
        
        // 全ての通知を取得してフィルタリング
        let pendingRequests = await center.pendingNotificationRequests()
        let taskNotificationIds = pendingRequests
            .filter { $0.identifier.contains(taskId) }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: taskNotificationIds)
    }
    
    // アラーム通知のみをキャンセル
    func cancelAlarmNotifications(for task: Task) async {
        guard let taskId = task.id?.uuidString else { return }
        
        let pendingRequests = await center.pendingNotificationRequests()
        let alarmNotificationIds = pendingRequests
            .filter { $0.identifier.hasPrefix("alarm_\(taskId)") }
            .map { $0.identifier }
        
        if !alarmNotificationIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: alarmNotificationIds)
        }
    }
    
    // リマインド通知のみをキャンセル
    func cancelReminderNotifications(for task: Task) async {
        guard let taskId = task.id?.uuidString else { return }
        
        let pendingRequests = await center.pendingNotificationRequests()
        let reminderNotificationIds = pendingRequests
            .filter { $0.identifier.hasPrefix("reminder_\(taskId)") }
            .map { $0.identifier }
        
        if !reminderNotificationIds.isEmpty {
            center.removePendingNotificationRequests(withIdentifiers: reminderNotificationIds)
        }
    }
    
    // スヌーズ処理
    func snoozeReminder(for task: Task) async throws {
        // スヌーズ回数をチェック
        // 注意: スヌーズ最大回数は通知スケジューリング時ではなく、
        // 通知が配信された後にユーザーが「スヌーズ」ボタンを押した時に適用される
        let snoozeCount = Int(task.snoozeCount)
        let snoozeMaxCount = Int(task.snoozeMaxCount)
        
        guard snoozeCount < snoozeMaxCount || task.snoozeUnlimited else {
            throw NotificationError.maxSnoozeReached
        }
        
        // 日付が変わったかチェック（リセット判定）
        let today = Calendar.current.startOfDay(for: Date())
        let lastSnoozeDate = Calendar.current.startOfDay(for: task.lastSnoozeDateTime ?? Date.distantPast)
        
        if today > lastSnoozeDate {
            // 日付が変わったのでカウンターをリセット
            task.snoozeCount = 0
        }
        
        // スヌーズ回数をインクリメント
        task.snoozeCount += 1
        task.lastSnoozeDateTime = Date()
        
        // 次のリマインド時刻を計算（現在時刻 + リマインド間隔）
        let nextReminderTime = Date().addingTimeInterval(
            TimeInterval(Int(task.reminderInterval) * 60)
        )
        
        // 次のリマインド通知をスケジュール
        try await scheduleReminderNotification(for: task, at: nextReminderTime)
    }
    
    // 通知が配信された後、次の通知をスケジュール（終了日時がない場合）
    func scheduleNextReminderAfterDelivery(for task: Task, deliveredAt: Date) async throws {
        guard task.reminderEnabled else { return }
        guard !task.isCompleted else { return }
        
        // 終了日時がない場合のみ、次の通知をスケジュール
        let endTime = task.reminderEndTime ?? task.deadline ?? task.startDateTime
        guard endTime == nil else { return }
        
        let reminderService = ReminderService(notificationManager: self)
        try await reminderService.scheduleNextReminder(for: task, from: deliveredAt)
    }
    
    // 重要度を通知重要度にマッピング（iOS 15+）
    private func mapPriorityToInterruptionLevel(_ priority: Priority) -> UNNotificationInterruptionLevel {
        switch priority {
        case .high:
            return .timeSensitive  // 時間に敏感な通知（Focus Modeでも表示される可能性が高い）
        case .medium:
            return .active  // 通常の通知
        case .low:
            return .passive  // 控えめな通知
        }
    }
    
    // 予定されている通知の一覧を取得
    func getPendingNotifications() async -> [UNNotificationRequest] {
        return await center.pendingNotificationRequests()
    }
    
    // 通知の詳細情報を取得（デバッグ用）
    func getNotificationDetails() async -> NotificationDetails {
        let pendingRequests = await center.pendingNotificationRequests()
        let settings = await center.notificationSettings()
        
        // 通知を種類別に分類
        let alarms = pendingRequests.filter { $0.identifier.hasPrefix("alarm_") }
        let reminders = pendingRequests.filter { $0.identifier.hasPrefix("reminder_") }
        
        // 通知の時刻を抽出してソート
        let alarmDates = alarms.compactMap { request -> Date? in
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                return Calendar.current.date(from: trigger.dateComponents)
            }
            return nil
        }.sorted()
        
        let reminderDates = reminders.compactMap { request -> Date? in
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                return Calendar.current.date(from: trigger.dateComponents)
            }
            return nil
        }.sorted()
        
        return NotificationDetails(
            totalCount: pendingRequests.count,
            alarmCount: alarms.count,
            reminderCount: reminders.count,
            authorizationStatus: settings.authorizationStatus,
            alertSetting: settings.alertSetting,
            alertStyle: settings.alertStyle,
            soundSetting: settings.soundSetting,
            badgeSetting: settings.badgeSetting,
            lockScreenSetting: settings.lockScreenSetting,
            notificationCenterSetting: settings.notificationCenterSetting,
            alarmDates: alarmDates,
            reminderDates: reminderDates,
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

