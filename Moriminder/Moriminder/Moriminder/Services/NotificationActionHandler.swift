//
//  NotificationActionHandler.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import UserNotifications
import CoreData

class NotificationActionHandler: NSObject, UNUserNotificationCenterDelegate {
    private let taskManager: TaskManager
    private let notificationManager: NotificationManager
    private let notificationRefreshService: NotificationRefreshService

    init(taskManager: TaskManager, notificationManager: NotificationManager, notificationRefreshService: NotificationRefreshService) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
        self.notificationRefreshService = notificationRefreshService
        super.init()
    }
    
    // 通知が配信された時（バックグラウンドでも呼ばれる）
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // フォアグラウンドでも通知を表示
        completionHandler([.banner, .sound, .badge])

        // 通知が配信された後、通知をリフレッシュして5件のバッファを維持
        _Concurrency.Task {
            try? await notificationRefreshService.refreshNotifications()
        }
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
        case "COMPLETE":
            // 通知アクションからの完了は、NotificationCenterでイベントを送信
            // UI層で確認ダイアログを表示する
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskCompleteRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )

        case "OPEN":
            // アプリを開いてタスク詳細画面を表示
            NotificationCenter.default.post(
                name: NSNotification.Name("TaskDetailRequested"),
                object: nil,
                userInfo: ["taskId": taskId]
            )

        default:
            // 通知をタップした場合（デフォルト動作）
            break
        }

        // 完了アクション以外の場合、通知をリフレッシュして5件のバッファを維持
        if response.actionIdentifier != "COMPLETE" {
            _Concurrency.Task {
                try? await notificationRefreshService.refreshNotifications()
            }
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
            options: [.customDismissAction]  // カスタムアクションを有効化
        )
        
        let reminderCategory = UNNotificationCategory(
            identifier: "REMINDER",
            actions: [
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
            options: [.customDismissAction]  // カスタムアクションを有効化
        )
        
        center.setNotificationCategories([alarmCategory, reminderCategory])
    }
}

