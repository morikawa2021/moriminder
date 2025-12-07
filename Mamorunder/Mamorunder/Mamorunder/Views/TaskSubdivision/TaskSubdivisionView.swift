//
//  TaskSubdivisionView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI
import CoreData

struct TaskSubdivisionView: View {
    let task: Task
    @StateObject private var viewModel: TaskSubdivisionViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    init(task: Task) {
        self.task = task
        _viewModel = StateObject(wrappedValue: TaskSubdivisionViewModel(
            task: task,
            viewContext: PersistenceController.shared.container.viewContext
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 画面名
                AppHeaderView(screenTitle: "タスク細分化")
                
                VStack(spacing: 24) {
                    Spacer()
                
                // 元のタスク表示
                VStack(alignment: .leading, spacing: 12) {
                    Text("このタスクを細分化しませんか？")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(task.title ?? "無題のタスク")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // 促すメッセージ
                VStack(spacing: 16) {
                    Image(systemName: "scissors")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                    
                    VStack(spacing: 8) {
                        Text("大きなタスクは細分化することで")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text("実行しやすくなります")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("例：「部屋の掃除」→「床を掃除機でかける」「窓を拭く」「ゴミを捨てる」など")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                
                Spacer()
                
                // 閉じるボタン
                Button {
                    dismiss()
                } label: {
                    Text("閉じる")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.bottom)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                AppTitleToolbar()
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

