//
//  TaskManager.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class TaskManager {
    private let viewContext: NSManagedObjectContext
    private let notificationManager: NotificationManager
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.notificationManager = NotificationManager()
    }
    
    // タスク作成
    func createTask(_ task: Task) async throws {
        // 1. バリデーション
        try validateTask(task)
        
        // 2. 保存
        try viewContext.save()
        
        // 3. 通知スケジュール
        if task.alarmEnabled {
            try await notificationManager.scheduleAlarm(for: task)
        }
        if task.reminderEnabled {
            try await notificationManager.scheduleReminder(for: task)
        }
        
        // 4. 繰り返しタスクの場合は次回インスタンスを生成
        if task.isRepeating {
            // TODO: 繰り返しタスク生成
        }
    }
    
    // IDでタスクを取得
    func fetchTask(id: UUID) -> Task? {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        do {
            return try viewContext.fetch(request).first
        } catch {
            print("タスク取得エラー: \(error)")
            return nil
        }
    }
    
    // タスク取得
    func fetchTasks(filter: FilterMode = .all, sort: SortMode = .deadlineAsc) -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        
        // フィルタの適用
        var predicates: [NSPredicate] = []
        
        switch filter {
        case .all:
            break
        case .incomplete:
            predicates.append(NSPredicate(format: "isCompleted == NO"))
        case .completed:
            predicates.append(NSPredicate(format: "isCompleted == YES"))
        case .category(let categoryName):
            predicates.append(NSPredicate(format: "category.name == %@", categoryName))
        case .priority(let priority):
            predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        // ソートの適用
        var tasks: [Task]
        do {
            tasks = try viewContext.fetch(request)
        } catch {
            print("タスク取得エラー: \(error)")
            return []
        }
        
        // Priorityソートの場合はカスタムソートを実行（文字列ソートでは正しく動作しないため）
        switch sort {
        case .createdAtDesc:
            tasks.sort { ($0.createdAt ?? Date.distantPast) > ($1.createdAt ?? Date.distantPast) }
        case .createdAtAsc:
            tasks.sort { ($0.createdAt ?? Date.distantPast) < ($1.createdAt ?? Date.distantPast) }
        case .priorityDesc:
            // 重要度（高い順）
            tasks.sort { task1, task2 in
                let priority1 = Priority(rawValue: task1.priority ?? "low") ?? .low
                let priority2 = Priority(rawValue: task2.priority ?? "low") ?? .low
                return priority1 > priority2
            }
        case .priorityAsc:
            // 重要度（低い順）
            tasks.sort { task1, task2 in
                let priority1 = Priority(rawValue: task1.priority ?? "low") ?? .low
                let priority2 = Priority(rawValue: task2.priority ?? "low") ?? .low
                return priority1 < priority2
            }
        case .deadlineAsc:
            // 期限（早い順）
            tasks.sort { task1, task2 in
                let date1 = task1.deadline ?? Date.distantFuture
                let date2 = task2.deadline ?? Date.distantFuture
                return date1 < date2
            }
        case .deadlineDesc:
            // 期限（遅い順）
            tasks.sort { task1, task2 in
                let date1 = task1.deadline ?? Date.distantFuture
                let date2 = task2.deadline ?? Date.distantFuture
                return date1 > date2
            }
        case .startDateTimeAsc:
            // 開始日時（早い順）
            tasks.sort { task1, task2 in
                let date1 = task1.startDateTime ?? Date.distantFuture
                let date2 = task2.startDateTime ?? Date.distantFuture
                return date1 < date2
            }
        case .startDateTimeDesc:
            // 開始日時（遅い順）
            tasks.sort { task1, task2 in
                let date1 = task1.startDateTime ?? Date.distantFuture
                let date2 = task2.startDateTime ?? Date.distantFuture
                return date1 > date2
            }
        case .alarmDateTime:
            tasks.sort { task1, task2 in
                let date1 = task1.alarmDateTime ?? Date.distantFuture
                let date2 = task2.alarmDateTime ?? Date.distantFuture
                return date1 < date2
            }
        case .category:
            tasks.sort { task1, task2 in
                let name1 = task1.category?.name ?? ""
                let name2 = task2.category?.name ?? ""
                return name1 < name2
            }
        case .alphabetical:
            tasks.sort { task1, task2 in
                let title1 = task1.title ?? ""
                let title2 = task2.title ?? ""
                return title1 < title2
            }
        }
        
        return tasks
    }
    
    // タスク完了
    func completeTask(_ task: Task) async throws {
        // 1. タスクを完了状態に更新
        task.isCompleted = true
        task.completedAt = Date()
        
        // 2. 通知をキャンセル
        try await notificationManager.cancelNotifications(for: task)
        
        // 3. 保存
        try viewContext.save()
        
        // 4. 繰り返しタスクの場合は次回インスタンスを生成
        if task.isRepeating {
            // TODO: 繰り返しタスク生成
        }
    }
    
    // タスク削除
    func deleteTask(_ task: Task) async throws {
        // 1. 通知をキャンセル
        try await notificationManager.cancelNotifications(for: task)
        
        // 2. 削除
        viewContext.delete(task)
        try viewContext.save()
    }
    
    // バリデーション
    private func validateTask(_ task: Task) throws {
        guard let title = task.title, !title.isEmpty else {
            throw TaskError.invalidTitle
        }
        
        // 日時設定のバリデーション
        if let deadline = task.deadline, let startDateTime = task.startDateTime {
            guard deadline >= startDateTime else {
                throw TaskError.conflictingDates
            }
        }
    }
}

