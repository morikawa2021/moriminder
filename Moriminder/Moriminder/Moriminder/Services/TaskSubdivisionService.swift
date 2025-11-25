//
//  TaskSubdivisionService.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class TaskSubdivisionService {
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // 1週間以上未完了のタスクを検出
    func findTasksEligibleForSubdivision() -> [Task] {
        let request: NSFetchRequest<Task> = Task.fetchRequest()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
            NSPredicate(format: "isCompleted == NO"),
            NSPredicate(format: "createdAt <= %@", sevenDaysAgo as CVarArg),
            NSPredicate(format: "reminderEnabled == YES")
        ])
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("細分化対象タスク取得エラー: \(error)")
            return []
        }
    }
    
    // タスクが細分化対象かどうかをチェック
    func isEligibleForSubdivision(_ task: Task) -> Bool {
        guard !task.isCompleted,
              let createdAt = task.createdAt,
              task.reminderEnabled else {
            return false
        }
        
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return createdAt <= sevenDaysAgo
    }
    
    // 細分化が既に実行されたかどうかをチェック（将来の実装用）
    func hasSubdivisionBeenExecuted(_ task: Task) -> Bool {
        // TODO: タスクに細分化実行フラグを追加するか、サブタスクの存在で判定
        // 現時点では常にfalseを返す（UIのみの実装のため）
        return false
    }
}







