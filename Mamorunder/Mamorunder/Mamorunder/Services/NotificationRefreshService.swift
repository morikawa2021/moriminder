//
//  NotificationRefreshService.swift
//  Mamorunder
//
//  Created on 2025-11-13.
//

import Foundation
import UserNotifications
import CoreData

class NotificationRefreshService {
    private let taskManager: TaskManager
    private let notificationManager: NotificationManager
    private let reminderService: ReminderService
    private let viewContext: NSManagedObjectContext

    init(taskManager: TaskManager, notificationManager: NotificationManager, reminderService: ReminderService, viewContext: NSManagedObjectContext) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
        self.reminderService = reminderService
        self.viewContext = viewContext
    }

    // アプリ起動時・フォアグラウンド復帰時・タスク完了時に呼び出す
    func refreshNotifications() async throws {
        print("🔄 通知リフレッシュ開始")

        // 1. 現在スケジュール済みの通知数を確認
        let pendingRequests = await notificationManager.getPendingNotifications()
        let deliveredNotifications = await notificationManager.getDeliveredNotifications()
        let currentCount = pendingRequests.count

        print("📊 現在の通知数: \(currentCount)/64 (配信済み: \(deliveredNotifications.count)個)")

        // 2. 配信済み通知の古いものを削除（1日以上前）
        let oneDayAgo = Date().addingTimeInterval(-24 * 60 * 60)
        let oldDeliveredIds = deliveredNotifications.compactMap { notification -> String? in
            if notification.date < oneDayAgo {
                return notification.request.identifier
            }
            return nil
        }

        if !oldDeliveredIds.isEmpty {
            await UNUserNotificationCenter.current()
                .removeDeliveredNotifications(withIdentifiers: oldDeliveredIds)
            print("🗑️ 古い配信済み通知を削除: \(oldDeliveredIds.count)個")
        }

        // 3. 50個を超えている場合、過去の予定通知を削除
        if currentCount > 50 {
            let outdatedNotifications = pendingRequests.filter { request in
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger,
                      let nextTriggerDate = Calendar.current.date(from: trigger.dateComponents) else {
                    return false
                }
                return nextTriggerDate < Date()
            }

            let outdatedIds = outdatedNotifications.map { $0.identifier }
            if !outdatedIds.isEmpty {
                await UNUserNotificationCenter.current()
                    .removePendingNotificationRequests(withIdentifiers: outdatedIds)
                print("🗑️ 過去の予定通知を削除: \(outdatedIds.count)個")
            }
        }

        // 4. アクティブなタスクを取得
        let activeTasks = await fetchActiveTasks()

        // 5. 各タスクの通知数を確認し、不足していれば補充
        var totalAdded = 0

        for task in activeTasks {
            // このタスクの現在の通知数を確認
            let taskNotifications = pendingRequests.filter { request in
                request.identifier.contains(task.id?.uuidString ?? "")
            }

            let currentTaskCount = taskNotifications.count
            let targetCount = 5  // 目標通知数

            if currentTaskCount < targetCount {
                let needed = targetCount - currentTaskCount
                print("📝 \(task.title ?? "無題"): 現在\(currentTaskCount)個 → \(needed)個追加")

                // 開始時刻のリマインドを補充
                if task.hasStartTimeReminder {
                    let startTimeNotifications = taskNotifications.filter {
                        $0.identifier.hasPrefix("starttime_reminder_")
                    }
                    if startTimeNotifications.count < targetCount {
                        let lastTime = getLastNotificationTime(from: startTimeNotifications)
                        try await addNotifications(
                            for: task,
                            type: .startTime,
                            count: targetCount - startTimeNotifications.count,
                            after: lastTime
                        )
                        totalAdded += targetCount - startTimeNotifications.count
                    }
                }

                // 期限のリマインドを補充
                if task.hasDeadlineReminder {
                    let deadlineNotifications = taskNotifications.filter {
                        $0.identifier.hasPrefix("deadline_reminder_")
                    }
                    if deadlineNotifications.count < targetCount {
                        let lastTime = getLastNotificationTime(from: deadlineNotifications)
                        try await addNotifications(
                            for: task,
                            type: .deadline,
                            count: targetCount - deadlineNotifications.count,
                            after: lastTime
                        )
                        totalAdded += targetCount - deadlineNotifications.count
                    }
                }
            }
        }

        let finalCount = await notificationManager.getPendingNotifications().count
        print("✅ 通知リフレッシュ完了: \(currentCount)個 → \(finalCount)個（+\(totalAdded)個追加）")
    }

    // 最後の通知時刻を取得
    private func getLastNotificationTime(from notifications: [UNNotificationRequest]) -> Date? {
        notifications
            .compactMap { request -> Date? in
                guard let trigger = request.trigger as? UNCalendarNotificationTrigger else { return nil }
                return Calendar.current.date(from: trigger.dateComponents)
            }
            .max()
    }

    // アクティブなタスクを取得（未完了・リマインド有効）
    private func fetchActiveTasks() async -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        // リマインドタイプのタスクを取得
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == NO"),
            NSPredicate(format: "isArchived == NO"),
            NSCompoundPredicate(orPredicateWithSubpredicates: [
                NSPredicate(format: "startTimeNotification == %@", NotificationType.remind.rawValue),
                NSPredicate(format: "deadlineNotification == %@", NotificationType.remind.rawValue)
            ])
        ])

        // 重要度順にソート（高→中→低）
        request.sortDescriptors = [
            NSSortDescriptor(key: "priority", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: true)
        ]

        do {
            return try await viewContext.perform {
                try self.viewContext.fetch(request)
            }
        } catch {
            print("⚠️ アクティブタスク取得エラー: \(error)")
            return []
        }
    }

    // 指定されたタスクに追加の通知をスケジュール
    private func addNotifications(for task: Task, type: TimePointType, count: Int, after lastTime: Date?) async throws {
        let intervalMinutes: Int
        let targetDate: Date?
        let endTime: Date?

        switch type {
        case .startTime:
            intervalMinutes = Int(task.startTimeReminderInterval)
            targetDate = task.startDateTime
            endTime = task.startTimeReminderEndDate()
        case .deadline:
            intervalMinutes = Int(task.deadlineReminderInterval)
            targetDate = task.deadline
            endTime = task.deadlineReminderEndDate()
        }

        guard let targetDate = targetDate else { return }

        // 開始時刻を決定
        var currentTime: Date
        if let lastTime = lastTime {
            // 最後の通知時刻から間隔分後
            currentTime = lastTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        } else {
            // リマインド開始時刻から
            switch type {
            case .startTime:
                currentTime = task.startTimeReminderStartDate() ?? targetDate.addingTimeInterval(-3600)
            case .deadline:
                currentTime = task.deadlineReminderStartDate() ?? targetDate.addingTimeInterval(-3600)
            }
        }

        // count個の通知を追加
        var added = 0
        while added < count {
            // 終了時刻を超えた場合は終了
            if let endTime = endTime, currentTime > endTime {
                break
            }

            // 現在時刻より未来の時刻のみスケジュール
            if currentTime > Date() {
                let isFinal = currentTime >= targetDate
                try await notificationManager.scheduleReminderNotification(
                    for: task,
                    at: currentTime,
                    type: type,
                    isFinal: isFinal
                )
                added += 1
            }

            // 次の通知時刻を計算
            currentTime = currentTime.addingTimeInterval(TimeInterval(intervalMinutes * 60))
        }
    }
}
