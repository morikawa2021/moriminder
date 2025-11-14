//
//  Task+Extensions.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

extension Task {
    // repeatPatternDataをRepeatPatternに変換するcomputed property
    public var repeatPattern: RepeatPattern? {
        get {
            guard let data = repeatPatternData else { return nil }
            return try? JSONDecoder().decode(RepeatPattern.self, from: data)
        }
        set {
            if let pattern = newValue {
                repeatPatternData = try? JSONEncoder().encode(pattern)
            } else {
                repeatPatternData = nil
            }
        }
    }
    
    // awakeFromInsertでデフォルト値を設定
    nonisolated public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // createdAtが設定されていない場合、現在日時を設定
        if createdAt == nil {
            createdAt = Date()
        }
        
        // idが設定されていない場合、新しいUUIDを生成
        if id == nil {
            id = UUID()
        }
        
        // デフォルト値の設定（初回作成時のみ）
        alarmEnabled = false
        reminderEnabled = false
        reminderInterval = 60
        isRepeating = false
        isCompleted = false
        isArchived = false
    }

    // MARK: - Reminder Helper Methods

    /// リマインドの基準となる日時を返す（開始時刻 > 期限の優先順位）
    public var reminderTargetDate: Date? {
        return startDateTime ?? deadline
    }

    /// リマインドの基準となる日時の名称を返す
    public var reminderTargetDescription: String {
        if startDateTime != nil {
            return "開始時刻"
        } else if deadline != nil {
            return "期限"
        } else {
            return "予定時刻"
        }
    }

    /// リマインド開始時刻が基準日時の何分前か計算
    /// - Returns: 基準日時の何分前にリマインドが開始されるか（nilの場合はデフォルトの60分）
    public func reminderStartOffsetMinutes() -> Int? {
        guard let targetDate = reminderTargetDate else {
            return nil
        }

        if let startTime = reminderStartTime {
            // 開始時刻と基準日時の差分を計算（分単位）
            let offsetSeconds = targetDate.timeIntervalSince(startTime)
            let offsetMinutes = Int(offsetSeconds / 60)
            return offsetMinutes
        } else {
            // reminderStartTimeが未設定の場合は60分前（デフォルト）
            return 60
        }
    }
}

