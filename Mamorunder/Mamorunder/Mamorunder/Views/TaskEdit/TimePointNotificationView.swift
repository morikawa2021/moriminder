//
//  TimePointNotificationView.swift
//  Mamorunder
//
//  Created on 2025-12-01.
//

import SwiftUI

/// 時間ポイント（開始時刻または期限）に対する通知設定ビュー
struct TimePointNotificationView: View {
    /// 時間ポイントの種類
    enum TimePointKind {
        case startTime
        case deadline

        var displayName: String {
            switch self {
            case .startTime: return "開始時刻"
            case .deadline: return "期限"
            }
        }
    }

    let kind: TimePointKind
    let targetDate: Date

    @Binding var notificationType: NotificationType
    @Binding var reminderOffset: Int  // 分
    @Binding var reminderInterval: Int  // 分

    // リマインド間隔の選択肢
    private let intervalOptions = [
        (5, "5分"),
        (10, "10分"),
        (15, "15分"),
        (30, "30分"),
        (60, "1時間"),
        (180, "3時間"),
        (360, "6時間"),
        (720, "12時間"),
        (1440, "24時間")
    ]

    // リマインドオフセットの選択肢
    private let offsetOptions = [
        (5, "5分前"),
        (10, "10分前"),
        (15, "15分前"),
        (30, "30分前"),
        (60, "1時間前"),
        (120, "2時間前"),
        (180, "3時間前"),
        (360, "6時間前"),
        (720, "12時間前"),
        (1440, "1日前")
    ]

    var body: some View {
        Section {
            // 通知タイプの選択（ラジオボタン風）
            ForEach(NotificationType.allCases, id: \.self) { type in
                notificationTypeRow(type)
            }

            // リマインド選択時の追加設定
            if notificationType == .remind {
                reminderSettings
            }
        } header: {
            sectionHeader
        }
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack {
            Text(kind.displayName)
            Spacer()
            Text(formattedTargetDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var formattedTargetDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: targetDate)
    }

    // MARK: - Notification Type Row

    private func notificationTypeRow(_ type: NotificationType) -> some View {
        Button {
            notificationType = type
        } label: {
            HStack {
                Image(systemName: notificationType == type ? "largecircle.fill.circle" : "circle")
                    .foregroundColor(notificationType == type ? .blue : .gray)

                VStack(alignment: .leading, spacing: 2) {
                    Text(displayText(for: type))
                        .foregroundColor(.primary)

                    if type == .once {
                        Text("\(kind.displayName)に1回だけ通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if type == .remind {
                        Text("繰り返し通知 → \(kind.displayName)に最終通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
        }
        .buttonStyle(.plain)
    }

    private func displayText(for type: NotificationType) -> String {
        switch type {
        case .none:
            return "通知しない"
        case .once:
            return "\(kind.displayName)に通知（1回のみ）"
        case .remind:
            return "リマインドする"
        }
    }

    // MARK: - Reminder Settings

    private var reminderSettings: some View {
        Group {
            // オフセット（何分前から）
            Picker("開始", selection: $reminderOffset) {
                ForEach(offsetOptions, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }

            // 間隔
            Picker("間隔", selection: $reminderInterval) {
                ForEach(intervalOptions, id: \.0) { option in
                    Text(option.1).tag(option.0)
                }
            }

            // 説明テキスト
            reminderDescription
        }
    }

    private var reminderDescription: some View {
        let startDate = Calendar.current.date(
            byAdding: .minute,
            value: -reminderOffset,
            to: targetDate
        ) ?? targetDate

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "HH:mm"

        let startTimeString = formatter.string(from: startDate)
        let targetTimeString = formatter.string(from: targetDate)

        let intervalText: String
        if reminderInterval >= 60 {
            let hours = reminderInterval / 60
            intervalText = "\(hours)時間"
        } else {
            intervalText = "\(reminderInterval)分"
        }

        return HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("\(startTimeString)から\(intervalText)間隔で通知、\(targetTimeString)に最終通知")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

#Preview {
    Form {
        TimePointNotificationView(
            kind: .startTime,
            targetDate: Date().addingTimeInterval(3600),
            notificationType: .constant(.remind),
            reminderOffset: .constant(30),
            reminderInterval: .constant(10)
        )

        TimePointNotificationView(
            kind: .deadline,
            targetDate: Date().addingTimeInterval(7200),
            notificationType: .constant(.once),
            reminderOffset: .constant(60),
            reminderInterval: .constant(15)
        )
    }
}
