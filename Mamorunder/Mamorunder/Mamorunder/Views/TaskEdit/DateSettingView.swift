//
//  DateSettingView.swift
//  Mamorunder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct DateSettingView: View {
    @Binding var taskType: TaskType
    @Binding var deadline: Date?
    @Binding var startDateTime: Date?
    let presetTimes: [PresetTime]
    
    // 期限/開始日時が設定されているかどうか
    private var isDateTimeEnabled: Bool {
        if taskType == .task {
            return deadline != nil
        } else {
            return startDateTime != nil
        }
    }
    
    var body: some View {
        Group {
            Picker("種類", selection: $taskType) {
                Text("期限").tag(TaskType.task)
                Text("開始日時").tag(TaskType.schedule)
            }
            .pickerStyle(.segmented)
            
            // 期限/開始日時を設定するかどうかのトグル
            Toggle(
                taskType == .task ? "期限を設定する" : "開始日時を設定する",
                isOn: Binding(
                    get: { isDateTimeEnabled },
                    set: { enabled in
                        if enabled {
                            // 有効にする場合、デフォルト値を設定
                            if taskType == .task {
                                deadline = Date()
                            } else {
                                startDateTime = Date()
                            }
                        } else {
                            // 無効にする場合、nilに設定
                            if taskType == .task {
                                deadline = nil
                            } else {
                                startDateTime = nil
                            }
                        }
                    }
                )
            )
            
            // プリセット時間の表示（トグルがOFFでも表示し、タップで自動的にONにする）
            if !presetTimes.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(presetTimes, id: \.objectID) { preset in
                            PresetTimeButton(
                                preset: preset,
                                taskType: taskType,
                                deadline: $deadline,
                                startDateTime: $startDateTime
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            // 設定が有効な場合のみDatePickerを表示
            if isDateTimeEnabled {
                if taskType == .task {
                    DatePicker("期限", selection: Binding(
                        get: { deadline ?? Date() },
                        set: { deadline = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                } else {
                    DatePicker("開始日時", selection: Binding(
                        get: { startDateTime ?? Date() },
                        set: { startDateTime = $0 }
                    ), displayedComponents: [.date, .hourAndMinute])
                }
            }
        }
        .environment(\.locale, Locale(identifier: "ja_JP"))
    }
}

