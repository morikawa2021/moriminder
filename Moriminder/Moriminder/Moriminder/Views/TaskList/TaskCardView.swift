//
//  TaskCardView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TaskCardView: View {
    let task: Task
    var onSubdivideRequested: (() -> Void)?
    var onTap: (() -> Void)?
    
    @Environment(\.managedObjectContext) private var viewContext
    
    private var subdivisionService: TaskSubdivisionService {
        TaskSubdivisionService(viewContext: viewContext)
    }
    
    private var shouldShowSubdivisionPrompt: Bool {
        subdivisionService.isEligibleForSubdivision(task) &&
        !subdivisionService.hasSubdivisionBeenExecuted(task)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タスク名
            HStack(spacing: 8) {
                // 完了チェックマークまたはアーカイブアイコン
                if task.isArchived {
                    Image(systemName: "archivebox.fill")
                        .foregroundColor(.orange)
                        .font(.headline)
                } else if task.isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.headline)
                }

                Text(task.title ?? "無題のタスク")
                    .font(.headline)
                    .strikethrough(task.isCompleted || task.isArchived)
                    .foregroundColor(task.isCompleted || task.isArchived ? .secondary : .primary)
            }
            
            HStack {
                // カテゴリ
                if let category = task.category {
                    HStack(spacing: 4) {
                        if let colorHex = category.color {
                            Circle()
                                .fill(CategoryManager.colorFromHex(colorHex))
                                .frame(width: 12, height: 12)
                        }
                        Text(category.name ?? "")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        category.color != nil
                            ? CategoryManager.colorFromHex(category.color!).opacity(0.2)
                            : Color.blue.opacity(0.2)
                    )
                    .cornerRadius(8)
                }

                // 重要度
                if let priority = task.priority {
                    PriorityBadge(priority: Priority(rawValue: priority) ?? .medium)
                }

                // 繰り返しアイコン
                if task.isRepeating {
                    Image(systemName: "repeat")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            
            // 日時情報（強調表示）
            if let deadline = task.deadline {
                Label {
                    Text(formatDate(deadline))
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }

            if let startDateTime = task.startDateTime {
                Label {
                    Text("開始: \(formatDate(startDateTime))")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            }
            
            // リマインド設定
            if task.reminderEnabled {
                Label {
                    let offsetMinutes = task.reminderStartOffsetMinutes() ?? 60
                    let intervalMinutes = Int(task.reminderInterval)
                    Text("リマインド: \(offsetMinutes)分前・\(intervalMinutes)分間隔")
                } icon: {
                    Image(systemName: "bell")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // 細分化を促す表示
            if shouldShowSubdivisionPrompt {
                Button {
                    onSubdivideRequested?()
                } label: {
                    HStack {
                        Image(systemName: "scissors")
                        Text("このタスクを細分化しませんか？")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .opacity(task.isCompleted || task.isArchived ? 0.7 : 1.0)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy年M月d日(E) H:mm"
        return formatter.string(from: date)
    }
}

struct PriorityBadge: View {
    let priority: Priority
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<priorityLevel, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .font(.caption)
            }
        }
        .foregroundColor(priorityColor)
    }
    
    private var priorityLevel: Int {
        switch priority {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return .gray
        case .medium: return .orange
        case .high: return .red
        }
    }
}

