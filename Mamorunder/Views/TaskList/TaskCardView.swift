//
//  TaskCardView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct TaskCardView: View {
    let task: Task
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // タスク名
            Text(task.title ?? "無題のタスク")
                .font(.headline)
            
            HStack {
                // カテゴリ
                if let category = task.category {
                    Text(category.name ?? "")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
                
                // 重要度
                if let priority = task.priority {
                    PriorityBadge(priority: Priority(rawValue: priority) ?? .medium)
                }
            }
            
            // 日時情報
            if let deadline = task.deadline {
                Label {
                    Text(formatDate(deadline))
                } icon: {
                    Image(systemName: "calendar")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            if let startDateTime = task.startDateTime {
                Label {
                    Text("開始: \(formatDate(startDateTime))")
                } icon: {
                    Image(systemName: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // リマインド設定
            if task.reminderEnabled {
                Label {
                    Text("リマインド: \(task.reminderInterval)分間隔")
                } icon: {
                    Image(systemName: "bell")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
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

