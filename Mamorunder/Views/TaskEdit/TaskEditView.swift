//
//  TaskEditView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TaskEditView: View {
    enum Mode {
        case create
        case edit(Task)
    }
    
    let mode: Mode
    @StateObject private var viewModel: TaskEditViewModel
    @Environment(\.dismiss) private var dismiss
    
    init(mode: Mode) {
        self.mode = mode
        _viewModel = StateObject(wrappedValue: TaskEditViewModel(mode: mode))
    }
    
    var body: some View {
        NavigationView {
            Form {
                // タスク名
                Section {
                    TextField("タスク名", text: $viewModel.title)
                        .font(.title3)
                }
                
                // カテゴリ
                Section("カテゴリ") {
                    CategoryPickerView(
                        selectedCategory: $viewModel.category,
                        categories: viewModel.categories
                    )
                }
                
                // 重要度
                Section("重要度") {
                    Picker("重要度", selection: $viewModel.priority) {
                        Text("低").tag(Priority.low)
                        Text("中").tag(Priority.medium)
                        Text("高").tag(Priority.high)
                    }
                    .pickerStyle(.segmented)
                }
                
                // 日時設定
                Section("日時設定") {
                    DateSettingView(
                        taskType: $viewModel.taskType,
                        deadline: $viewModel.deadline,
                        startDateTime: $viewModel.startDateTime,
                        presetTimes: viewModel.presetTimes
                    )
                }
                
                // アラーム設定
                Section("アラーム設定") {
                    AlarmSettingView(
                        enabled: $viewModel.alarmEnabled,
                        dateTime: $viewModel.alarmDateTime,
                        sound: $viewModel.alarmSound
                    )
                }
                
                // リマインド設定
                Section("リマインド設定") {
                    ReminderSettingView(
                        enabled: $viewModel.reminderEnabled,
                        interval: $viewModel.reminderInterval,
                        priority: viewModel.priority,
                        taskType: viewModel.taskType,
                        snoozeMaxCount: $viewModel.snoozeMaxCount
                    )
                }
                
                // 繰り返し設定
                Section("繰り返し設定") {
                    RepeatSettingView(
                        enabled: $viewModel.isRepeating,
                        pattern: $viewModel.repeatPattern,
                        endDate: $viewModel.repeatEndDate
                    )
                }
            }
            .navigationTitle(mode == .create ? "タスク登録" : "タスク編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
            }
        }
    }
}

