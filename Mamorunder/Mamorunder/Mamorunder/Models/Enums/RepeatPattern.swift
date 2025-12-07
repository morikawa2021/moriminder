//
//  RepeatPattern.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

// 繰り返しパターンのタイプ
public enum RepeatType: String, Codable {
    case daily = "daily"                     // 毎日
    case weekly = "weekly"                   // 毎週
    case monthly = "monthly"                 // 毎月
    case yearly = "yearly"                   // 毎年
    case everyNHours = "everyNHours"         // N時間ごと
    case everyNDays = "everyNDays"           // N日ごと
    case nthWeekdayOfMonth = "nthWeekdayOfMonth" // 毎月第N曜日
    case custom = "custom"                   // カスタム
}

// 繰り返しパターン（パラメータを含む）
// Core DataのTransformable属性で使用するため、NSObjectを継承
@objc(RepeatPattern)
public class RepeatPattern: NSObject, Codable {
    public let type: RepeatType                     // パターンタイプ
    public let interval: Int?                       // N日ごと の N（everyNDaysの場合）
    public let hourInterval: Int?                   // N時間ごと の N（everyNHoursの場合）
    public let weekday: Int?                        // 曜日（1=日曜日〜7=土曜日、nthWeekdayOfMonthの場合）
    public let week: Int?                           // 第N週（1=第1週、nthWeekdayOfMonthの場合）
    public let customDays: [Int]?                   // カスタムパターンの曜日（customの場合）
    
    public init(type: RepeatType, interval: Int?, hourInterval: Int?, weekday: Int?, week: Int?, customDays: [Int]?) {
        self.type = type
        self.interval = interval
        self.hourInterval = hourInterval
        self.weekday = weekday
        self.week = week
        self.customDays = customDays
        super.init()
    }
    
    // Codable実装（既存データとの互換性のため）
    enum CodingKeys: String, CodingKey {
        case type
        case interval
        case hourInterval
        case weekday
        case week
        case customDays
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(RepeatType.self, forKey: .type)
        interval = try container.decodeIfPresent(Int.self, forKey: .interval)
        hourInterval = try container.decodeIfPresent(Int.self, forKey: .hourInterval)
        weekday = try container.decodeIfPresent(Int.self, forKey: .weekday)
        week = try container.decodeIfPresent(Int.self, forKey: .week)
        customDays = try container.decodeIfPresent([Int].self, forKey: .customDays)
        super.init()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encodeIfPresent(interval, forKey: .interval)
        try container.encodeIfPresent(hourInterval, forKey: .hourInterval)
        try container.encodeIfPresent(weekday, forKey: .weekday)
        try container.encodeIfPresent(week, forKey: .week)
        try container.encodeIfPresent(customDays, forKey: .customDays)
    }

    // 便利なイニシャライザ
    public static func daily() -> RepeatPattern {
        return RepeatPattern(type: .daily, interval: nil, hourInterval: nil, weekday: nil, week: nil, customDays: nil)
    }

    public static func weekly() -> RepeatPattern {
        return RepeatPattern(type: .weekly, interval: nil, hourInterval: nil, weekday: nil, week: nil, customDays: nil)
    }

    public static func monthly() -> RepeatPattern {
        return RepeatPattern(type: .monthly, interval: nil, hourInterval: nil, weekday: nil, week: nil, customDays: nil)
    }

    public static func yearly() -> RepeatPattern {
        return RepeatPattern(type: .yearly, interval: nil, hourInterval: nil, weekday: nil, week: nil, customDays: nil)
    }

    public static func everyNHours(_ n: Int) -> RepeatPattern {
        return RepeatPattern(type: .everyNHours, interval: nil, hourInterval: n, weekday: nil, week: nil, customDays: nil)
    }

    public static func everyNDays(_ n: Int) -> RepeatPattern {
        return RepeatPattern(type: .everyNDays, interval: n, hourInterval: nil, weekday: nil, week: nil, customDays: nil)
    }

    public static func nthWeekdayOfMonth(weekday: Int, week: Int) -> RepeatPattern {
        return RepeatPattern(type: .nthWeekdayOfMonth, interval: nil, hourInterval: nil, weekday: weekday, week: week, customDays: nil)
    }

    public static func custom(days: [Int]) -> RepeatPattern {
        return RepeatPattern(type: .custom, interval: nil, hourInterval: nil, weekday: nil, week: nil, customDays: days)
    }
}
