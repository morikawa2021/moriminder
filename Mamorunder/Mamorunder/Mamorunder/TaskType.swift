//
//  TaskType.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum TaskType: String, Codable {
    case task = "task"           // タスク（期限設定）
    case schedule = "schedule"   // スケジュール（開始日時設定）
}

