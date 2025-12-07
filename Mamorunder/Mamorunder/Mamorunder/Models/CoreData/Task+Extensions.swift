//
//  Task+Extensions.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

extension Task {
    // MARK: - RepeatPattern Conversion

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

    // MARK: - NotificationType Conversion

    // 開始時刻の通知タイプを取得・設定
    var startTimeNotificationType: NotificationType {
        get {
            NotificationType(rawValue: startTimeNotification ?? "none") ?? .none
        }
        set {
            startTimeNotification = newValue.rawValue
        }
    }

    // 期限の通知タイプを取得・設定
    var deadlineNotificationType: NotificationType {
        get {
            NotificationType(rawValue: deadlineNotification ?? "none") ?? .none
        }
        set {
            deadlineNotification = newValue.rawValue
        }
    }

    // MARK: - Notification Helper Methods

    /// 開始時刻に対して通知が設定されているか
    public var hasStartTimeNotification: Bool {
        return startTimeNotificationType != .none && startDateTime != nil
    }

    /// 期限に対して通知が設定されているか
    public var hasDeadlineNotification: Bool {
        return deadlineNotificationType != .none && deadline != nil
    }

    /// 何らかの通知が設定されているか
    public var hasAnyNotification: Bool {
        return hasStartTimeNotification || hasDeadlineNotification
    }

    /// 開始時刻のリマインドが有効か
    public var hasStartTimeReminder: Bool {
        return startTimeNotificationType == .remind && startDateTime != nil
    }

    /// 期限のリマインドが有効か
    public var hasDeadlineReminder: Bool {
        return deadlineNotificationType == .remind && deadline != nil
    }

    /// 開始時刻のリマインド開始日時を計算
    /// - Returns: リマインドを開始する日時（開始時刻の offset 分前）
    public func startTimeReminderStartDate() -> Date? {
        guard let startDate = startDateTime else { return nil }
        return Calendar.current.date(
            byAdding: .minute,
            value: -Int(startTimeReminderOffset),
            to: startDate
        )
    }

    /// 期限のリマインド開始日時を計算
    /// - Returns: リマインドを開始する日時（期限の offset 分前）
    public func deadlineReminderStartDate() -> Date? {
        guard let deadlineDate = deadline else { return nil }
        return Calendar.current.date(
            byAdding: .minute,
            value: -Int(deadlineReminderOffset),
            to: deadlineDate
        )
    }

    /// 開始時刻のリマインド終了日時を計算
    /// リマインド終了ルール:
    /// - 開始時刻のみ設定: タスク完了まで継続（nilを返す）
    /// - 両方設定: 開始時刻で終了
    public func startTimeReminderEndDate() -> Date? {
        guard startDateTime != nil else { return nil }
        // 期限が設定されている場合は開始時刻で終了
        if deadline != nil {
            return startDateTime
        }
        // 期限が設定されていない場合はタスク完了まで継続
        return nil
    }

    /// 期限のリマインド終了日時を計算
    /// 常にタスク完了まで継続（nilを返す）
    public func deadlineReminderEndDate() -> Date? {
        // 期限のリマインドは常にタスク完了まで継続
        return nil
    }
}
