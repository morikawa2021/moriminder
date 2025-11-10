//
//  ReminderSettingView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct ReminderSettingView: View {
    @Binding var enabled: Bool
    @Binding var interval: Int
    let priority: Priority
    let taskType: TaskType
    @Binding var snoozeMaxCount: Int
    @Binding var snoozeUnlimited: Bool
    @Binding var reminderEndTime: Date?
    let deadline: Date?
    let startDateTime: Date?
    
    @State private var useDefaultSettings: Bool = true
    @State private var showReminderEndTimePicker: Bool = false
    
    // 重要度とタスクタイプに応じたデフォルト間隔
    private var defaultInterval: Int {
        switch (priority, taskType) {
        case (.low, .task):
            return 1440  // 24時間間隔
        case (.medium, .task):
            return 180   // 3時間間隔
        case (.high, .task):
            return 60    // 1時間間隔
        case (.low, .schedule), (.medium, .schedule), (.high, .schedule):
            // スケジュールの場合は段階的リマインドのため、最初の間隔を返す
            return 60    // デフォルト1時間間隔
        }
    }
    
    var body: some View {
        Group {
            Toggle("リマインド", isOn: $enabled)
            
            if enabled {
                // デフォルト設定を使用するかどうかの選択
                Toggle("デフォルト設定を使用", isOn: $useDefaultSettings)
                    .onChange(of: useDefaultSettings) { newValue in
                        if newValue {
                            interval = defaultInterval
                        }
                    }
                    .onChange(of: priority) { _ in
                        if useDefaultSettings {
                            interval = defaultInterval
                        }
                    }
                    .onChange(of: taskType) { _ in
                        if useDefaultSettings {
                            interval = defaultInterval
                        }
                    }
                
                if !useDefaultSettings {
                    Picker("間隔", selection: $interval) {
                        Text("5分").tag(5)
                        Text("15分").tag(15)
                        Text("30分").tag(30)
                        Text("1時間").tag(60)
                        Text("3時間").tag(180)
                        Text("6時間").tag(360)
                        Text("12時間").tag(720)
                        Text("24時間").tag(1440)
                    }
                } else {
                    // デフォルト設定の表示
                    HStack {
                        Text("間隔:")
                        Spacer()
                        Text(formatInterval(defaultInterval))
                            .foregroundColor(.secondary)
                    }
                    .font(.subheadline)
                }
                
                // スヌーズ設定
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("無期限スヌーズ", isOn: $snoozeUnlimited)
                        .onChange(of: snoozeUnlimited) { newValue in
                            if newValue {
                                // 無期限がONの場合、スヌーズ最大回数は無視される
                            }
                        }
                    
                    if !snoozeUnlimited {
                        Stepper("スヌーズ最大回数: \(snoozeMaxCount)回", value: $snoozeMaxCount, in: 1...10)
                    } else {
                        HStack {
                            Text("スヌーズ最大回数:")
                            Spacer()
                            Text("無期限")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
                
                // リマインド終了時刻設定
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("リマインド終了時刻を設定", isOn: $showReminderEndTimePicker)
                        .onChange(of: showReminderEndTimePicker) { newValue in
                            if !newValue {
                                // トグルがOFFの場合、リマインド終了時刻をnilに設定（タスク完了まで継続）
                                reminderEndTime = nil
                            } else {
                                // トグルがONの場合、デフォルト値を設定
                                if reminderEndTime == nil {
                                    // デフォルトは期限または開始日時がある場合はそれから1週間後、なければ現在時刻から1週間後
                                    let baseDate = deadline ?? startDateTime ?? Date()
                                    reminderEndTime = Calendar.current.date(byAdding: .day, value: 7, to: baseDate)
                                }
                            }
                        }
                    
                    if showReminderEndTimePicker {
                        DatePicker(
                            "リマインド終了時刻",
                            selection: Binding(
                                get: { reminderEndTime ?? Date() },
                                set: { reminderEndTime = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        HStack {
                            Text("リマインド終了時刻:")
                            Spacer()
                            Text("タスク完了まで")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            // 既存のリマインド終了時刻が設定されている場合、ピッカーを表示
            if reminderEndTime != nil {
                showReminderEndTimePicker = true
            }
            
            // 既存の間隔がデフォルト値と一致するかどうかで、デフォルト設定を使用するかどうかを判定
            // 一致する場合はデフォルト設定を使用、一致しない場合はカスタム設定を使用
            if interval == defaultInterval {
                useDefaultSettings = true
            } else {
                useDefaultSettings = false
            }
        }
        .onChange(of: reminderEndTime) { newValue in
            // リマインド終了時刻が設定された場合、ピッカーを表示
            if newValue != nil && !showReminderEndTimePicker {
                showReminderEndTimePicker = true
            }
        }
    }
    
    private func formatInterval(_ minutes: Int) -> String {
        if minutes < 60 {
            return "\(minutes)分"
        } else if minutes < 1440 {
            return "\(minutes / 60)時間"
        } else {
            return "\(minutes / 1440)日"
        }
    }
}

