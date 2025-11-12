//
//  ReminderSettingView.swift
//  Moriminder
//
//  Created on 2025-11-09.
//

import SwiftUI

struct ReminderSettingView: View {
    @Binding var enabled: Bool
    @Binding var startTime: Date?
    @Binding var interval: Int
    @Binding var endTime: Date?
    let deadline: Date?
    let startDateTime: Date?

    @State private var showEndTimePicker: Bool = false

    // デフォルトの開始時刻を計算（期限/開始日時の1時間前）
    private var defaultStartTime: Date {
        let targetTime = deadline ?? startDateTime ?? Date()
        return targetTime.addingTimeInterval(-3600) // 1時間前
    }

    var body: some View {
        Group {
            Toggle("リマインド", isOn: $enabled)

            if enabled {
                // リマインド開始日時
                DatePicker(
                    "開始日時",
                    selection: Binding(
                        get: { startTime ?? defaultStartTime },
                        set: { startTime = $0 }
                    ),
                    displayedComponents: [.date, .hourAndMinute]
                )

                // リマインド間隔
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

                // リマインド終了時刻設定
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("終了日時を設定", isOn: $showEndTimePicker)
                        .onChange(of: showEndTimePicker) { newValue in
                            if !newValue {
                                // トグルがOFFの場合、終了時刻をnilに設定（完了まで無期限）
                                endTime = nil
                            } else {
                                // トグルがONの場合、デフォルト値を設定
                                if endTime == nil {
                                    // デフォルトは開始時刻から1週間後
                                    let baseDate = startTime ?? defaultStartTime
                                    endTime = Calendar.current.date(byAdding: .day, value: 7, to: baseDate)
                                }
                            }
                        }

                    if showEndTimePicker {
                        DatePicker(
                            "終了日時",
                            selection: Binding(
                                get: { endTime ?? Date() },
                                set: { endTime = $0 }
                            ),
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    } else {
                        HStack {
                            Text("終了日時:")
                            Spacer()
                            Text("完了まで無期限")
                                .foregroundColor(.secondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
        .onAppear {
            // 既存の終了時刻が設定されている場合、ピッカーを表示
            if endTime != nil {
                showEndTimePicker = true
            }
        }
        .onChange(of: endTime) { newValue in
            // 終了時刻が設定された場合、ピッカーを表示
            if newValue != nil && !showEndTimePicker {
                showEndTimePicker = true
            }
        }
    }
}

