//
//  TaskManager.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData
import UserNotifications

class TaskManager {
    private let viewContext: NSManagedObjectContext
    private let notificationManager: NotificationManager
    private let archiveService: TaskArchiveService
    private var repeatingTaskGenerator: RepeatingTaskGenerator {
        RepeatingTaskGenerator(
            taskManager: self,
            notificationManager: notificationManager,
            viewContext: viewContext
        )
    }

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        self.notificationManager = NotificationManager()
        self.archiveService = TaskArchiveService(viewContext: viewContext)
    }
    
    // タスク作成
    func createTask(_ task: Task) async throws {
        // 1. バリデーション
        do {
            try validateTask(task)
        } catch {
            print("タスクバリデーションエラー: \(error)")
            throw error
        }
        
        // 2. 保存
        do {
            // 変更があるか確認
            guard viewContext.hasChanges else {
                print("警告: 保存する変更がありません")
                return
            }
            
            try viewContext.save()
            print("タスク保存成功: \(task.title ?? "無題")")
        } catch {
            print("CoreData保存エラー: \(error)")
            if let nsError = error as NSError? {
                print("エラー詳細: \(nsError.userInfo)")
                print("エラードメイン: \(nsError.domain)")
                print("エラーコード: \(nsError.code)")
                
                // バリデーションエラーの詳細を表示
                if let validationErrors = nsError.userInfo[NSValidationKeyErrorKey] as? [String: Any] {
                    print("バリデーションエラー: \(validationErrors)")
                }
                
                // 複数のエラーがある場合
                if let detailedErrors = nsError.userInfo[NSDetailedErrorsKey] as? [NSError] {
                    for detailedError in detailedErrors {
                        print("詳細エラー: \(detailedError.localizedDescription)")
                    }
                }
            }
            throw TaskError.saveFailed
        }
        
        // 3. 通知スケジュール
        // 編集時は既存の通知をキャンセルしてから再スケジュール
        // Core Dataの isInserted プロパティを使用して、本当に新規作成なのか編集なのかを判定
        // isInserted = false の場合、既存のタスクが更新されている（編集モード）
        // isInserted = true の場合、新しいタスクが作成されている（新規作成モード）
        let isEditing = !task.isInserted
        if isEditing {
            print("📝 タスク編集モード: 既存の通知をキャンセルしてから再スケジュールします")
            await notificationManager.cancelNotifications(for: task)
        }
        
        // 通知権限を確認してからスケジュール
        let authorizationStatus = await notificationManager.checkAuthorizationStatus()
        if authorizationStatus != .authorized && authorizationStatus != .provisional {
            print("警告: 通知権限が許可されていません。ステータス: \(authorizationStatus.rawValue)")
            // 権限がない場合でもタスクの保存は続行
        }

        // 通知をスケジュール（新しいモデル: 時間ポイント別）
        if task.hasAnyNotification {
            do {
                try await notificationManager.scheduleNotifications(for: task)
                print("通知スケジュール成功: \(task.title ?? "無題")")
            } catch {
                print("通知スケジュールエラー: \(error)")
                // 通知エラーは保存を妨げないが、ログに記録
            }
        }
        
        // 4. 繰り返しタスクの場合の処理
        // parentTaskIdが設定されている場合は、既に生成された子インスタンスなのでスキップ
        if task.isRepeating && task.parentTaskId == nil {
            do {
                if isEditing {
                    // 編集時: 未完了の子タスクを削除して新しい設定で再生成
                    print("📝 繰り返しタスク編集: 未完了の子タスクを再生成します")
                    try await repeatingTaskGenerator.updateRepeatingTaskInstances(for: task)
                } else {
                    // 新規作成時: 初回の子タスクを生成
                    print("✨ 繰り返しタスク新規作成: 初回の子タスクを生成します")
                    try await repeatingTaskGenerator.initializeRepeatingTask(for: task)
                }
            } catch {
                print("繰り返しタスク処理エラー: \(error)")
                // 繰り返しタスク処理エラーは保存を妨げないが、ログに記録
            }
        }
    }
    
    // タスク取得（ID指定）
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

        // 繰り返しタスクの親タスク（テンプレート）を常に除外
        // 親タスク = isRepeating == true && parentTaskId == nil
        // 子インスタンス（実際の予定日時を持つもの）のみ表示
        predicates.append(NSPredicate(format: "isRepeating == NO OR parentTaskId != nil"))

        switch filter {
        case .all:
            // アーカイブ済みは除外（すべて = アーカイブ以外のすべて）
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .incomplete:
            predicates.append(NSPredicate(format: "isCompleted == NO"))
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .completed:
            predicates.append(NSPredicate(format: "isCompleted == YES"))
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .archived:
            predicates.append(NSPredicate(format: "isArchived == YES"))
        case .category(let categoryName):
            predicates.append(NSPredicate(format: "category.name == %@", categoryName))
            predicates.append(NSPredicate(format: "isArchived == NO"))
        case .priority(let priority):
            predicates.append(NSPredicate(format: "priority == %@", priority.rawValue))
            predicates.append(NSPredicate(format: "isArchived == NO"))
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
            // 既にソート済み（fetch前に設定する必要があるが、後でソートする）
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
            // 通知予定時刻でソート（開始時刻または期限の早い方）
            tasks.sort { task1, task2 in
                let date1 = task1.startDateTime ?? task1.deadline ?? Date.distantFuture
                let date2 = task2.startDateTime ?? task2.deadline ?? Date.distantFuture
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
        await notificationManager.cancelNotifications(for: task)
        
        // 3. 保存
        try viewContext.save()
        
        // 4. 繰り返しタスクの場合は次回インスタンスを生成
        if task.isRepeating {
            try await repeatingTaskGenerator.onTaskCompleted(for: task)
        }
    }
    
    // タスク削除
    func deleteTask(_ task: Task) async throws {
        // 1. 通知をキャンセル
        await notificationManager.cancelNotifications(for: task)
        
        // 2. 削除
        viewContext.delete(task)
        try viewContext.save()
    }
    
    // タスクアーカイブ
    func archiveTask(_ task: Task) async throws {
        try archiveService.archiveTask(task)
    }

    // タスクのアーカイブ解除（復元）
    func unarchiveTask(_ task: Task) async throws {
        try archiveService.unarchiveTask(task)
    }

    // 自動アーカイブ実行
    func performAutoArchive(daysAfterCompletion: Int = TaskArchiveService.defaultArchiveDays) async throws -> Int {
        return try await archiveService.archiveCompletedTasks(olderThan: daysAfterCompletion)
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

