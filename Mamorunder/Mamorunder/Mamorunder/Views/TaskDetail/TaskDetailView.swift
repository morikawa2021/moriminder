//
//  TaskDetailView.swift
//  Mamorunder
//
//  Created on 2025-11-19.
//

import SwiftUI
import CoreData

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: TaskDetailViewModel
    @State private var showCompleteConfirmation = false

    init(task: Task) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }

    var body: some View {
        NavigationView {
            ZStack {
                // メインコンテンツ
                ScrollView {
                    VStack(spacing: 24) {
                        // 基本情報セクション
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "基本情報", icon: "info.circle.fill")

                            // タイトル
                            DetailRow(
                                label: "タスク名",
                                value: viewModel.task.title ?? "",
                                icon: "text.alignleft"
                            )

                            // カテゴリー
                            HStack {
                                Label("カテゴリー", systemImage: "folder.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Spacer()

                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(viewModel.categoryColor)
                                        .frame(width: 12, height: 12)

                                    Text(viewModel.categoryName)
                                        .font(.body)
                                }
                            }
                            .padding(.horizontal)

                            // 優先度
                            DetailRow(
                                label: "優先度",
                                value: viewModel.formattedPriority,
                                icon: "flag.fill",
                                valueColor: priorityColor
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                        // 日時設定セクション
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "日時設定", icon: "calendar")

                            // タスク種別
                            DetailRow(
                                label: "種別",
                                value: viewModel.formattedTaskType,
                                icon: "doc.text.fill"
                            )

                            // 期限
                            if viewModel.task.deadline != nil {
                                DetailRow(
                                    label: "期限",
                                    value: viewModel.formattedDeadline,
                                    icon: "clock.fill"
                                )
                            }

                            // 開始日時
                            if viewModel.task.startDateTime != nil {
                                DetailRow(
                                    label: "開始日時",
                                    value: viewModel.formattedStartDateTime,
                                    icon: "clock.fill"
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                        // 通知設定セクション
                        VStack(alignment: .leading, spacing: 16) {
                            SectionHeader(title: "通知設定", icon: "bell.fill")

                            // 開始時刻の通知
                            if viewModel.task.startDateTime != nil {
                                DetailRow(
                                    label: "開始時刻",
                                    value: viewModel.formattedStartTimeNotification,
                                    icon: "clock.fill"
                                )
                            }

                            // 期限の通知
                            if viewModel.task.deadline != nil {
                                DetailRow(
                                    label: "期限",
                                    value: viewModel.formattedDeadlineNotification,
                                    icon: "alarm.fill"
                                )
                            }

                            // どちらも設定されていない場合
                            if viewModel.task.startDateTime == nil && viewModel.task.deadline == nil {
                                HStack {
                                    Label("通知", systemImage: "bell.slash")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Text("日時が設定されていません")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)

                        // 繰り返し設定セクション
                        if viewModel.task.isRepeating {
                            VStack(alignment: .leading, spacing: 16) {
                                SectionHeader(title: "繰り返し設定", icon: "arrow.clockwise")

                                DetailRow(
                                    label: "繰り返し",
                                    value: viewModel.formattedRepeat,
                                    icon: "repeat"
                                )
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }

                        // 下部の余白
                        Spacer(minLength: 80)
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))

                // 完了ボタン（未完了の場合のみ、下部に固定）
                if !viewModel.isCompleted {
                    VStack {
                        Spacer()

                        Button(action: {
                            showCompleteConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)

                                Text("完了する")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                        .disabled(viewModel.isCompleting)
                    }
                }
            }
            .navigationTitle("タスク詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("編集") {
                        viewModel.showEditSheet = true
                    }
                    .disabled(viewModel.isCompleted)
                }
            }
            .sheet(isPresented: $viewModel.showEditSheet, onDismiss: {
                // 編集画面を閉じた後、タスクを再読み込み
                viewModel.refreshTask()
            }) {
                TaskEditView(mode: .edit(viewModel.task))
                    .environment(\.managedObjectContext, viewContext)
            }
            .alert("タスクを完了", isPresented: $showCompleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("完了", role: .destructive) {
                    _Concurrency.Task {
                        do {
                            try await viewModel.completeTask()
                            // 完了後、画面を閉じる
                            dismiss()
                        } catch {
                            print("タスク完了エラー: \(error)")
                        }
                    }
                }
            } message: {
                Text("このタスクを完了しますか？\n完了すると通知が停止されます。")
            }
        }
    }

    // MARK: - Computed Properties

    private var priorityColor: Color {
        guard let priorityString = viewModel.task.priority,
              let priority = Priority(rawValue: priorityString) else {
            return .primary
        }

        switch priority {
        case .low:
            return .blue
        case .medium:
            return .orange
        case .high:
            return .red
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.headline)

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundColor(valueColor)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let task = Task(context: context)
    task.id = UUID()
    task.title = "サンプルタスク"
    task.priority = Priority.high.rawValue
    task.taskType = TaskType.task.rawValue
    task.deadline = Date().addingTimeInterval(3600)
    task.startDateTime = Date()
    task.startTimeNotification = NotificationType.remind.rawValue
    task.startTimeReminderOffset = 30
    task.startTimeReminderInterval = 10
    task.deadlineNotification = NotificationType.once.rawValue
    task.isRepeating = false

    return TaskDetailView(task: task)
}
