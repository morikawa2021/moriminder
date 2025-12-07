//
//  TaskEditViewModel.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import SwiftUI
import CoreData

class TaskEditViewModel: ObservableObject {
    enum Mode {
        case create
        case edit(Task)
    }
    
    @Published var title: String = ""
    @Published var category: Category?
    @Published var priority: Priority = .medium
    @Published var taskType: TaskType = .task
    @Published var deadline: Date?
    @Published var startDateTime: Date?
    @Published var alarmEnabled: Bool = false
    @Published var alarmDateTime: Date?
    @Published var alarmSound: String?
    @Published var reminderEnabled: Bool = false
    @Published var reminderInterval: Int = 60
    @Published var reminderStartTime: Date?
    @Published var reminderEndTime: Date?
    @Published var snoozeMaxCount: Int = 5
    @Published var snoozeUnlimited: Bool = false
    @Published var isRepeating: Bool = false
    @Published var repeatPattern: RepeatPattern?
    @Published var repeatEndDate: Date?
    
    @Published var categories: [Category] = []
    @Published var presetTimes: [PresetTime] = []
    
    var isValid: Bool {
        !title.isEmpty
    }
    
    private let mode: Mode
    private let taskManager: TaskManager
    private let viewContext: NSManagedObjectContext
    
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
        alarmEnabled = task.alarmEnabled
        alarmDateTime = task.alarmDateTime
        alarmSound = task.alarmSound
        reminderEnabled = task.reminderEnabled
        reminderInterval = Int(task.reminderInterval)
        reminderStartTime = task.reminderStartTime
        reminderEndTime = task.reminderEndTime
        snoozeMaxCount = Int(task.snoozeMaxCount)
        snoozeUnlimited = task.snoozeUnlimited
        isRepeating = task.isRepeating
        // TODO: repeatPatternの読み込み
        repeatEndDate = task.repeatEndDate
    }
    
    private func loadCategories() {
        // TODO: カテゴリの読み込み
        categories = []
    }
    
    private func loadPresetTimes() {
        // TODO: プリセット時間の読み込み
        presetTimes = []
    }
    
    func save() async {
        // TODO: タスクの保存処理
    }
}

