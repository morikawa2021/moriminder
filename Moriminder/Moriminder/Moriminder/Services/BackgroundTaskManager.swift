//
//  BackgroundTaskManager.swift
//  Moriminder
//
//  Created on 2025-11-13.
//

import Foundation
import BackgroundTasks
import UserNotifications

class BackgroundTaskManager {
    static let shared = BackgroundTaskManager()

    private let taskIdentifier = "jp.co.softstudio.Moriminder.notification-refresh"
    private var notificationRefreshService: NotificationRefreshService?

    private init() {}

    // NotificationRefreshServiceを設定
    func configure(refreshService: NotificationRefreshService) {
        self.notificationRefreshService = refreshService
    }

    // バックグラウンドタスクを登録
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: taskIdentifier,
            using: nil
        ) { task in
            self.handleNotificationRefresh(task: task as! BGAppRefreshTask)
        }
        print("📋 バックグラウンドタスク登録完了: \(taskIdentifier)")
    }

    // 次のバックグラウンドタスクをスケジュール
    func scheduleNextBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)

        // 12時間後に実行をリクエスト（最早実行時刻）
        request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 3600)

        do {
            try BGTaskScheduler.shared.submit(request)
            print("📅 次のバックグラウンドタスクをスケジュール: 12時間後")
        } catch {
            print("⚠️ バックグラウンドタスクのスケジュールに失敗: \(error)")
        }
    }

    // バックグラウンドタスクのハンドラー
    private func handleNotificationRefresh(task: BGAppRefreshTask) {
        print("🔄 バックグラウンドタスク実行開始")

        // 次のタスクをスケジュール
        scheduleNextBackgroundTask()

        // タスクのタイムアウトを設定（30秒）
        task.expirationHandler = {
            print("⏱️ バックグラウンドタスクがタイムアウトしました")
        }

        // 通知リフレッシュを実行
        _Concurrency.Task {
            do {
                try await self.notificationRefreshService?.refreshNotifications()
                task.setTaskCompleted(success: true)
                print("✅ バックグラウンドタスク完了")
            } catch {
                task.setTaskCompleted(success: false)
                print("❌ バックグラウンドタスク失敗: \(error)")
            }
        }
    }
}
