//
//  ReminderService.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class ReminderService {
    private let notificationManager: NotificationManager
    
    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }
    
    // リマインドスケジュール（動的スケジューリング版：初回は5個のみ登録）
    func scheduleReminder(for task: Task) async throws {
        guard task.reminderEnabled else { return }

        // 現在の通知数を確認（iOS 64個制限への対応）
        let currentNotificationCount = await notificationManager.getPendingNotifications().count

        print("📊 通知状況: 現在 \(currentNotificationCount)/64個")

        // 初回スケジュール時は5個のみ登録（動的スケジューリング）
        let initialNotificationCount = 5

        // 1. 開始時刻の決定
        var startTime: Date
        if let explicitStartTime = task.reminderStartTime {
            // 明示的に設定されている場合はそれを使用
            startTime = explicitStartTime
        } else {
            // 未設定の場合、期限/開始日時の1時間前をデフォルトとする
            let targetTime = task.deadline ?? task.startDateTime ?? Date()
            startTime = targetTime.addingTimeInterval(-3600) // 1時間前
        }

        // 開始時刻が過去の場合は現在時刻から開始
        if startTime < Date() {
            print("ℹ️ リマインド開始時刻が過去のため、現在時刻から開始します")
            startTime = Date()
        }

        // 2. 終了時刻の決定（未設定ならnil = 完了まで無期限）
        let endTime = task.reminderEndTime

        // 3. 間隔を取得（分単位）
        let intervalMinutes = Int(task.reminderInterval)

        // 4. 通知をスケジュール（初回は5個のみ）
        var currentTime = startTime
        var scheduledCount = 0

        while scheduledCount < initialNotificationCount {
            // タスクが完了している場合は終了
            guard !task.isCompleted else { break }

            // 終了時刻を超えた場合は終了
            if let endTime = endTime, currentTime > endTime {
                break
            }

            // 現在時刻より未来の時刻のみスケジュール
            if currentTime > Date() {
                do {
                    try await notificationManager.scheduleReminderNotification(
                        for: task,
                        at: currentTime
                    )
                    scheduledCount += 1
                    print("リマインド通知スケジュール: \(task.title ?? "無題") at \(currentTime)")
                } catch {
                    print("リマインド通知スケジュールエラー: \(error.localizedDescription)")
                }
            }

            // 次の通知時刻を計算
            currentTime = currentTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }

        let endInfo = endTime == nil ? "完了まで無期限" : "終了: \(endTime!)"
        print("✅ リマインドスケジュール完了: \(task.title ?? "無題") - \(scheduledCount)個の通知 (\(endInfo))")
        print("   ※ 通知は自動的に補充されます（NotificationRefreshService）")

        // 注: 通知が配信された後、または通知数が減った時に、NotificationRefreshServiceが自動的に補充する
    }
    
    // 次のリマインド通知をスケジュール（終了日時がない場合に使用）
    func scheduleNextReminder(for task: Task, from currentTime: Date) async throws {
        guard task.reminderEnabled else { return }
        guard !task.isCompleted else { return }

        // 終了日時がない場合のみ、次の通知をスケジュール
        guard task.reminderEndTime == nil else { return }

        // 間隔を取得（分単位）
        let intervalMinutes = Int(task.reminderInterval)

        // 次の通知時刻を計算
        let nextTime = currentTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))

        // 未来の時刻のみスケジュール
        guard nextTime > Date() else { return }

        try await notificationManager.scheduleReminderNotification(
            for: task,
            at: nextTime
        )

        print("次のリマインド通知をスケジュール: \(task.title ?? "無題") at \(nextTime) (間隔: \(intervalMinutes)分)")
    }
}

