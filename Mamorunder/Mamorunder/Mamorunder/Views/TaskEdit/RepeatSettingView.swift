//
//  RepeatSettingView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct RepeatSettingView: View {
    @Binding var enabled: Bool
    @Binding var pattern: RepeatPattern?
    @Binding var endDate: Date?
    
    @State private var selectedPatternType: RepeatType = .daily
    @State private var customInterval: Int = 1
    @State private var customHourInterval: Int = 1  // N時間ごとのN
    @State private var selectedWeekday: Int = 1  // 1=日曜日
    @State private var selectedWeek: Int = 1     // 第1週
    @State private var customDays: Set<Int> = [] // 1=日曜日〜7=土曜日
    
    var body: some View {
        Group {
            Toggle("繰り返し", isOn: $enabled)
            
            if enabled {
                // 繰り返しパターンの選択
                Picker("パターン", selection: $selectedPatternType) {
                    Text("毎日").tag(RepeatType.daily)
                    Text("毎週").tag(RepeatType.weekly)
                    Text("毎月").tag(RepeatType.monthly)
                    Text("毎年").tag(RepeatType.yearly)
                    Text("N時間ごと").tag(RepeatType.everyNHours)
                    Text("N日ごと").tag(RepeatType.everyNDays)
                    Text("毎月第N曜日").tag(RepeatType.nthWeekdayOfMonth)
                    Text("カスタム").tag(RepeatType.custom)
                }
                .onChange(of: selectedPatternType) { _ in
                    updatePattern()
                }
                
                // パターンに応じた詳細設定
                switch selectedPatternType {
                case .daily, .weekly, .monthly, .yearly:
                    // 基本パターンは追加設定不要
                    EmptyView()
                    
                case .everyNHours:
                    Stepper("\(customHourInterval)時間ごと", value: $customHourInterval, in: 1...168)
                        .onChange(of: customHourInterval) { _ in
                            updatePattern()
                        }
                    
                case .everyNDays:
                    Stepper("\(customInterval)日ごと", value: $customInterval, in: 1...365)
                        .onChange(of: customInterval) { _ in
                            updatePattern()
                        }
                    
                case .nthWeekdayOfMonth:
                    Picker("曜日", selection: $selectedWeekday) {
                        Text("日曜日").tag(1)
                        Text("月曜日").tag(2)
                        Text("火曜日").tag(3)
                        Text("水曜日").tag(4)
                        Text("木曜日").tag(5)
                        Text("金曜日").tag(6)
                        Text("土曜日").tag(7)
                    }
                    .onChange(of: selectedWeekday) { _ in
                        updatePattern()
                    }
                    
                    Picker("週", selection: $selectedWeek) {
                        Text("第1週").tag(1)
                        Text("第2週").tag(2)
                        Text("第3週").tag(3)
                        Text("第4週").tag(4)
                        Text("第5週").tag(5)
                    }
                    .onChange(of: selectedWeek) { _ in
                        updatePattern()
                    }
                    
                case .custom:
                    VStack(alignment: .leading, spacing: 8) {
                        Text("繰り返す曜日:")
                        ForEach(1...7, id: \.self) { day in
                            Toggle(weekdayName(day), isOn: Binding(
                                get: { customDays.contains(day) },
                                set: { isOn in
                                    if isOn {
                                        customDays.insert(day)
                                    } else {
                                        customDays.remove(day)
                                    }
                                    updatePattern()
                                }
                            ))
                        }
                    }
                }
                
                // 終了日時の設定
                Toggle("終了日時を設定", isOn: Binding(
                    get: { endDate != nil },
                    set: { isOn in
                        endDate = isOn ? Date() : nil
                    }
                ))
                
                if endDate != nil {
                    DatePicker("終了日時", selection: Binding(
                        get: { endDate ?? Date() },
                        set: { endDate = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
        .onAppear {
            loadPattern()
        }
    }
    
    private func loadPattern() {
        guard let pattern = pattern else {
            // デフォルトパターンを設定
            self.pattern = RepeatPattern.daily()
            selectedPatternType = .daily
            return
        }
        
        selectedPatternType = pattern.type
        
        switch pattern.type {
        case .everyNHours:
            customHourInterval = pattern.hourInterval ?? 1
        case .everyNDays:
            customInterval = pattern.interval ?? 1
        case .nthWeekdayOfMonth:
            selectedWeekday = pattern.weekday ?? 1
            selectedWeek = pattern.week ?? 1
        case .custom:
            customDays = Set(pattern.customDays ?? [])
        default:
            break
        }
    }
    
    private func updatePattern() {
        switch selectedPatternType {
        case .daily:
            pattern = RepeatPattern.daily()
        case .weekly:
            pattern = RepeatPattern.weekly()
        case .monthly:
            pattern = RepeatPattern.monthly()
        case .yearly:
            pattern = RepeatPattern.yearly()
        case .everyNHours:
            pattern = RepeatPattern.everyNHours(customHourInterval)
        case .everyNDays:
            pattern = RepeatPattern.everyNDays(customInterval)
        case .nthWeekdayOfMonth:
            pattern = RepeatPattern.nthWeekdayOfMonth(weekday: selectedWeekday, week: selectedWeek)
        case .custom:
            pattern = RepeatPattern.custom(days: Array(customDays).sorted())
        }
    }
    
    private func weekdayName(_ day: Int) -> String {
        let names = ["", "日", "月", "火", "水", "木", "金", "土"]
        return names[day]
    }
}

