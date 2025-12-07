//
//  ReminderService.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

class ReminderService {
    private let notificationManager: NotificationManager
    
    init(notificationManager: NotificationManager) {
        self.notificationManager = notificationManager
    }
    
    // リマインドスケジュール（iOS通知64個制限に対応）
    func scheduleReminder(for task: Task) async throws {
        guard task.reminderEnabled else { return }

        let intervals = calculateReminderIntervals(for: task)
        let startTime = task.reminderStartTime ?? Date()
        let endTime = task.reminderEndTime ?? task.deadline ?? task.startDateTime

        // iOS の通知64個制限に対応するため、直近の通知のみをスケジュール
        // 重要度に応じて最大通知数を調整
        let maxNotificationsPerTask: Int
        if let priorityString = task.priority,
           let priority = Priority(rawValue: priorityString) {
            switch priority {
            case .high:
                maxNotificationsPerTask = 15  // 高重要度: 最大15個
            case .medium:
                maxNotificationsPerTask = 10  // 中重要度: 最大10個
            case .low:
                maxNotificationsPerTask = 5   // 低重要度: 最大5個
            }
        } else {
            maxNotificationsPerTask = 5  // デフォルト
        }

        var currentTime = startTime
        var notificationCount = 0

        // 直近の通知をスケジュール
        while notificationCount < maxNotificationsPerTask {
            // タスクが完了していない場合のみ通知をスケジュール
            if !task.isCompleted {
                let interval = intervals[notificationCount % intervals.count]
                currentTime = currentTime.addingTimeInterval(TimeInterval(interval * 60))

                if let endTime = endTime, currentTime > endTime {
                    break
                }

                try await notificationManager.scheduleReminderNotification(
                    for: task,
                    at: currentTime
                )
            }

            notificationCount += 1
        }

        // 注: アプリ起動時やバックグラウンドタスクで、次の通知を追加でスケジュールする
        // 実装は NotificationRefreshService で行う（後述）
    }
    
    // リマインド間隔の計算（重要度とタスクタイプに基づく）
    private func calculateReminderIntervals(for task: Task) -> [Int] {
        guard let priorityString = task.priority,
              let priority = Priority(rawValue: priorityString),
              let taskTypeString = task.taskType,
              let taskType = TaskType(rawValue: taskTypeString) else {
            // デフォルト: 1時間間隔
            return [60]
        }
        
        switch (priority, taskType) {
        case (.low, .task):
            // 低重要度・タスク: 24時間間隔
            return [1440] // 24時間 = 1440分
            
        case (.medium, .task):
            // 中重要度・タスク: 3時間間隔
            return [180] // 3時間 = 180分
            
        case (.high, .task):
            // 高重要度・タスク: 1時間間隔
            return [60] // 1時間 = 60分
            
        case (.low, .schedule):
            // 低重要度・スケジュール: 段階的リマインド
            guard let startDateTime = task.startDateTime else {
                return [60]
            }
            return calculateStagedIntervals(
                startDateTime: startDateTime,
                stages: [
                    (days: 3, interval: 1440),    // 3日前から: 1日1回
                    (days: 1, interval: 720),      // 1日前から: 12時間間隔
                    (hours: 6, interval: 360),      // 6時間前から: 6時間間隔
                    (hours: 1, interval: 60),      // 1時間前から: 1時間間隔
                ],
                overdueInterval: 30                 // 開始日時超過後: 30分間隔
            )
            
        case (.medium, .schedule):
            // 中重要度・スケジュール: 段階的リマインド
            guard let startDateTime = task.startDateTime else {
                return [60]
            }
            return calculateStagedIntervals(
                startDateTime: startDateTime,
                stages: [
                    (days: 7, interval: 1440),     // 1週間前から: 1日1回
                    (days: 3, interval: 720),       // 3日前から: 12時間間隔
                    (days: 1, interval: 360),       // 1日前から: 6時間間隔
                    (hours: 6, interval: 180),      // 6時間前から: 3時間間隔
                    (hours: 3, interval: 60),       // 3時間前から: 1時間間隔
                    (hours: 1, interval: 30),       // 1時間前から: 30分間隔
                ],
                overdueInterval: 15                 // 開始日時超過後: 15分間隔
            )
            
        case (.high, .schedule):
            // 高重要度・スケジュール: 段階的リマインド
            guard let startDateTime = task.startDateTime else {
                return [60]
            }
            return calculateStagedIntervals(
                startDateTime: startDateTime,
                stages: [
                    (days: 7, interval: 1440),     // 1週間前から: 1日1回
                    (days: 3, interval: 720),       // 3日前から: 12時間間隔
                    (days: 1, interval: 360),       // 1日前から: 6時間間隔
                    (hours: 6, interval: 180),      // 6時間前から: 3時間間隔
                    (hours: 3, interval: 60),       // 3時間前から: 1時間間隔
                    (hours: 1, interval: 30),       // 1時間前から: 30分間隔
                    (hours: 0.5, interval: 15),     // 30分前から: 15分間隔
                    (hours: 0.25, interval: 5),    // 15分前から: 5分間隔
                    (hours: 0.083, interval: 1),    // 5分前から: 1分間隔
                ],
                overdueInterval: 1                  // 開始日時超過後: 1分間隔
            )
        }
    }
    
    // 段階的リマインド間隔の計算
    private func calculateStagedIntervals(
        startDateTime: Date,
        stages: [(days: Double?, hours: Double?, interval: Int)],
        overdueInterval: Int
    ) -> [Int] {
        let now = Date()
        let timeUntilStart = startDateTime.timeIntervalSince(now)
        
        var intervals: [Int] = []
        
        // 各ステージの間隔を計算
        for stage in stages {
            let threshold: TimeInterval
            if let days = stage.days {
                threshold = days * 86400
            } else if let hours = stage.hours {
                threshold = hours * 3600
            } else {
                continue
            }
            
            if timeUntilStart > threshold {
                intervals.append(stage.interval)
            }
        }
        
        // 開始日時を過ぎた場合の間隔
        if timeUntilStart <= 0 {
            intervals.append(overdueInterval)
        }
        
        return intervals.isEmpty ? [60] : intervals
    }
}

