//
//  DataError.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum DataError: LocalizedError {
    case corruptedData                   // データ破損
    case migrationFailed                 // マイグレーション失敗
    case storageFullError                // ストレージ容量不足

    var errorDescription: String? {
        switch self {
        case .corruptedData:
            return "データが破損しています。復元を試みてください"
        case .migrationFailed:
            return "データの移行に失敗しました"
        case .storageFullError:
            return "ストレージ容量が不足しています"
        }
    }
}

