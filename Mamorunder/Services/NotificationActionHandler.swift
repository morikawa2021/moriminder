//
//  NotificationActionHandler.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import UserNotifications
import CoreData

class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    private let taskManager: TaskManager
    private let notificationManager: NotificationManager
    
    init(taskManager: TaskManager, notificationManager: NotificationManager) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
        super.init()
    }
    
    // 通知アクションの処理
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let taskId = extractTaskId(from: response.notification)
        guard let taskId = taskId else {
            completionHandler()
            return
        }
        
        guard let task = taskManager.fetchTask(id: taskId) else {
            completionHandler()
            return
        }
        
        switch response.actionIdentifier {
        case "SNOOZE":
            // スヌーズ処理
            Task {
                try? await notificationManager.snoozeReminder(for: task)
                // スヌーズ後、Core Dataを保存
                try? task.managedObjectContext?.save()
            }
            
        case "COMPLETE":
            // 完了確認ダイアログを表示（UI層で処理）
            // NotificationCenterでアプリに通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskCompleteRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
            
        case "STOP":
            // リマインド停止確認ダイアログを表示（UI層で処理）
            // NotificationCenterでアプリに通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskReminderStopRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
            
        case "OPEN":
            // アプリを開いてタスク詳細画面を表示
            // NotificationCenterでアプリに通知を送信
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskDetailRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
            
        default:
            // デフォルトアクション（通知をタップした場合）
            // アプリを開いてタスク詳細画面を表示
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskDetailRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )
            break
        }
        
        completionHandler()
    }
    
    // 通知からタスクIDを抽出
    private func extractTaskId(from notification: UNNotification) -> UUID? {
        // 通知IDからタスクIDを抽出
        // 形式: "alarm_{taskId}" または "reminder_{taskId}_{timestamp}"
        let identifier = notification.request.identifier
        
        if identifier.hasPrefix("alarm_") {
            let taskIdString = String(identifier.dropFirst(6))
            return UUID(uuidString: taskIdString)
        } else if identifier.hasPrefix("reminder_") {
            let parts = identifier.dropFirst(9).split(separator: "_")
            if let taskIdString = parts.first {
                return UUID(uuidString: String(taskIdString))
            }
        }
        
        return nil
    }
}

// 通知カテゴリの登録
extension UNNotificationCategory {
    static func registerCategories() {
        let center = UNUserNotificationCenter.current()
        
        let alarmCategory = UNNotificationCategory(
            identifier: "ALARM",
            actions: [
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "スヌーズ",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "COMPLETE",
                    title: "完了",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "OPEN",
                    title: "アプリを開く",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [
                UNNotificationAction(
                    identifier: "SNOOZE",
                    title: "スヌーズ",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "COMPLETE",
                    title: "完了",
                    options: [.foreground]
                ),
                UNNotificationAction(
                    identifier: "STOP",
                    title: "停止",
                    options: []
                ),
                UNNotificationAction(
                    identifier: "OPEN",
                    title: "アプリを開く",
                    options: [.foreground]
                )
            ],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([alarmCategory, reminderCategory])
    }
}

