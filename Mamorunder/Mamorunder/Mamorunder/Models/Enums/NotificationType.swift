//
//  NotificationType.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

/// 時間ポイント（開始時刻・期限）に対する通知設定タイプ
enum NotificationType: String, Codable, CaseIterable {
    case none = "none"       // 通知なし
    case once = "once"       // 1回のみ（その時刻に通知）
    case remind = "remind"   // リマインド（繰り返し + 最終通知）

    var displayName: String {
        switch self {
        case .none: return "通知しない"
        case .once: return "1回のみ"
        case .remind: return "リマインド"
        }
    }
}
