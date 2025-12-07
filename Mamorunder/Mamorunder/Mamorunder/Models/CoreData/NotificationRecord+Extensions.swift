//
//  NotificationRecord+Extensions.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

extension NotificationRecord {
    // awakeFromInsertでデフォルト値を設定
    nonisolated public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // idが設定されていない場合、新しいUUIDを生成
        if id == nil {
            id = UUID()
        }
        
        // isDeliveredのデフォルト値
        isDelivered = false
    }
    
    // notificationTypeをNotificationType enumに変換するcomputed property
    var notificationTypeEnum: NotificationType? {
        get {
            guard let typeString = notificationType else { return nil }
            return NotificationType(rawValue: typeString)
        }
        set {
            notificationType = newValue?.rawValue
        }
    }
}

