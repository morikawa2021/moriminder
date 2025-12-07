//
//  ReminderService.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class ReminderService {
    private let notificationManager: NotificationManager

    /// 初回スケジュール時に登録する通知の最大数（iOS 64個制限への対応）
    private let initialNotificationCount = 5

    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }

    // MARK: - Schedule Reminders

    /// 特定のタイムポイントのリマインドをスケジュール
    func scheduleReminder(for task: Task, type: TimePointType) async throws {
        // リマインドタイプかどうか確認
        let notificationType: NotificationType
        let targetDate: Date?
        let offset: Int32
        let interval: Int32
        let endDate: Date?

        switch type {
        case .startTime:
            guard task.startTimeNotificationType == .remind else { return }
            notificationType = task.startTimeNotificationType
            targetDate = task.startDateTime
            offset = task.startTimeReminderOffset
            interval = task.startTimeReminderInterval
            endDate = task.startTimeReminderEndDate()
        case .deadline:
            guard task.deadlineNotificationType == .remind else { return }
            notificationType = task.deadlineNotificationType
            targetDate = task.deadline
            offset = task.deadlineReminderOffset
            interval = task.deadlineReminderInterval
            endDate = task.deadlineReminderEndDate()
        }

        guard notificationType == .remind else { return }
        guard let targetDate = targetDate else { return }

        // 現在の通知数を確認
        let currentNotificationCount = await notificationManager.getPendingNotifications().count
        print("📊 通知状況: 現在 \(currentNotificationCount)/64個")

        // 1. 開始時刻の決定（ターゲット時刻の offset 分前）
        var startTime = Calendar.current.date(
            byAdding: .minute,
            value: -Int(offset),
            to: targetDate
        ) ?? targetDate

        // 開始時刻が過去の場合は現在時刻から開始
        if startTime < Date() {
            print("ℹ️ リマインド開始時刻が過去のため、現在時刻から開始します")
            startTime = Date()
        }

        // 2. リマインド通知をスケジュール（初回は5個のみ）
        var currentTime = startTime
        var scheduledCount = 0
        let intervalMinutes = Int(interval)

        while scheduledCount < initialNotificationCount {
            // タスクが完了している場合は終了
            guard !task.isCompleted else { break }

            // 終了時刻を超えた場合は終了
            if let endDate = endDate, currentTime > endDate {
                break
            }

            // 現在時刻より未来の時刻のみスケジュール
            if currentTime > Date() {
                do {
                    // ターゲット時刻と同じ（またはそれ以降）ならfinalフラグを立てる
                    let isFinal = currentTime >= targetDate
                    try await notificationManager.scheduleReminderNotification(
                        for: task,
                        at: currentTime,
                        type: type,
                        isFinal: isFinal
                    )
                    scheduledCount += 1
                    print("リマインド通知スケジュール: \(task.title ?? "無題") - \(type.displayName) at \(currentTime)\(isFinal ? " (最終)" : "")")
                } catch {
                    print("リマインド通知スケジュールエラー: \(error.localizedDescription)")
                }
            }

            // 次の通知時刻を計算
            currentTime = currentTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }

        let endInfo = endDate == nil ? "完了まで無期限" : "終了: \(endDate!)"
        print("✅ リマインドスケジュール完了: \(task.title ?? "無題") - \(type.displayName) - \(scheduledCount)個の通知 (\(endInfo))")
    }

    // MARK: - Schedule Next Reminder

    /// 次のリマインド通知をスケジュール（通知配信後に呼ばれる）
    func scheduleNextReminder(for task: Task, from currentTime: Date, type: TimePointType) async throws {
        guard !task.isCompleted else { return }

        // リマインドタイプかどうか確認
        let notificationType: NotificationType
        let targetDate: Date?
        let interval: Int32
        let endDate: Date?

        switch type {
        case .startTime:
            guard task.startTimeNotificationType == .remind else { return }
            notificationType = task.startTimeNotificationType
            targetDate = task.startDateTime
            interval = task.startTimeReminderInterval
            endDate = task.startTimeReminderEndDate()
        case .deadline:
            guard task.deadlineNotificationType == .remind else { return }
            notificationType = task.deadlineNotificationType
            targetDate = task.deadline
            interval = task.deadlineReminderInterval
            endDate = task.deadlineReminderEndDate()
        }

        guard notificationType == .remind else { return }

        // 終了時刻が設定されていて、現在時刻がそれを超えている場合は終了
        if let endDate = endDate, currentTime >= endDate {
            print("ℹ️ リマインド終了時刻に達したため、次の通知はスケジュールしません")
            return
        }

        // 次の通知時刻を計算
        let intervalMinutes = Int(interval)
        let nextTime = currentTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))

        // 未来の時刻のみスケジュール
        guard nextTime > Date() else { return }

        // ターゲット時刻と同じ（またはそれ以降）ならfinalフラグを立てる
        let isFinal = targetDate.map { nextTime >= $0 } ?? false

        try await notificationManager.scheduleReminderNotification(
            for: task,
            at: nextTime,
            type: type,
            isFinal: isFinal
        )

        print("次のリマインド通知をスケジュール: \(task.title ?? "無題") - \(type.displayName) at \(nextTime) (間隔: \(intervalMinutes)分)\(isFinal ? " (最終)" : "")")
    }
}
