//
//  Category+Extensions.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

extension Category {
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
        
        // usageCountのデフォルト値
        usageCount = 0
    }
}

