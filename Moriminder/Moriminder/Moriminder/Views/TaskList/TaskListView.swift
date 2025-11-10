//
//  TaskListView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @Environment(\.managedObjectContext) private var viewContext
    @State private var taskToSubdivide: Task?
    @State private var showCategoryManagement = false
    @State private var showNotificationDebug = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 画面名
                AppHeaderView(screenTitle: "タスク一覧")
                
                // フィルタ・ソートバー
                FilterSortBar(
                    filterMode: $viewModel.filterMode,
                    sortMode: $viewModel.sortMode
                )
                
                // タスクリスト
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskCardView(
                            task: task,
                            onSubdivideRequested: {
                                taskToSubdivide = task
                            },
                            onTap: {
                                viewModel.taskToShowDetail = task
                            }
                        )
                            .listRowBackground(
                                task.isCompleted
                                    ? Color.gray.opacity(0.1)
                                    : Color.clear
                            )
                            .swipeActions(edge: .trailing) {
                                // 完了アクション
                                Button {
                                    viewModel.requestCompleteTask(task)
                                } label: {
                                    Label("完了", systemImage: "checkmark")
                                }
                                .tint(.green)
                                
                                // 削除アクション
                                Button(role: .destructive) {
                                    viewModel.requestDeleteTask(task)
                                } label: {
                                    Label("削除", systemImage: "trash")
                                }
                            }
                    }
                }
                
                // 新規タスク追加ボタン
                Button {
                    viewModel.showAddTask = true
                } label: {
                    Label("新規タスク追加", systemImage: "plus.circle.fill")
                        .font(.title2)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppTitleToolbar()
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button {
                            showNotificationDebug = true
                        } label: {
                            Image(systemName: "bell.badge")
                                .foregroundColor(.blue)
                        }
                        
                        Button {
                            showCategoryManagement = true
                        } label: {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddTask, onDismiss: {
                viewModel.loadTasks()
            }) {
                TaskEditView(mode: .create)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: $taskToSubdivide, onDismiss: {
                viewModel.loadTasks()
            }) { task in
                TaskSubdivisionView(task: task)
                    .environment(\.managedObjectContext, viewContext)
            }
            .sheet(item: Binding(
                get: { viewModel.taskToShowDetail },
                set: { viewModel.taskToShowDetail = $0 }
            ), onDismiss: {
                viewModel.loadTasks()
            }) { task in
                TaskEditView(mode: .edit(task))
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("タスクを完了しますか？", isPresented: Binding(
                get: { viewModel.taskToComplete != nil },
                set: { if !$0 { viewModel.taskToComplete = nil } }
            )) {
                Button("キャンセル", role: .cancel) {
                    viewModel.taskToComplete = nil
                }
                Button("完了", role: .destructive) {
                    viewModel.confirmCompleteTask()
                }
            } message: {
                if let task = viewModel.taskToComplete {
                    Text("「\(task.title ?? "")」を完了としてマークしますか？")
                }
            }
            .alert("タスクを削除しますか？", isPresented: Binding(
                get: { viewModel.taskToDelete != nil },
                set: { if !$0 { viewModel.taskToDelete = nil } }
            )) {
                Button("キャンセル", role: .cancel) {
                    viewModel.taskToDelete = nil
                }
                Button("削除", role: .destructive) {
                    viewModel.confirmDeleteTask()
                }
            } message: {
                if let task = viewModel.taskToDelete {
                    Text("「\(task.title ?? "")」を削除しますか？この操作は取り消せません。")
                }
            }
            .alert("リマインドを停止しますか？", isPresented: Binding(
                get: { viewModel.taskToStopReminder != nil },
                set: { if !$0 { viewModel.taskToStopReminder = nil } }
            )) {
                Button("キャンセル", role: .cancel) {
                    viewModel.taskToStopReminder = nil
                }
                Button("停止", role: .destructive) {
                    viewModel.confirmStopReminder()
                }
            } message: {
                if let task = viewModel.taskToStopReminder {
                    Text("「\(task.title ?? "")」のリマインドを停止しますか？")
                }
            }
            .onAppear {
                viewModel.loadTasks()
            }
            .onChange(of: viewModel.filterMode) { _ in
                viewModel.loadTasks()
            }
            .onChange(of: viewModel.sortMode) { _ in
                viewModel.loadTasks()
            }
            .sheet(isPresented: $showCategoryManagement) {
                CategoryManagementView(viewContext: viewContext)
            }
            .sheet(isPresented: $showNotificationDebug) {
                NotificationDebugView()
            }
        }
    }
}

// プレビュー
#Preview {
    TaskListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

