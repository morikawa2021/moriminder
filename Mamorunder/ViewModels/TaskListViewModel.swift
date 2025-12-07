//
//  TaskListViewModel.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import SwiftUI
import CoreData

class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filterMode: FilterMode = .all
    @Published var sortMode: SortMode = .deadlineAsc
    @Published var showAddTask = false
    
    private let taskManager: TaskManager
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext
        self.taskManager = TaskManager(viewContext: viewContext)
    }
    
    func loadTasks() {
        tasks = taskManager.fetchTasks(
            filter: filterMode,
            sort: sortMode
        )
    }
    
    func completeTask(_ task: Task) {
        // リマインド中のタスクの場合は確認ダイアログを表示
        if task.reminderEnabled {
            // TODO: 確認ダイアログを表示
        } else {
            Task {
                try? await taskManager.completeTask(task)
                loadTasks()
            }
        }
    }
    
    func deleteTask(_ task: Task) {
        Task {
            try? await taskManager.deleteTask(task)
            loadTasks()
        }
    }
}

