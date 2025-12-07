//
//  RepeatingTaskGenerator.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class RepeatingTaskGenerator {
    private let taskManager: TaskManager
    private let notificationManager: NotificationManager
    private let viewContext: NSManagedObjectContext
    
    init(taskManager: TaskManager, notificationManager: NotificationManager, viewContext: NSManagedObjectContext) {
        self.taskManager = taskManager
        self.notificationManager = notificationManager
        self.viewContext = viewContext
    }
    
    // 繰り返しタスクの初期化（最初の2-3回分を生成）
    func initializeRepeatingTask(for parentTask: Task) async throws {
        guard parentTask.isRepeating,
              let pattern = parentTask.repeatPattern else { return }
        
        // 最初の3回分のインスタンスを生成
        let maxInstances = 3
        var generatedCount = 0
        var currentDate = parentTask.deadline ?? parentTask.startDateTime ?? Date()
        
        while generatedCount < maxInstances {
            let nextDate = calculateNextDate(from: currentDate, pattern: pattern)
            
            // 繰り返し終了日時のチェック
            if let endDate = parentTask.repeatEndDate, nextDate > endDate {
                break
            }
            
            // 新しいインスタンスを作成
            let nextTask = createTaskInstance(
                from: parentTask,
                nextDate: nextDate,
                pattern: pattern
            )
            
            try await taskManager.createTask(nextTask)
            
            currentDate = nextDate
            generatedCount += 1
        }
    }
    
    // タスク完了時に次のインスタンスを生成（ローリング方式）
    func onTaskCompleted(for task: Task) async throws {
        guard task.isRepeating,
              let pattern = task.repeatPattern else { return }
        
        // 現在の未完了インスタンス数を確認
        let parentId = task.parentTaskId ?? task.id
        guard let parentId = parentId else { return }
        
        let pendingInstances = fetchPendingRepeatingInstances(parentTaskId: parentId)
        
        // 未完了が2個未満なら、次のインスタンスを生成
        if pendingInstances.count < 2 {
            // 最後のインスタンスの日時から次の日時を計算
            let lastDate = pendingInstances.last?.deadline
                ?? pendingInstances.last?.startDateTime
                ?? task.deadline
                ?? task.startDateTime
                ?? Date()
            
            let nextDate = calculateNextDate(from: lastDate, pattern: pattern)
            
            // 繰り返し終了日時のチェック
            if let endDate = task.repeatEndDate, nextDate > endDate {
                return // 繰り返し終了
            }
            
            // 新しいインスタンスを作成
            let nextTask = createTaskInstance(
                from: task,
                nextDate: nextDate,
                pattern: pattern
            )
            
            try await taskManager.createTask(nextTask)
        }
    }
    
    // 未完了の繰り返しインスタンスを取得
    private func fetchPendingRepeatingInstances(parentTaskId: UUID) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "parentTaskId == %@", parentTaskId as CVarArg),
            NSPredicate(format: "isCompleted == NO")
        ])
        request.sortDescriptors = [
            NSSortDescriptor(key: "deadline", ascending: true),
            NSSortDescriptor(key: "startDateTime", ascending: true)
        ]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("繰り返しインスタンス取得エラー: \(error)")
            return []
        }
    }

    // 親タスク編集時: 未完了の子タスクを削除して再生成
    func updateRepeatingTaskInstances(for parentTask: Task) async throws {
        guard parentTask.isRepeating else { return }

        // 1. 未完了の子タスクを全て削除
        try await deleteUncompletedInstances(for: parentTask)

        // 2. 新しい設定で子タスクを再生成
        try await initializeRepeatingTask(for: parentTask)
    }

    // 未完了の子タスクを削除
    private func deleteUncompletedInstances(for parentTask: Task) async throws {
        let parentId = parentTask.id
        guard let parentId = parentId else { return }

        // 未完了の子タスクを取得
        let uncompletedTasks = fetchPendingRepeatingInstances(parentTaskId: parentId)

        // 各タスクの通知をキャンセルして削除
        for task in uncompletedTasks {
            // 通知をキャンセル
            await notificationManager.cancelNotifications(for: task)

            // タスクを削除
            viewContext.delete(task)
        }

        // 変更を保存
        if viewContext.hasChanges {
            try viewContext.save()
        }

        print("📝 親タスク編集: \(uncompletedTasks.count)個の未完了子タスクを削除しました")
    }
    
    // タスクインスタンスの作成
    private func createTaskInstance(
        from parentTask: Task,
        nextDate: Date,
        pattern: RepeatPattern
    ) -> Task {
        let task = Task(context: viewContext)
        task.id = UUID()
        task.title = parentTask.title
        task.category = parentTask.category
        task.priority = parentTask.priority
        task.taskType = parentTask.taskType
        task.createdAt = Date()
        
        // 日時設定
        if let taskTypeString = parentTask.taskType,
           let taskType = TaskType(rawValue: taskTypeString) {
            if taskType == .task {
                task.deadline = nextDate
            } else {
                task.startDateTime = nextDate
            }
        } else {
            // デフォルトはタスクとして扱う
            task.deadline = nextDate
        }
        
        // 通知設定（新モデル）
        // 開始時刻の通知設定
        task.startTimeNotification = parentTask.startTimeNotification
        task.startTimeReminderOffset = parentTask.startTimeReminderOffset
        task.startTimeReminderInterval = parentTask.startTimeReminderInterval

        // 期限の通知設定
        task.deadlineNotification = parentTask.deadlineNotification
        task.deadlineReminderOffset = parentTask.deadlineReminderOffset
        task.deadlineReminderInterval = parentTask.deadlineReminderInterval

        // 繰り返し設定
        task.isRepeating = true
        task.repeatPattern = pattern
        task.repeatEndDate = parentTask.repeatEndDate
        task.parentTaskId = parentTask.parentTaskId ?? parentTask.id
        
        return task
    }
    
    // アラーム時刻の調整
    private func addIntervalToAlarm(_ originalAlarm: Date, nextDate: Date, originalDate: Date) -> Date {
        let interval = originalAlarm.timeIntervalSince(originalDate)
        return nextDate.addingTimeInterval(interval)
    }
    
    // 次回日時の計算
    private func calculateNextDate(from date: Date, pattern: RepeatPattern) -> Date {
        let calendar = Calendar.current
        
        switch pattern.type {
        case .daily:
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
            
        case .weekly:
            return calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
            
        case .monthly:
            return calendar.date(byAdding: .month, value: 1, to: date) ?? date
            
        case .yearly:
            return calendar.date(byAdding: .year, value: 1, to: date) ?? date
            
        case .everyNHours:
            guard let hourInterval = pattern.hourInterval else { return date }
            return calendar.date(byAdding: .hour, value: hourInterval, to: date) ?? date
            
        case .everyNDays:
            guard let interval = pattern.interval else { return date }
            return calendar.date(byAdding: .day, value: interval, to: date) ?? date
            
        case .nthWeekdayOfMonth:
            guard let weekday = pattern.weekday, let week = pattern.week else { return date }
            return calculateNthWeekday(weekday: weekday, week: week, from: date)
            
        case .custom:
            // カスタムパターンの処理（次の該当日を探す）
            guard let customDays = pattern.customDays, !customDays.isEmpty else { return date }
            return calculateNextCustomDate(from: date, days: customDays)
        }
    }
    
    // 毎月第N曜日の計算
    private func calculateNthWeekday(weekday: Int, week: Int, from date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: date)
        
        // 次の月に進む
        components.month! += 1
        
        guard let firstDayOfMonth = calendar.date(from: components) else { return date }
        let firstWeekday = calendar.component(.weekday, from: firstDayOfMonth)
        
        // 目的の曜日までの日数を計算
        var daysToAdd = (weekday - firstWeekday + 7) % 7
        daysToAdd += (week - 1) * 7
        
        return calendar.date(byAdding: .day, value: daysToAdd, to: firstDayOfMonth) ?? date
    }
    
    // カスタムパターンの次回日時計算
    private func calculateNextCustomDate(from date: Date, days: [Int]) -> Date {
        let calendar = Calendar.current
        var currentDate = date
        
        // 最大14日先まで探す
        for _ in 0..<14 {
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
            let weekday = calendar.component(.weekday, from: currentDate)
            if days.contains(weekday) {
                return currentDate
            }
        }
        
        return currentDate
    }
}

