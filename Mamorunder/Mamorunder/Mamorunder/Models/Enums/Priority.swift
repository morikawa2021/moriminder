//
//  Priority.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

enum Priority: String, Codable, Comparable {
    case low = "low"         // 低
    case medium = "medium"   // 中
    case high = "high"       // 高
    
    // 比較用の数値
    private var order: Int {
        switch self {
        case .low: return 1
        case .medium: return 2
        case .high: return 3
        }
    }
    
    static func < (lhs: Priority, rhs: Priority) -> Bool {
        return lhs.order < rhs.order
    }
}

