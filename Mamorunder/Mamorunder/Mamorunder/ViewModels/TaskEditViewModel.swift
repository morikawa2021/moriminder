//
//  TaskEditViewModel.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import SwiftUI
import CoreData
import Combine

class TaskEditViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Task)
    }

    // MARK: - Basic Properties
    @Published var title: String = ""
    @Published var category: Category?
    @Published var priority: Priority = .medium
    @Published var taskType: TaskType = .task
    @Published var deadline: Date?
    @Published var startDateTime: Date?

    // MARK: - Notification Properties (New Model)
    // 開始時刻の通知設定
    @Published var startTimeNotification: NotificationType = .none
    @Published var startTimeReminderOffset: Int = 30  // 分
    @Published var startTimeReminderInterval: Int = 10  // 分

    // 期限の通知設定
    @Published var deadlineNotification: NotificationType = .none
    @Published var deadlineReminderOffset: Int = 60  // 分
    @Published var deadlineReminderInterval: Int = 15  // 分

    // MARK: - Repeat Properties
    @Published var isRepeating: Bool = false
    @Published var repeatPattern: RepeatPattern?
    @Published var repeatEndDate: Date?

    // MARK: - UI State
    @Published var categories: [Category] = []
    @Published var presetTimes: [PresetTime] = []
    @Published var isSaving: Bool = false

    var isValid: Bool {
        !title.isEmpty && !isSaving
    }

    private let mode: Mode
    private var taskManager: TaskManager
    private var viewContext: NSManagedObjectContext

    init(mode: Mode, viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.mode = mode
        self.viewContext = viewContext
        self.taskManager = TaskManager(viewContext: viewContext)

        // 編集モードの場合、既存のタスクデータを読み込む
        if case .edit(let task) = mode {
            loadTask(task)
        }

        loadCategories()
        loadPresetTimes()
    }

    func updateViewContext(_ newViewContext: NSManagedObjectContext) {
        self.viewContext = newViewContext
        self.taskManager = TaskManager(viewContext: newViewContext)
        // viewContextが変更されたので、カテゴリとプリセット時間を再読み込み
        loadCategories()
        loadPresetTimes()
    }

    private func loadTask(_ task: Task) {
        title = task.title ?? ""
        category = task.category
        if let priorityString = task.priority {
            priority = Priority(rawValue: priorityString) ?? .medium
        }
        if let taskTypeString = task.taskType {
            taskType = TaskType(rawValue: taskTypeString) ?? .task
        }
        deadline = task.deadline
        startDateTime = task.startDateTime

        // 通知設定（新モデル）
        startTimeNotification = task.startTimeNotificationType
        startTimeReminderOffset = Int(task.startTimeReminderOffset)
        startTimeReminderInterval = Int(task.startTimeReminderInterval)

        deadlineNotification = task.deadlineNotificationType
        deadlineReminderOffset = Int(task.deadlineReminderOffset)
        deadlineReminderInterval = Int(task.deadlineReminderInterval)

        // 繰り返し設定
        isRepeating = task.isRepeating
        repeatPattern = task.repeatPattern
        repeatEndDate = task.repeatEndDate
    }

    func loadCategories() {
        let request: NSFetchRequest<Category> = Category.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "usageCount", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]

        do {
            categories = try viewContext.fetch(request)
        } catch {
            print("カテゴリ取得エラー: \(error)")
            categories = []
        }
    }

    private func loadPresetTimes() {
        let request: NSFetchRequest<PresetTime> = PresetTime.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(key: "isDefault", ascending: false),
            NSSortDescriptor(key: "order", ascending: true)
        ]

        do {
            presetTimes = try viewContext.fetch(request)
        } catch {
            print("プリセット時間取得エラー: \(error)")
            presetTimes = []
        }
    }

    func save() async throws {
        // 保存中のフラグを設定
        await MainActor.run {
            isSaving = true
        }

        defer {
            _Concurrency.Task { @MainActor in
                isSaving = false
            }
        }

        let task: Task

        switch mode {
        case .create:
            // 新規作成
            task = Task(context: viewContext)
            task.createdAt = Date()
            task.id = UUID()
        case .edit(let existingTask):
            // 編集
            // 既存のタスクが別のコンテキストに属している場合は、現在のコンテキストに取得し直す
            if existingTask.managedObjectContext != viewContext {
                // 別のコンテキストのタスクを現在のコンテキストで取得
                guard let taskId = existingTask.id else {
                    throw TaskError.taskNotFound
                }
                if let taskInContext = taskManager.fetchTask(id: taskId) {
                    task = taskInContext
                } else {
                    throw TaskError.taskNotFound
                }
            } else {
                task = existingTask
            }
        }

        // 基本情報の設定
        task.title = title
        task.category = category
        task.priority = priority.rawValue
        task.taskType = taskType.rawValue
        task.deadline = deadline
        task.startDateTime = startDateTime

        // 通知設定（新モデル）
        // 開始時刻がない場合は通知設定を無効化
        if startDateTime != nil {
            task.startTimeNotificationType = startTimeNotification
            task.startTimeReminderOffset = Int32(startTimeReminderOffset)
            task.startTimeReminderInterval = Int32(startTimeReminderInterval)
        } else {
            task.startTimeNotificationType = .none
        }

        // 期限がない場合は通知設定を無効化
        if deadline != nil {
            task.deadlineNotificationType = deadlineNotification
            task.deadlineReminderOffset = Int32(deadlineReminderOffset)
            task.deadlineReminderInterval = Int32(deadlineReminderInterval)
        } else {
            task.deadlineNotificationType = .none
        }

        print("💾 タスク保存: \(title)")
        print("  - startDateTime: \(startDateTime?.description ?? "nil")")
        print("  - startTimeNotification: \(startTimeNotification.rawValue)")
        print("  - deadline: \(deadline?.description ?? "nil")")
        print("  - deadlineNotification: \(deadlineNotification.rawValue)")

        // 繰り返し設定
        task.isRepeating = isRepeating
        task.repeatPattern = repeatPattern
        task.repeatEndDate = repeatEndDate

        // カテゴリの使用回数をインクリメント
        if let category = category {
            category.usageCount += 1
        }

        // 保存と通知スケジュール
        try await taskManager.createTask(task)
    }
}
