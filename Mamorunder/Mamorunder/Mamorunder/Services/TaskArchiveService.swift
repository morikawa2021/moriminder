//
//  TaskArchiveService.swift
//  Mamorunder
//
//  Created on 2025-11-17.
//

import Foundation
import CoreData

/// 完了済みタスクのアーカイブを管理するサービス
class TaskArchiveService {
    private let viewContext: NSManagedObjectContext

    /// アーカイブまでのデフォルト日数
    static let defaultArchiveDays = 7

    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }

    // MARK: - Public Methods

    /// 指定日数より古い完了済みタスクを自動アーカイブ
    /// - Parameter daysAfterCompletion: 完了後の経過日数（デフォルト: 7日）
    /// - Returns: アーカイブされたタスクの数
    @discardableResult
    func archiveCompletedTasks(olderThan daysAfterCompletion: Int = defaultArchiveDays) async throws -> Int {
        let tasksToArchive = fetchTasksToArchive(daysAfterCompletion: daysAfterCompletion)

        for task in tasksToArchive {
            task.isArchived = true
        }

        if !tasksToArchive.isEmpty {
            try viewContext.save()
        }

        return tasksToArchive.count
    }

    /// 指定したタスクを手動でアーカイブ
    /// - Parameter task: アーカイブするタスク
    func archiveTask(_ task: Task) throws {
        task.isArchived = true
        try viewContext.save()
    }

    /// アーカイブされたタスクを復元
    /// - Parameter task: 復元するタスク
    func unarchiveTask(_ task: Task) throws {
        task.isArchived = false
        try viewContext.save()
    }

    // MARK: - Private Methods

    /// アーカイブ対象のタスクを取得
    /// - Parameter daysAfterCompletion: 完了後の経過日数
    /// - Returns: アーカイブ対象のタスク配列
    private func fetchTasksToArchive(daysAfterCompletion: Int) -> [Task] {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()

        // 完了日時から指定日数経過した日時を計算
        guard let thresholdDate = Calendar.current.date(
            byAdding: .day,
            value: -daysAfterCompletion,
            to: Date()
        ) else {
            return []
        }

        // 条件: 完了済み、未アーカイブ、指定日数より古い
        let predicates = [
            NSPredicate(format: "isCompleted == YES"),
            NSPredicate(format: "isArchived == NO"),
            NSPredicate(format: "completedAt != nil AND completedAt < %@", thresholdDate as NSDate)
        ]

        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            return try viewContext.fetch(fetchRequest)
        } catch {
            print("アーカイブ対象タスクの取得に失敗: \(error)")
            return []
        }
    }

    /// アーカイブされたタスクの数を取得（統計用）
    func getArchivedTasksCount() -> Int {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "isArchived == YES")

        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("アーカイブ済みタスク数の取得に失敗: \(error)")
            return 0
        }
    }

    /// 完了済みかつ未アーカイブのタスク数を取得（統計用）
    func getCompletedUnArchivedTasksCount() -> Int {
        let fetchRequest: NSFetchRequest<Task> = Task.fetchRequest()
        let predicates = [
            NSPredicate(format: "isCompleted == YES"),
            NSPredicate(format: "isArchived == NO")
        ]
        fetchRequest.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)

        do {
            return try viewContext.count(for: fetchRequest)
        } catch {
            print("完了済み未アーカイブタスク数の取得に失敗: \(error)")
            return 0
        }
    }
}
