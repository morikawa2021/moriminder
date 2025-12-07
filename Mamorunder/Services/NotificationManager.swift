//
//  NotificationManager.swift
//  Mamorunder
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
        let granted = try await center.requestAuthorization(options: [
            .alert, .sound, .badge, .provisional
        ])

        guard granted else {
            throw NotificationError.authorizationDenied
        }
    }
    
    // アラーム通知のスケジュール
    func scheduleAlarm(for task: Task) async throws {
        guard let alarmDateTime = task.alarmDateTime else { return }
        guard alarmDateTime > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "アラーム: \(task.title ?? "タスク")"
        content.body = "設定時刻になりました"
        if let soundName = task.alarmSound {
            content.sound = UNNotificationSound(named: UNNotificationSoundName(soundName))
        } else {
            content.sound = .default
        }
        content.categoryIdentifier = "ALARM"
        
        // 重要度設定
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            content.interruptionLevel = mapPriorityToInterruptionLevel(priority)
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
        guard date > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "リマインド: \(task.title ?? "タスク")"
        if let category = task.category, let categoryName = category.name {
            content.body = "カテゴリ: \(categoryName)"
        } else {
            content.body = "タスクを確認してください"
        }
        content.sound = .default
        content.categoryIdentifier = "REMINDER"
        
        // 重要度設定
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            content.interruptionLevel = mapPriorityToInterruptionLevel(priority)
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
    
    // 通知のキャンセル
    func cancelNotifications(for task: Task) async {
        guard let taskId = task.id?.uuidString else { return }
        
        // リマインド通知を削除するため、全ての通知を取得してフィルタリング
        let pendingRequests = await center.pendingNotificationRequests()
        let taskNotificationIds = pendingRequests
            .filter { $0.identifier.contains(taskId) }
            .map { $0.identifier }
        
        center.removePendingNotificationRequests(withIdentifiers: taskNotificationIds)
    }
    
    // スヌーズ処理
    func snoozeReminder(for task: Task) async throws {
        // スヌーズ回数をチェック
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
}

