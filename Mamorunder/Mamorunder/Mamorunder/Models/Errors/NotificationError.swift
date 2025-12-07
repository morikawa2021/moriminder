//
//  NotificationError.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum NotificationError: LocalizedError {
    case authorizationDenied
    case schedulingFailed
    case maxSnoozeReached
    case notificationLimitReached        // iOS 64個制限
    case invalidScheduleTime             // 過去の時刻
    case duplicateNotification           // 重複する通知

    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "通知の許可が必要です。設定アプリから通知を許可してください"
        case .schedulingFailed:
            return "通知のスケジュールに失敗しました"
        case .maxSnoozeReached:
            return "スヌーズの最大回数に達しました"
        case .notificationLimitReached:
            return "通知数の上限に達しました。古いタスクを完了してください"
        case .invalidScheduleTime:
            return "過去の時刻には通知を設定できません"
        case .duplicateNotification:
            return "既に同じ通知がスケジュールされています"
        }
    }
}

