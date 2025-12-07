//
//  TaskListViewModel.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class TaskListViewModel: ObservableObject {
    @Published var tasks: [Task] = []
    @Published var filterMode: FilterMode = .incomplete
    @Published var sortMode: SortMode = .deadlineAsc
    @Published var showAddTask = false
    @Published var taskToComplete: Task?
    @Published var taskToDelete: Task?
    @Published var taskToStopReminder: Task?
    @Published var taskToShowDetail: Task?
    
    private let taskManager: TaskManager
    private let viewContext: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext
        self.taskManager = TaskManager(viewContext: viewContext)
        
        // 通知アクションイベントをリッスン
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // 完了リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskCompleteRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                if let task = self?.taskManager.fetchTask(id: taskId) {
                    self?.taskToComplete = task
                }
            }
            .store(in: &cancellables)
        
        // リマインド停止リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskReminderStopRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                if let task = self?.taskManager.fetchTask(id: taskId) {
                    self?.taskToStopReminder = task
                }
            }
            .store(in: &cancellables)
        
        // タスク詳細表示リクエスト
        NotificationCenter.default.publisher(for: NSNotification.Name("TaskDetailRequested"))
            .compactMap { $0.userInfo?["taskId"] as? UUID }
            .sink { [weak self] taskId in
                if let task = self?.taskManager.fetchTask(id: taskId) {
                    self?.taskToShowDetail = task
                }
            }
            .store(in: &cancellables)
    }
    
    func loadTasks() {
        tasks = taskManager.fetchTasks(
            filter: filterMode,
            sort: sortMode
        )
    }

    func fetchTask(id: UUID) -> Task? {
        return taskManager.fetchTask(id: id)
    }
    
    func requestCompleteTask(_ task: Task) {
        // 確認ダイアログを表示するためにタスクを設定
        taskToComplete = task
    }
    
    func confirmCompleteTask() {
        guard let task = taskToComplete else { return }
        taskToComplete = nil
        
        _Concurrency.Task {
            try? await taskManager.completeTask(task)
            await MainActor.run {
                loadTasks()
            }
        }
    }
    
    func requestDeleteTask(_ task: Task) {
        // 確認ダイアログを表示するためにタスクを設定
        taskToDelete = task
    }
    
    func confirmDeleteTask() {
        guard let task = taskToDelete else { return }
        taskToDelete = nil
        
        _Concurrency.Task {
            try? await taskManager.deleteTask(task)
            await MainActor.run {
                loadTasks()
            }
        }
    }
    
    func confirmStopReminder() {
        guard let task = taskToStopReminder else { return }
        taskToStopReminder = nil

        // すべての通知を無効化
        task.startTimeNotificationType = .none
        task.deadlineNotificationType = .none

        _Concurrency.Task {
            // 通知をキャンセル
            let notificationManager = NotificationManager()
            await notificationManager.cancelNotifications(for: task)

            // Core Dataを保存
            try? viewContext.save()

            await MainActor.run {
                loadTasks()
            }
        }
    }

    func archiveTask(_ task: Task) {
        _Concurrency.Task {
            try? await taskManager.archiveTask(task)
            await MainActor.run {
                loadTasks()
            }
        }
    }

    func unarchiveTask(_ task: Task) {
        _Concurrency.Task {
            try? await taskManager.unarchiveTask(task)
            await MainActor.run {
                loadTasks()
            }
        }
    }
}

