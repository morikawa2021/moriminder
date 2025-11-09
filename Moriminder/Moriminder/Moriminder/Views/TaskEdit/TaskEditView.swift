//
//  TaskEditView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct TaskEditView: View {
    enum Mode: Equatable {
        case create
        case edit(Task)
        
        static func == (lhs: Mode, rhs: Mode) -> Bool {
            switch (lhs, rhs) {
            case (.create, .create):
                return true
            case (.edit(let lhsTask), .edit(let rhsTask)):
                return lhsTask.id == rhsTask.id
            default:
                return false
            }
        }
    }
    
    let mode: Mode
    @StateObject private var viewModel: TaskEditViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @State private var errorMessage: String?
    @State private var showErrorAlert = false
    
    init(mode: Mode) {
        self.mode = mode
        let viewModelMode: TaskEditViewModel.Mode
        switch mode {
        case .create:
            viewModelMode = .create
        case .edit(let task):
            viewModelMode = .edit(task)
        }
        // viewContextは後で設定されるため、一時的にnilを渡す
        _viewModel = StateObject(wrappedValue: TaskEditViewModel(mode: viewModelMode, viewContext: PersistenceController.shared.container.viewContext))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 画面名
                AppHeaderView(screenTitle: mode == .create ? "タスク登録" : "タスク編集")
                
                Form {
                // タスク名（必須）
                Section {
                    TaskNameInputView(
                        title: $viewModel.title,
                        extractedDateTime: Binding(
                            get: { viewModel.deadline ?? viewModel.startDateTime },
                            set: { date in
                                if let date = date {
                                    if viewModel.taskType == .task {
                                        viewModel.deadline = date
                                    } else {
                                        viewModel.startDateTime = date
                                    }
                                }
                            }
                        ),
                        extractedTaskType: $viewModel.taskType
                    )
                    .font(.title3)
                    .listRowBackground(Color.red.opacity(0.1))
                } header: {
                    HStack(spacing: 4) {
                        Text("タスク名")
                        Text("（必須）")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // カテゴリ（任意）
                Section {
                    Group {
                        CategoryPickerView(
                            selectedCategory: $viewModel.category,
                            categories: viewModel.categories,
                            onCategoryCreated: {
                                viewModel.loadCategories()
                            }
                        )
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("カテゴリ")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 重要度（任意）
                Section {
                    Group {
                        Picker("重要度", selection: $viewModel.priority) {
                            Text("低").tag(Priority.low)
                            Text("中").tag(Priority.medium)
                            Text("高").tag(Priority.high)
                        }
                        .pickerStyle(.segmented)
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("重要度")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 日時設定（任意）
                Section {
                    Group {
                        DateSettingView(
                            taskType: $viewModel.taskType,
                            deadline: $viewModel.deadline,
                            startDateTime: $viewModel.startDateTime,
                            presetTimes: viewModel.presetTimes
                        )
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("日時設定")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // アラーム設定（任意）
                Section {
                    Group {
                        AlarmSettingView(
                            enabled: $viewModel.alarmEnabled,
                            dateTime: $viewModel.alarmDateTime,
                            sound: $viewModel.alarmSound,
                            defaultDateTime: viewModel.taskType == .task ? viewModel.deadline : viewModel.startDateTime
                        )
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("アラーム設定")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // リマインド設定（任意）
                Section {
                    Group {
                        ReminderSettingView(
                            enabled: $viewModel.reminderEnabled,
                            interval: $viewModel.reminderInterval,
                            priority: viewModel.priority,
                            taskType: viewModel.taskType,
                            snoozeMaxCount: $viewModel.snoozeMaxCount,
                            snoozeUnlimited: $viewModel.snoozeUnlimited,
                            reminderEndTime: $viewModel.reminderEndTime,
                            deadline: viewModel.deadline,
                            startDateTime: viewModel.startDateTime
                        )
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("リマインド設定")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                // 繰り返し設定（任意）
                Section {
                    Group {
                        RepeatSettingView(
                            enabled: $viewModel.isRepeating,
                            pattern: $viewModel.repeatPattern,
                            endDate: $viewModel.repeatEndDate
                        )
                    }
                    .listRowBackground(Color(.systemBackground))
                } header: {
                    HStack(spacing: 4) {
                        Text("繰り返し設定")
                        Text("（任意）")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppTitleToolbar()
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isSaving ? "保存中..." : "保存") {
                        _Concurrency.Task {
                            do {
                                try await viewModel.save()
                                await MainActor.run {
                                    dismiss()
                                }
                            } catch {
                                await MainActor.run {
                                    let errorMessage: String
                                    if let taskError = error as? TaskError {
                                        errorMessage = taskError.errorDescription ?? "タスクの保存に失敗しました"
                                    } else if let notificationError = error as? NotificationError {
                                        errorMessage = notificationError.errorDescription ?? "通知の設定に失敗しました"
                                    } else {
                                        errorMessage = "タスクの保存に失敗しました: \(error.localizedDescription)"
                                    }
                                    self.errorMessage = errorMessage
                                    self.showErrorAlert = true
                                    print("タスク保存エラー: \(error)")
                                    if let nsError = error as NSError? {
                                        print("エラー詳細: \(nsError.userInfo)")
                                    }
                                }
                            }
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
            .alert("エラー", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
            .onAppear {
                // viewContextをViewModelに設定
                viewModel.updateViewContext(viewContext)
            }
        }
    }
}

