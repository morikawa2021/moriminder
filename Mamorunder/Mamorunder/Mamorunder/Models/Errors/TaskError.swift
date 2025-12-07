//
//  TaskError.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum TaskError: LocalizedError {
    case invalidTitle
    case invalidDateTime
    case conflictingDates                // 開始日時 > 期限の場合
    case pastDate                        // 過去の日時を設定
    case taskNotFound
    case saveFailed
    case invalidRepeatPattern            // 繰り返し設定が無効

    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "タスク名を入力してください"
        case .invalidDateTime:
            return "日時設定が無効です"
        case .conflictingDates:
            return "開始日時は期限より前に設定してください"
        case .pastDate:
            return "過去の日時は設定できません"
        case .taskNotFound:
            return "タスクが見つかりません"
        case .saveFailed:
            return "タスクの保存に失敗しました"
        case .invalidRepeatPattern:
            return "繰り返し設定が無効です。パラメータを確認してください"
        }
    }
}

