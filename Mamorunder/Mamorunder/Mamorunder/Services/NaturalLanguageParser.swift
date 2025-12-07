//
//  NaturalLanguageParser.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import Foundation

class NaturalLanguageParser {
    private let detector: NSDataDetector
    
    init() {
        detector = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
    }
    
    struct ExtractionResult {
        let dateTime: Date?
        let taskType: TaskType?
    }
    
    // 自然言語から日時を抽出
    func extractDateTime(from text: String) -> ExtractionResult {
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        
        guard let match = matches.first,
              let date = match.date else {
            return ExtractionResult(dateTime: nil, taskType: nil)
        }
        
        // 時刻情報を抽出（「9時」「15時」「午後3時」など）
        var finalDate = date
        let calendar = Calendar.current
        
        // 時刻パターンを検出
        if let hourMatch = extractHour(from: text) {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            var dateComponents = DateComponents()
            dateComponents.year = components.year
            dateComponents.month = components.month
            dateComponents.day = components.day
            dateComponents.hour = hourMatch.hour
            dateComponents.minute = hourMatch.minute ?? 0
            
            if let adjustedDate = calendar.date(from: dateComponents) {
                finalDate = adjustedDate
            }
        }
        
        // タスクタイプの判定
        let taskType: TaskType
        if text.contains("まで") || text.contains("期限") || text.contains("締切") {
            taskType = .task
        } else if text.contains("に") || text.contains("時") || text.contains("開始") {
            taskType = .schedule
        } else {
            // デフォルトはタスク
            taskType = .task
        }
        
        return ExtractionResult(dateTime: finalDate, taskType: taskType)
    }
    
    // 時刻を抽出（「9時」「15時」「午後3時」など）
    private func extractHour(from text: String) -> (hour: Int, minute: Int?)? {
        let patterns = [
            // 「午後3時」「午前9時」
            (pattern: "午後(\\d+)時", isPM: true),
            (pattern: "午前(\\d+)時", isPM: false),
            // 「9時」「15時」
            (pattern: "(\\d+)時", isPM: nil),
            // 「9:00」「15:30」
            (pattern: "(\\d+):(\\d+)", isPM: nil)
        ]
        
        for patternInfo in patterns {
            let regex = try? NSRegularExpression(pattern: patternInfo.pattern)
            let range = NSRange(text.startIndex..., in: text)
            
            if let match = regex?.firstMatch(in: text, options: [], range: range) {
                if match.numberOfRanges >= 2 {
                    let hourRange = match.range(at: 1)
                    if let hourString = Range(hourRange, in: text),
                       let hour = Int(text[hourString]) {
                        var finalHour = hour
                        
                        // 午後/午前の処理
                        if let isPM = patternInfo.isPM {
                            if isPM && hour < 12 {
                                finalHour = hour + 12
                            } else if !isPM && hour == 12 {
                                finalHour = 0
                            }
                        }
                        
                        // 分の抽出（「9:30」形式の場合）
                        var minute: Int? = nil
                        if match.numberOfRanges >= 3 {
                            let minuteRange = match.range(at: 2)
                            if let minuteString = Range(minuteRange, in: text),
                               let minuteValue = Int(text[minuteString]) {
                                minute = minuteValue
                            }
                        }
                        
                        return (hour: finalHour, minute: minute)
                    }
                }
            }
        }
        
        return nil
    }
}

