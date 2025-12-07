//
//  TaskListView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TaskListView: View {
    @StateObject private var viewModel = TaskListViewModel()
    @State private var filterMode: FilterMode = .all
    @State private var sortMode: SortMode = .deadlineAsc
    
    var body: some View {
        NavigationView {
            VStack {
                // フィルタ・ソートバー
                FilterSortBar(
                    filterMode: $filterMode,
                    sortMode: $sortMode
                )
                
                // タスクリスト
                List {
                    ForEach(viewModel.tasks) { task in
                        TaskCardView(task: task)
                            .swipeActions(edge: .trailing) {
                                // 完了アクション
                                Button {
                                    viewModel.completeTask(task)
                                } label: {
                                    Label("完了", systemImage: "checkmark")
                                }
                                .tint(.green)
                                
                                // 削除アクション
                                Button(role: .destructive) {
                                    viewModel.deleteTask(task)
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
            .navigationTitle("タスク一覧")
            .sheet(isPresented: $viewModel.showAddTask) {
                TaskEditView(mode: .create)
            }
            .onAppear {
                viewModel.loadTasks()
            }
        }
    }
}

// プレビュー
#Preview {
    TaskListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}

