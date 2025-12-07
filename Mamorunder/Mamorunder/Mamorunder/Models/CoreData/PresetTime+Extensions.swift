//
//  PresetTime+Extensions.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation
import CoreData

extension PresetTime {
    // awakeFromInsertでデフォルト値を設定
    nonisolated public override func awakeFromInsert() {
        super.awakeFromInsert()
        
        // idが設定されていない場合、新しいUUIDを生成
        if id == nil {
            id = UUID()
        }
        
        // isDefaultのデフォルト値
        isDefault = false
    }
    
    // デフォルトプリセット時間の作成
    static func createDefaultPresetTimes(in context: NSManagedObjectContext) {
        let request: NSFetchRequest<PresetTime> = PresetTime.fetchRequest()
        request.predicate = NSPredicate(format: "isDefault == YES")
        
        do {
            let existingDefaults = try context.fetch(request)
            // 既にデフォルトが存在する場合は作成しない
            if !existingDefaults.isEmpty {
                return
            }
        } catch {
            print("デフォルトプリセット時間確認エラー: \(error)")
        }
        
        // デフォルトプリセット時間の定義
        let defaultPresets: [(name: String, hour: Int, minute: Int, offsetDays: Int, order: Int)] = [
            ("今日の9時", 9, 0, 0, 0),
            ("今日の12時", 12, 0, 0, 1),
            ("今日の15時", 15, 0, 0, 2),
            ("今日の18時", 18, 0, 0, 3),
            ("今日の21時", 21, 0, 0, 4),
            ("明日の9時", 9, 0, 1, 5),
            ("明日の12時", 12, 0, 1, 6),
            ("明日の15時", 15, 0, 1, 7),
            ("明日の18時", 18, 0, 1, 8),
            ("明後日の9時", 9, 0, 2, 9),
            ("明後日の12時", 12, 0, 2, 10),
            ("明後日の15時", 15, 0, 2, 11)
        ]
        
        for preset in defaultPresets {
            let presetTime = PresetTime(context: context)
            presetTime.id = UUID()
            presetTime.name = preset.name
            presetTime.hour = Int32(preset.hour)
            presetTime.minute = Int32(preset.minute)
            presetTime.offsetDays = Int32(preset.offsetDays)
            presetTime.isDefault = true
            presetTime.order = Int32(preset.order)
        }
        
        do {
            try context.save()
        } catch {
            print("デフォルトプリセット時間作成エラー: \(error)")
        }
    }
}

